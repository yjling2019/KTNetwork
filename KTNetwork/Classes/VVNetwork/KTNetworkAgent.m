//
//  KTNetworkAgent.m
//  KOTU
//
//  Created by KOTU on 2019/9/10.
//

#import "KTNetworkAgent.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "KTBaseRequest.h"
#import "KTBaseUploadRequest.h"
#import "KTBaseDownloadRequest.h"
#import "KTGroupRequest.h"
#import "KTBatchRequest.h"
#import "KTChainRequest.h"
#import "KTNetworkConfig.h"
#import "VVMockManager.h"
#import "KTBackgroundSessionManager.h"
#import "TDScope.h"
#import "KTBaseRequest+Private.h"

static dispatch_once_t onceToken;

@interface KTBaseRequest(KTNetworkAgent)

/// 每次真正发起请求前，重置状态，避免受到上次请求数据的干扰
- (void)resetOriginStatus;

@end

@implementation KTBaseRequest(KTNetworkAgent)

/// 每次真正发起请求前，重置状态，避免受到上次请求数据的干扰
- (void)resetOriginStatus
{
    self.requestTask = nil;
    self.responseObject = nil;
    self.responseJSONObject = nil;
    self.error = nil;
    self.signaturedUrl = nil;
    self.signaturedParams = nil;
    self.parsedData = nil;
}

@end

@interface KTNetworkAgent()
{
    dispatch_queue_t _processingQueue;
}

/// the priority first request
@property (nonatomic, strong, nullable) id priorityFirstRequest;

/// the array of the batchRequest
@property (nonatomic, strong) NSMutableArray *batchRequests;
/// the array of the chainRequest
@property (nonatomic, strong) NSMutableArray *chainRequests;

/// the requests need after priprityFirstRequest fininsed,if the priprityFirstRequest is not nil,
@property (nonatomic, strong, nonnull) NSMutableArray *bufferRequests;
@property (nonatomic, strong) NSMutableArray <__kindof KTBaseRequest *> *allStartedRequests;

/// the set of the request status
@property (nonatomic, strong) NSIndexSet *allStatusCodes;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFJSONResponseSerializer *jsonResponseSerializer;
@property (nonatomic, strong) AFXMLParserResponseSerializer *xmlParserResponseSerialzier;
@property (nonatomic, strong, nonnull) KTBackgroundSessionManager *backgroundSessionMananger;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation KTNetworkAgent

+ (instancetype)sharedAgent
{
    static KTNetworkAgent *_networkAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _networkAgent = [[self alloc] init];
    });
    return _networkAgent;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allStartedRequests = [NSMutableArray new];
        _batchRequests = [NSMutableArray new];
		_chainRequests = [NSMutableArray new];
		_bufferRequests = [NSMutableArray new];
        _lock = [[NSLock alloc] init];
        _processingQueue =dispatch_queue_create("com.kotu.networkAgent.processing", DISPATCH_QUEUE_CONCURRENT);
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[KTNetworkConfig sharedConfig].sessionConfiguration];
        _sessionManager.securityPolicy = [KTNetworkConfig sharedConfig].securityPolicy;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        _sessionManager.completionQueue = _processingQueue;
        _sessionManager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _jsonResponseSerializer = [self config_jsonResponseSerializer];
        _xmlParserResponseSerialzier = [self config_xmlParserResponseSerialzier];
        _backgroundSessionMananger = [KTBackgroundSessionManager new];
    }
    return self;
}

- (void)addRequest:(__kindof KTBaseRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    
    if (![request isKindOfClass:[KTBaseRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[KTBaseRequest class]] be YES");
#endif
        return;
    }
	
    dispatch_once(&onceToken, ^{
		if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(beforeAllRequests)]) {
			[[KTNetworkConfig sharedConfig].requestHelper beforeAllRequests];
		}
    });
    
    if (self.priorityFirstRequest) {
        if (([self.priorityFirstRequest isKindOfClass:[KTBaseRequest class]] && ![self.priorityFirstRequest isEqual:request])
            || ([self.priorityFirstRequest isKindOfClass:[KTBatchRequest class]] && ![[(KTBatchRequest *)self.priorityFirstRequest requestArray] containsObject:request])
            ||([self.priorityFirstRequest isKindOfClass:[KTChainRequest class]] && ![[(KTChainRequest *)self.priorityFirstRequest requestArray] containsObject:request])) {
            [self.lock lock];
            if (![self.bufferRequests containsObject:request]) {
               [self.bufferRequests addObject:request];
            }
            [self.lock unlock];
            return;
        }
    }
    
    if (request.isExecuting) {
        return;
    }
	
    [request resetOriginStatus];

	if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(beforeEachRequest:)]) {
        [[KTNetworkConfig sharedConfig].requestHelper beforeEachRequest:request];
    }
	
    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
	
    if (request) {
		[self.lock lock];
        [self.allStartedRequests addObject:request];
		[self.lock unlock];
    }
	
    [request.requestTask resume];
}

- (void)cancelRequest:(__kindof KTBaseRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[KTBaseRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[KTBaseRequest class]] be YES");
#endif
        return;
    }
	
    if (![self.allStartedRequests containsObject:request]) {
        [request clearCompletionBlock];
        return;
    }
	
    if (request.isCancelled
        || request.requestTask.state == NSURLSessionTaskStateCompleted) {
        return;
    }
	
    [request.requestTask cancel];
    [self.lock lock];
    [self.allStartedRequests removeObject:request];
    [self.lock unlock];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests
{
    if (self.priorityFirstRequest) {
        if ([self.priorityFirstRequest isKindOfClass:[KTBaseRequest class]]) {
            KTBaseRequest *request = (KTBaseRequest *)self.priorityFirstRequest;
            [request stop];
        } else if ([self.priorityFirstRequest isKindOfClass:[KTBatchRequest class]]) {
            KTBatchRequest *request = (KTBatchRequest *)self.priorityFirstRequest;
            [request stop];
        } else if ([self.priorityFirstRequest isKindOfClass:[KTChainRequest class]]) {
            KTChainRequest *request = (KTChainRequest *)self.priorityFirstRequest;
            [request stop];
        }
    }
    
    [self.lock lock];
    [self.batchRequests removeAllObjects];
    [self.chainRequests removeAllObjects];
    [self.bufferRequests removeAllObjects];
    [self.lock unlock];
    
    [self.lock lock];
    NSArray *allStartedRequests = [self.allStartedRequests copy];
    [self.lock unlock];
    
    for (__kindof KTBaseRequest *request in allStartedRequests) {
        [request stop];
    }
}

- (NSURLSessionTask *)sessionTaskForRequest:(__kindof KTBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *url = nil;
    id param = nil;
    if (request.useSignature) {
        if ([request customSignature]) {
            url = request.signaturedUrl;
            param = request.signaturedParams;
        } else {
            if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(signatureRequest:)]) {
                [[KTNetworkConfig sharedConfig].requestHelper signatureRequest:request];
                url = request.signaturedUrl;
                param = request.signaturedParams;
            } else {
                NSError *signatureError = [NSError errorWithDomain:KTNetworkErrorDomain code:KTNetworkErrorNotSupportSignature userInfo:@{@"msg":@"the requestHelper do not implement selecotr signatureRequest:"}];
                signatureError = *error;
                return nil;
            }
        }
    } else {
        url = [self buildRequestUrl:request];
        param = request.requestArgument;
    }
    
    if ([KTNetworkConfig sharedConfig].isMock) {
        BOOL needMock = [VVMockManager matchRequest:request url:url];
        if (needMock) {
            NSURL *Url = [NSURL URLWithString:url];
            NSString *scheme = Url.scheme;
            NSString *host = Url.host;
            NSNumber *port = Url.port;
            NSString *domain = nil;
            if (port) {
				domain = [NSString stringWithFormat:@"%@://%@:%@",scheme,host,port];
            } else {
				domain = [NSString stringWithFormat:@"%@://%@",scheme,host];
            }
           url = [url stringByReplacingOccurrencesOfString:domain withString:[KTNetworkConfig sharedConfig].mockBaseUrl];
        }
    }
    
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    if ([request isKindOfClass:[KTBaseDownloadRequest class]]) {
        return [self downloadTaskWithRequest:(KTBaseDownloadRequest *)request requestSerializer:requestSerializer URLString:url parameters:param error:error];
    } else if ([request isKindOfClass:[KTBaseUploadRequest class]]) {
        return [self uploadTaskWithRequest:request requestSerializer:requestSerializer URLString:url parameters:param error:error];
	} else {
		return [self dataTaskWithRequest:request requestSerializer:requestSerializer URLString:url parameters:param error:error];
	}
}

- (NSURLSessionTask *)downloadTaskWithRequest:(__kindof KTBaseDownloadRequest *)request
                            requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                    URLString:(NSString *)URLString
                                    parameters:(id)parameters
                                         error:(NSError * _Nullable __autoreleasing *)error
{
   __block NSURLSessionTask *dataTask = [self.backgroundSessionMananger dataTaskWithDownloadRequest:request requestSerializer:requestSerializer URLString:URLString parameters:parameters progress:request.progressBlock completionHandler:^(NSURLResponse * _Nonnull response, NSError * _Nullable error) {
        [self handleResultWithRequest:request error:error];
    } error:error];
    return dataTask;
}

- (NSURLSessionDataTask *)uploadTaskWithRequest:(__kindof KTBaseUploadRequest *)request
                                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                        URLString:(NSString *)URLString
                                       parameters:(id)parameters
                                            error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableURLRequest *urlRequest = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:URLString parameters:parameters constructingBodyWithBlock:request.formDataBlock error:error];
    __block NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:urlRequest uploadProgress:request.progressBlock downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        request.responseObject = responseObject;
        [self handleResultWithRequest:request error:error];
    }];
    request.requestTask = dataTask;
    return dataTask;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(__kindof KTBaseRequest *)request
                            requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                    URLString:(NSString *)URLString
                                   parameters:(id)parameters
                                        error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *method = nil;
    switch (request.requestMethod) {
        case KTRequestMethodGET:
        {
            method = @"GET";
        }
            break;
        case KTRequestMethodPOST:
        {
            method = @"POST";
        }
            break;
        case KTRequestMethodHEAD:
        {
            method = @"HEAD";
        }
            break;
        case KTRequestMethodPUT:
        {
            method = @"PUT";
        }
            break;
        case KTRequestMethodDELETE:
        {
            method = @"DELETE";
        }
            break;
        case KTRequestMethodPATCH:
        {
            method = @"PATCH";
        }
            break;
        default:
            break;
    }
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    __block NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:urlRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        request.responseObject = responseObject;
        [self handleResultWithRequest:request error:error];
    }];
    return dataTask;
}

- (void)handleResultWithRequest:(__kindof KTBaseRequest *)request error:(NSError *)error
{
    if (!request) {
        return;
    }
    NSError *__autoreleasing serializationError = nil;
    NSError *__autoreleasing validationError = nil;
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    if (![request isKindOfClass:[KTBaseDownloadRequest class]]) {
		NSData *responseData = nil;
		if ([request.responseObject isKindOfClass:[NSData class]]) {
			responseData = (NSData *)request.responseObject;
		}
		switch (request.responseSerializerType) {
			case KTResponseSerializerTypeHTTP:
	//            defalut serializer. do nothing
				break;
				
			case KTResponseSerializerTypeJSON: {
				request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:request.requestTask.response data:responseData error:&serializationError];
				request.responseJSONObject = request.responseObject;
			}
				break;
			
			case KTResponseSerializerTypeXMLParser: {
				request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:request.requestTask.response data:responseData error:&serializationError];
			}
				break;
				
			default:
				break;
		}
    }
    
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        if (request.responseSerializerType == KTResponseSerializerTypeHTTP
            || request.responseSerializerType == KTResponseSerializerTypeJSON) {
            succeed = [self validateResult:request error:&validationError];
            requestError = validationError;
        }
    }

    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }
    if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(afterEachRequest:)]) {
        [[KTNetworkConfig sharedConfig].requestHelper afterEachRequest:request];
    }
#if DEBUG
    [self printRequestDescription:request];
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lock lock];
        [self.allStartedRequests removeObject:request];
        [self.lock unlock];
        [request clearCompletionBlock];
    });
}

- (BOOL)validateResult:(__kindof KTBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error
{
    if ([request isKindOfClass:[KTBaseDownloadRequest class]]) {
        return YES;
    }
    BOOL result = YES;
    id json = request.responseJSONObject;
    id validator = [request jsonValidator];
    if (json && validator) {
		result = [self validateJSON:json withValidator:validator];
        if (!result) {
            NSError *tmpError = [[NSError alloc] initWithDomain:KTNetworkErrorDomain code:KTNetworkErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"validateResult failed",@"extra":request.responseJSONObject?:@{}}];
            if (error != NULL) {
				*error = tmpError;
            }
        }
    } else if (!json) {
#if DEBUG
        NSAssert(NO, @"responseJSONObject can't be nil");
#endif
    }
    return result;
}

- (void)requestDidSucceedWithRequest:(__kindof KTBaseRequest *)request
{
	@autoreleasepool {
		BOOL needExtraHandle = [request requestSuccessPreHandle];
        if (needExtraHandle) {
			if ([KTNetworkConfig sharedConfig].requestHelper && [[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(preHandleSuccessRequest:)]) {
				[[KTNetworkConfig sharedConfig].requestHelper preHandleSuccessRequest:request];
            }
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.isIndependentRequest) {
            if (request.requestAccessory && [request.requestAccessory respondsToSelector:@selector(requestWillStop:)]) {
                [request.requestAccessory requestWillStop:request];
            }
        }
        if (request.successBlock) {
            request.successBlock(request);
        }
        if (request.isIndependentRequest) {
            if (request.requestAccessory && [request.requestAccessory respondsToSelector:@selector(requestDidStop:)]) {
                [request.requestAccessory requestDidStop:request];
            }
        }
        [self judgeToStartBufferRequestsWithRequest:request];
    });
}

- (void)requestDidFailWithRequest:(__kindof KTBaseRequest *)request error:(NSError *)error
{
    request.error = error;
	
    @autoreleasepool {
       BOOL needExtraHandle = [request requestFailurePreHandle];
        if (needExtraHandle) {
            if ([KTNetworkConfig sharedConfig].requestHelper && [[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(preHandleFailureRequest:)]) {
                [[KTNetworkConfig sharedConfig].requestHelper preHandleFailureRequest:request];
            }
        }
    }
	
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.isIndependentRequest) {
			if (request.requestAccessory && [request.requestAccessory respondsToSelector:@selector(requestWillStop:)]) {
                [request.requestAccessory requestWillStop:request];
            }
        }
        if (request.failureBlock) {
            request.failureBlock(request);
        }
        if (request.isIndependentRequest) {
            if (request.requestAccessory && [request.requestAccessory respondsToSelector:@selector(requestDidStop:)]) {
                [request.requestAccessory requestDidStop:request];
            }
        }
        [self judgeToStartBufferRequestsWithRequest:request];
    });
}

- (NSString *)buildRequestUrl:(__kindof KTBaseRequest *)request
{
    NSString *urlStr = [request buildCustomRequestUrl];
    if (!urlStr || (urlStr && [urlStr isKindOfClass:[NSString class]] && urlStr.length == 0)) {
        NSString *detailUrl = [request requestUrl];
        
        if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(filterUrl:withRequest:)]) {
			detailUrl = [[KTNetworkConfig sharedConfig].requestHelper filterUrl:detailUrl withRequest:request];
        }
        
        NSString *baseUrl = @"";
        if ([request useCDN]) {
            if (request.cdnBaseUrl.length > 0) {
                baseUrl = request.cdnBaseUrl;
            } else {
                if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(baseUrlOfRequest:)]) {
                     baseUrl = [[KTNetworkConfig sharedConfig].requestHelper baseUrlOfRequest:request];
                } else {
                    baseUrl = [KTNetworkConfig sharedConfig].cdnBaseUrl;
                }
            }
        } else {
            if (request.baseUrl.length > 0) {
                baseUrl = request.baseUrl;
            } else {
                if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(baseUrlOfRequest:)]) {
                     baseUrl = [[KTNetworkConfig sharedConfig].requestHelper baseUrlOfRequest:request];
                } else {
                     baseUrl = [KTNetworkConfig sharedConfig].baseUrl;
                }
            }
        }
        if (baseUrl.length == 0) {
#if DEBUG
            NSAssert(NO, @"please make sure baseUrl.length > 0 be YES!");
#endif
        }
        NSURL *url = [NSURL URLWithString:baseUrl];
        if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
            url = [url URLByAppendingPathComponent:@""];
        }
        if (![[url path] isEqualToString:@"/"]) {
			detailUrl = [NSString stringWithFormat:@"%@%@",[url path],detailUrl];
        }
        urlStr = [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
    }
    return urlStr;
}

- (void)addBatchRequest:(__kindof KTBatchRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
	
    if (![request isKindOfClass:[KTBatchRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[KTBatchRequest class]] be YES");
#endif
        return;
    }
	
	dispatch_once(&onceToken, ^{
		if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(beforeAllRequests)]) {
			[[KTNetworkConfig sharedConfig].requestHelper beforeAllRequests];
		}
	});
	
    if (self.priorityFirstRequest && ![self.priorityFirstRequest isEqual:request]) {
        [self.lock lock];
        if (![self.bufferRequests containsObject:request]) {
            [self.bufferRequests addObject:request];
        }
        [self.lock unlock];
    } else {
        [self.lock lock];
        if (![self.batchRequests containsObject:request]) {
            [self.batchRequests addObject:request];
        }
        [self.lock unlock];
        [request start];
    }
}

- (void)removeBatchRequest:(__kindof KTBatchRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[KTBatchRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[KTBatchRequest class]] be YES");
#endif
        return;
    }
    [self.lock lock];
    [self.batchRequests removeObject:request];
    [self.lock unlock];
    for (__kindof KTBaseRequest *baseRequest in [request.requestArray copy]) {
        [baseRequest stop];
    }
    [self judgeToStartBufferRequestsWithRequest:request];
}

- (void)addChainRequest:(__kindof KTChainRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
	
    if (![request isKindOfClass:[KTChainRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[KTChainRequest class]] be YES");
#endif
        return;
    }
	
	dispatch_once(&onceToken, ^{
		if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(beforeAllRequests)]) {
			[[KTNetworkConfig sharedConfig].requestHelper beforeAllRequests];
		}
	});
	
    if (self.priorityFirstRequest && ![self.priorityFirstRequest isEqual:request]) {
        [self.lock lock];
        if (![self.bufferRequests containsObject:request]) {
            [self.bufferRequests addObject:request];
        }
        [self.lock unlock];
    } else {
        [self.lock lock];
        if (![self.chainRequests containsObject:request]) {
            [self.chainRequests addObject:request];
        }
        [self.lock unlock];
        [request start];
    }
}

- (void)removeChainRequest:(__kindof KTChainRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[KTChainRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[KTChainRequest class]] be YES");
#endif
        return;
    }
    [self.lock lock];
    [self.chainRequests removeObject:request];
    [self.lock unlock];
    for (__kindof KTBaseRequest *baseRequest in [request.requestArray copy]) {
        [baseRequest stop];
    }
    [self judgeToStartBufferRequestsWithRequest:request];
}

- (void)addPriorityFirstRequest:(id)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (!([request isKindOfClass:[KTBaseRequest class]]
          || [request isKindOfClass:[KTBatchRequest class]]
          || [request isKindOfClass:[KTChainRequest class]])) {
#if DEBUG
        NSAssert(NO, @"no support this request as a PriorityFirstRequest");
#endif
        return;
    }
    
    if (self.allStartedRequests.count > 0) {
#if DEBUG
       NSAssert(NO, @"addPriorityFirstRequest func must use before any request started");
#endif
       return;
    }
    self.priorityFirstRequest = request;
}

- (NSArray <__kindof KTBaseRequest *>*)allRequests
{
    [self.lock lock];
    NSMutableSet *requestSet = [NSMutableSet new];
    NSArray *array1 = [self.allStartedRequests copy];
    [requestSet addObjectsFromArray:array1];
    for (__kindof KTBatchRequest *request in self.batchRequests) {
        NSArray *tmpArray = request.requestArray;
        [requestSet addObjectsFromArray:tmpArray];
    }

    for (__kindof KTChainRequest *request in self.chainRequests) {
        NSArray *tmpArray = request.requestArray;
        [requestSet addObjectsFromArray:tmpArray];
    }
    if (self.priorityFirstRequest) {
        if ([self.priorityFirstRequest isKindOfClass:[KTBatchRequest class]]) {
            KTBatchRequest *request = (KTBatchRequest *)self.priorityFirstRequest;
            NSArray *tmpArray = request.requestArray;
            [requestSet addObjectsFromArray:tmpArray];
        } else if ([self.priorityFirstRequest isKindOfClass:[KTChainRequest class]]) {
            KTChainRequest *request = self.priorityFirstRequest;
            NSArray *tmpArray = request.requestArray;
            [requestSet addObjectsFromArray:tmpArray];
        } else if ([self.priorityFirstRequest isKindOfClass:[KTBaseRequest class]]) {
            [requestSet addObject:self.priorityFirstRequest];
        }
    }
    [self.lock unlock];
    return [requestSet allObjects];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
                                                                   completionHandler:(void (^)(void))completionHandler
{
    if ([self.backgroundSessionMananger.backgroundTaskIdentifier isEqualToString:identifier]) {
        self.backgroundSessionMananger.completionHandler = completionHandler;
    }
}

- (void)judgeToStartBufferRequestsWithRequest:(id)request
{
    if (self.priorityFirstRequest && [self.priorityFirstRequest isEqual:request]) {
        self.priorityFirstRequest = nil;
        for (id tmpRequest in self.bufferRequests) {
            if ([tmpRequest isKindOfClass:[KTBaseRequest class]]) {
                [self addRequest:tmpRequest];
            } else if ([tmpRequest isKindOfClass:[KTBatchRequest class]]) {
                [self addBatchRequest:tmpRequest];
            } else if ([tmpRequest isKindOfClass:[KTChainRequest class]]) {
                [self addChainRequest:tmpRequest];
            }
        }
        [self.bufferRequests removeAllObjects];
    }
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(__kindof KTBaseRequest *)request
{
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == KTRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == KTRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    if ([KTNetworkConfig sharedConfig].HTTPMethodsEncodingParametersInURI) {
        requestSerializer.HTTPMethodsEncodingParametersInURI = [KTNetworkConfig sharedConfig].HTTPMethodsEncodingParametersInURI;
    }
	
	if ([KTNetworkConfig sharedConfig].isMock) {
		requestSerializer.timeoutInterval = [KTNetworkConfig sharedConfig].mockModelTimeoutInterval;
	} else {
		requestSerializer.timeoutInterval = [request requestTimeoutInterval];
	}
           // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaders];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    return requestSerializer;
}

- (AFJSONResponseSerializer *)config_jsonResponseSerializer
{
    AFJSONResponseSerializer *jsonResponseSerializer = [AFJSONResponseSerializer serializer];
    jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
    jsonResponseSerializer.removesKeysWithNullValues = YES;
    return jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)config_xmlParserResponseSerialzier
{
    AFXMLParserResponseSerializer *xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
    xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    return xmlParserResponseSerialzier;
}

#pragma mark - private -
- (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator
{
    if ([json isKindOfClass:[NSDictionary class]] &&
        [jsonValidator isKindOfClass:[NSDictionary class]]) {
        NSDictionary * dict = json;
        NSDictionary * validator = jsonValidator;
        BOOL result = YES;
        NSEnumerator * enumerator = [validator keyEnumerator];
        NSString * key;
        while ((key = [enumerator nextObject]) != nil) {
            id value = dict[key];
            id format = validator[key];
            if ([value isKindOfClass:[NSDictionary class]]
                || [value isKindOfClass:[NSArray class]]) {
                result = [self validateJSON:value withValidator:format];
                if (!result) {
                    break;
                }
            } else {
                if ([value isKindOfClass:format] == NO &&
                    [value isKindOfClass:[NSNull class]] == NO) {
                    result = NO;
                    break;
                }
            }
        }
        return result;
    } else if ([json isKindOfClass:[NSArray class]] &&
               [jsonValidator isKindOfClass:[NSArray class]]) {
        NSArray * validatorArray = (NSArray *)jsonValidator;
        if (validatorArray.count > 0) {
            NSArray * array = json;
            NSDictionary * validator = jsonValidator[0];
            for (id item in array) {
                BOOL result = [self validateJSON:item withValidator:validator];
                if (!result) {
                    return NO;
                }
            }
        }
        return YES;
    } else if ([json isKindOfClass:jsonValidator]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)printRequestDescription:(__kindof KTBaseRequest *)request
{
    NSLog(@"request description:%@\n",request.description);
    NSLog(@"request curl:%@\n",request.curlRequest);
    NSLog(@"request response:%@\n",request.responseObject);
}

@end
