//
//  VVNetworkAgent.m
//  VVRootLib
//
//  Created by JackLee on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import "VVNetworkAgent.h"
#import "VVBaseRequest.h"
//#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager.h>

#import "VVNetworkConfig.h"
#import "VVGroupRequest.h"
#import "VVMockManager.h"
#import "VVBackgroundSessionManager.h"
#import "TDScope.h"
#import "VVBatchRequest.h"
#import "VVChainRequest.h"

@interface VVBaseRequest(VVNetworkAgent)

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) NSError *error;
/// the progressBlock of download/upload request
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);
/// the request success block
@property (nonatomic, copy, nullable) void(^successBlock)(__kindof VVBaseRequest *request);
/// the request failure block
@property (nonatomic, copy, nullable) void(^failureBlock)(__kindof VVBaseRequest *request);

/// when upload data cofig the formData
@property (nonatomic, copy, nullable) void (^formDataBlock)(id<AFMultipartFormData> formData);
/// the url has signatured
@property (nonatomic, copy, readwrite, nullable) NSString *signaturedUrl;
/// the params has signatured
@property (nonatomic, strong, readwrite, nullable) id signaturedParams;

@property (nonatomic, strong, readwrite, nullable) id parsedData;


/// 每次真正发起请求前，重置状态，避免受到上次请求数据的干扰
- (void)resetOriginStatus;

@end

@implementation VVBaseRequest(VVNetworkAgent)

@dynamic requestTask;
@dynamic responseObject;
@dynamic responseJSONObject;
@dynamic error;
@dynamic progressBlock;
@dynamic successBlock;
@dynamic failureBlock;
@dynamic formDataBlock;
@dynamic signaturedUrl;
@dynamic signaturedParams;
@dynamic parsedData;

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

@interface VVNetworkAgent()
{
    dispatch_queue_t _processingQueue;
}

//@property (nonatomic, strong) NSMutableDictionary <NSNumber *, __kindof VVBaseRequest *>*requestDic;
@property (nonatomic, strong) NSMutableArray <__kindof VVBaseRequest *>*allStartedRequests;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFJSONResponseSerializer *jsonResponseSerializer;
@property (nonatomic, strong) AFXMLParserResponseSerializer *xmlParserResponseSerialzier;

/// the set of the request status
@property (nonatomic, strong) NSIndexSet *allStatusCodes;
/// the array of the batchRequest
@property (nonatomic, strong) NSMutableArray *batchRequests;

/// the array of the chainRequest
@property (nonatomic, strong) NSMutableArray *chainRequests;

/// the priority first request
@property (nonatomic, strong, nullable) id priorityFirstRequest;

/// the requests need after priprityFirstRequest fininsed,if the priprityFirstRequest is not nil,
@property (nonatomic, strong, nonnull) NSMutableArray *bufferRequests;

@property (nonatomic, strong, nonnull) VVBackgroundSessionManager *backgroundSessionMananger;

@end

@implementation VVNetworkAgent

+ (instancetype)sharedAgent
{
    static VVNetworkAgent *_networkAgent = nil;
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
        _processingQueue =dispatch_queue_create("com.vova.networkAgent.processing", DISPATCH_QUEUE_CONCURRENT);
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[VVNetworkConfig sharedConfig].sessionConfiguration];
        _sessionManager.securityPolicy = [VVNetworkConfig sharedConfig].securityPolicy;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        _sessionManager.completionQueue = _processingQueue;
        _sessionManager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _jsonResponseSerializer = [self config_jsonResponseSerializer];
        _xmlParserResponseSerialzier = [self config_xmlParserResponseSerialzier];
        _backgroundSessionMananger = [VVBackgroundSessionManager new];
    }
    return self;
}

- (void)addRequest:(__kindof VVBaseRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    
    if (![request isKindOfClass:[VVBaseRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[VVBaseRequest class]] be YES");
#endif
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(beforeAllRequests)]) {
			[[VVNetworkConfig sharedConfig].requestHelper beforeAllRequests];
		}
    });
    
    if (self.priorityFirstRequest) {
        if (([self.priorityFirstRequest isKindOfClass:[VVBaseRequest class]] && ![self.priorityFirstRequest isEqual:request])
            || ([self.priorityFirstRequest isKindOfClass:[VVBatchRequest class]] && ![[(VVBatchRequest *)self.priorityFirstRequest requestArray] containsObject:request])
            ||([self.priorityFirstRequest isKindOfClass:[VVChainRequest class]] && ![[(VVChainRequest *)self.priorityFirstRequest requestArray] containsObject:request])) {
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
    if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(beforeEachRequest:)]) {
        [[VVNetworkConfig sharedConfig].requestHelper beforeEachRequest:request];
    }
    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
	
    [self.lock lock];
    if (request) {
        [self.allStartedRequests addObject:request];
    }
	[self.lock unlock];
    [request.requestTask resume];
}

- (void)cancelRequest:(__kindof VVBaseRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[VVBaseRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[VVBaseRequest class]] be YES");
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
        if ([self.priorityFirstRequest isKindOfClass:[VVBaseRequest class]]) {
            VVBaseRequest *request = (VVBaseRequest *)self.priorityFirstRequest;
            [request stop];
        } else if ([self.priorityFirstRequest isKindOfClass:[VVBatchRequest class]]) {
            VVBatchRequest *request = (VVBatchRequest *)self.priorityFirstRequest;
            [request stop];
        } else if ([self.priorityFirstRequest isKindOfClass:[VVChainRequest class]]){
            VVChainRequest *request = (VVChainRequest *)self.priorityFirstRequest;
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
    
    for (__kindof VVBaseRequest *request in allStartedRequests) {
        [request stop];
    }
}

- (NSURLSessionTask *)sessionTaskForRequest:(__kindof VVBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *url = nil;
    id param = nil;
    if (request.useSignature) {
        if ([request customSignature]) {
            url = request.signaturedUrl;
            param = request.signaturedParams;
        } else {
            if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(signatureRequest:)]) {
                [[VVNetworkConfig sharedConfig].requestHelper signatureRequest:request];
                url = request.signaturedUrl;
                param = request.signaturedParams;
            } else {
                NSError *signatureError = [NSError errorWithDomain:VVNetworkErrorDomain code:VVNetworkErrorNotSupportSignature userInfo:@{@"msg":@"the requestHelper do not implement selecotr signatureRequest:"}];
                signatureError = *error;
                return nil;
            }
        }
    } else {
        url = [self buildRequestUrl:request];
        param = request.requestArgument;
    }
    
    if ([VVNetworkConfig sharedConfig].isMock) {
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
           url = [url stringByReplacingOccurrencesOfString:domain withString:[VVNetworkConfig sharedConfig].mockBaseUrl];
        }
    }
    
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    if ([request isKindOfClass:[VVBaseDownloadRequest class]]) {
        return [self downloadTaskWithRequest:(VVBaseDownloadRequest *)request requestSerializer:requestSerializer URLString:url parameters:param error:error];
    } else if ([request isKindOfClass:[VVBaseUploadRequest class]]) {
        return [self uploadTaskWithRequest:request requestSerializer:requestSerializer URLString:url parameters:param error:error];
	} else {
		return [self dataTaskWithRequest:request requestSerializer:requestSerializer URLString:url parameters:param error:error];
	}
}

- (NSURLSessionTask *)downloadTaskWithRequest:(__kindof VVBaseDownloadRequest *)request
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

- (NSURLSessionDataTask *)uploadTaskWithRequest:(__kindof VVBaseUploadRequest *)request
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

- (NSURLSessionDataTask *)dataTaskWithRequest:(__kindof VVBaseRequest *)request
                            requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                    URLString:(NSString *)URLString
                                   parameters:(id)parameters
                                        error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *method = nil;
    switch (request.requestMethod) {
        case VVRequestMethodGET:
        {
            method = @"GET";
        }
            break;
        case VVRequestMethodPOST:
        {
            method = @"POST";
        }
            break;
        case VVRequestMethodHEAD:
        {
            method = @"HEAD";
        }
            break;
        case VVRequestMethodPUT:
        {
            method = @"PUT";
        }
            break;
        case VVRequestMethodDELETE:
        {
            method = @"DELETE";
        }
            break;
        case VVRequestMethodPATCH:
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

- (void)handleResultWithRequest:(__kindof VVBaseRequest *)request error:(NSError *)error
{
    if (!request) {
        return;
    }
    NSError *__autoreleasing serializationError = nil;
    NSError *__autoreleasing validationError = nil;
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    if (![request isKindOfClass:[VVBaseDownloadRequest class]]) {
		NSData *responseData = nil;
		if ([request.responseObject isKindOfClass:[NSData class]]) {
			responseData = (NSData *)request.responseObject;
		}
		switch (request.responseSerializerType) {
			case VVResponseSerializerTypeHTTP:
	//            defalut serializer. do nothing
				break;
				
			case VVResponseSerializerTypeJSON: {
				request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:request.requestTask.response data:responseData error:&serializationError];
				request.responseJSONObject = request.responseObject;
			}
				break;
			
			case VVResponseSerializerTypeXMLParser: {
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
        if (request.responseSerializerType == VVResponseSerializerTypeHTTP
            || request.responseSerializerType == VVResponseSerializerTypeJSON) {
            succeed = [self validateResult:request error:&validationError];
            requestError = validationError;
        }
    }

    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }
    if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(afterEachRequest:)]) {
        [[VVNetworkConfig sharedConfig].requestHelper afterEachRequest:request];
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

- (BOOL)validateResult:(__kindof VVBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error
{
    if ([request isKindOfClass:[VVBaseDownloadRequest class]]) {
        return YES;
    }
    BOOL result = YES;
    id json = request.responseJSONObject;
    id validator = [request jsonValidator];
    if (json && validator) {
		result = [self validateJSON:json withValidator:validator];
        if (!result) {
            NSError *tmpError = [[NSError alloc] initWithDomain:VVNetworkErrorDomain code:VVNetworkErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"validateResult failed",@"extra":request.responseJSONObject?:@{}}];
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

- (void)requestDidSucceedWithRequest:(__kindof VVBaseRequest *)request
{
	@autoreleasepool {
		BOOL needExtraHandle = [request requestSuccessPreHandle];
        if (needExtraHandle) {
			if ([VVNetworkConfig sharedConfig].requestHelper && [[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(preHandleSuccessRequest:)]) {
				[[VVNetworkConfig sharedConfig].requestHelper preHandleSuccessRequest:request];
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

- (void)requestDidFailWithRequest:(__kindof VVBaseRequest *)request error:(NSError *)error
{
    request.error = error;
	
    @autoreleasepool {
       BOOL needExtraHandle = [request requestFailurePreHandle];
        if (needExtraHandle) {
            if ([VVNetworkConfig sharedConfig].requestHelper && [[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(preHandleFailureRequest:)]) {
                [[VVNetworkConfig sharedConfig].requestHelper preHandleFailureRequest:request];
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

- (NSString *)buildRequestUrl:(__kindof VVBaseRequest *)request
{
    NSString *urlStr = [request buildCustomRequestUrl];
    if (!urlStr || (urlStr && [urlStr isKindOfClass:[NSString class]] && urlStr.length == 0)) {
        NSString *detailUrl = [request requestUrl];
        
        if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(filterUrl:withRequest:)]) {
			detailUrl = [[VVNetworkConfig sharedConfig].requestHelper filterUrl:detailUrl withRequest:request];
        }
        
        NSString *baseUrl = @"";
        if ([request useCDN]) {
            if (request.cdnBaseUrl.length > 0) {
                baseUrl = request.cdnBaseUrl;
            } else {
                if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(baseUrlOfRequest:)]) {
                     baseUrl = [[VVNetworkConfig sharedConfig].requestHelper baseUrlOfRequest:request];
                } else {
                    baseUrl = [VVNetworkConfig sharedConfig].cdnBaseUrl;
                }
            }
        }else{
            if (request.baseUrl.length > 0) {
                baseUrl = request.baseUrl;
            } else {
                if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(baseUrlOfRequest:)]) {
                     baseUrl = [[VVNetworkConfig sharedConfig].requestHelper baseUrlOfRequest:request];
                }else {
                     baseUrl = [VVNetworkConfig sharedConfig].baseUrl;
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

- (void)addBatchRequest:(__kindof VVBatchRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[VVBatchRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[VVBatchRequest class]] be YES");
#endif
        return;
    }
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

- (void)removeBatchRequest:(__kindof VVBatchRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[VVBatchRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[VVBatchRequest class]] be YES");
#endif
        return;
    }
    [self.lock lock];
    [self.batchRequests removeObject:request];
    [self.lock unlock];
    for (__kindof VVBaseRequest *baseRequest in [request.requestArray copy]) {
        [baseRequest stop];
    }
    [self judgeToStartBufferRequestsWithRequest:request];
}

- (void)addChainRequest:(__kindof VVChainRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[VVChainRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[VVChainRequest class]] be YES");
#endif
        return;
    }
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

- (void)removeChainRequest:(__kindof VVChainRequest *)request
{
    if (!request) {
#if DEBUG
        NSAssert(NO, @"request can't be nil");
#endif
        return;
    }
    if (![request isKindOfClass:[VVChainRequest class]]) {
#if DEBUG
        NSAssert(NO, @"please makesure [request isKindOfClass:[VVChainRequest class]] be YES");
#endif
        return;
    }
    [self.lock lock];
    [self.chainRequests removeObject:request];
    [self.lock unlock];
    for (__kindof VVBaseRequest *baseRequest in [request.requestArray copy]) {
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
    if (!([request isKindOfClass:[VVBaseRequest class]]
          || [request isKindOfClass:[VVBatchRequest class]]
          || [request isKindOfClass:[VVChainRequest class]])) {
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

- (NSArray <__kindof VVBaseRequest *>*)allRequests
{
    [self.lock lock];
    NSMutableSet *requestSet = [NSMutableSet new];
    NSArray *array1 = [self.allStartedRequests copy];
    [requestSet addObjectsFromArray:array1];
    for (__kindof VVBatchRequest *request in self.batchRequests) {
        NSArray *tmpArray = request.requestArray;
        [requestSet addObjectsFromArray:tmpArray];
    }

    for (__kindof VVChainRequest *request in self.chainRequests) {
        NSArray *tmpArray = request.requestArray;
        [requestSet addObjectsFromArray:tmpArray];
    }
    if (self.priorityFirstRequest) {
        if ([self.priorityFirstRequest isKindOfClass:[VVBatchRequest class]]) {
            VVBatchRequest *request = (VVBatchRequest *)self.priorityFirstRequest;
            NSArray *tmpArray = request.requestArray;
            [requestSet addObjectsFromArray:tmpArray];
        } else if([self.priorityFirstRequest isKindOfClass:[VVChainRequest class]]) {
            VVChainRequest *request = self.priorityFirstRequest;
            NSArray *tmpArray = request.requestArray;
            [requestSet addObjectsFromArray:tmpArray];
        } else if ([self.priorityFirstRequest isKindOfClass:[VVBaseRequest class]]) {
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
            if ([tmpRequest isKindOfClass:[VVBaseRequest class]]) {
                [self addRequest:tmpRequest];
            } else if ([tmpRequest isKindOfClass:[VVBatchRequest class]]) {
                [self addBatchRequest:tmpRequest];
            } else if ([tmpRequest isKindOfClass:[VVChainRequest class]]) {
                [self addChainRequest:tmpRequest];
            }
        }
        [self.bufferRequests removeAllObjects];
    }
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(__kindof VVBaseRequest *)request
{
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == VVRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == VVRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    if ([VVNetworkConfig sharedConfig].HTTPMethodsEncodingParametersInURI) {
        requestSerializer.HTTPMethodsEncodingParametersInURI = [VVNetworkConfig sharedConfig].HTTPMethodsEncodingParametersInURI;
    }
	
	if ([VVNetworkConfig sharedConfig].isMock) {
		requestSerializer.timeoutInterval = [VVNetworkConfig sharedConfig].mockModelTimeoutInterval;
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

- (void)printRequestDescription:(__kindof VVBaseRequest *)request
{
    NSLog(@"request description:%@\n",request.description);
    NSLog(@"request curl:%@\n",request.curlRequest);
    NSLog(@"request response:%@\n",request.responseObject);
}

@end
