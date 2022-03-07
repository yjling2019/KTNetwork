//
//  KTBaseRequest.m
//  KOTU
//
//  Created by KOTU on 2019/9/10.
//

#import "KTBaseRequest.h"
#import "KTNetworkAgent.h"
#import "KTNetworkConfig.h"
#import "KTBaseRequest+Private.h"
#import "KTNetworkAgent.h"

@implementation KTBaseRequest

@synthesize groupRequest = _groupRequest;
@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeoutInterval = 15;
		_requestSerializerType = KTRequestSerializerTypeHTTP;
		_responseSerializerType = KTResponseSerializerTypeJSON;
		_ignoreCache = YES;
    }
    return self;
}

- (void)clearRequest
{
	self.successBlock = nil;
	self.failureBlock = nil;
}

- (void)start
{
	[self willStart];
	
    if (self.ignoreCache || ![self readResponseFromCache]) {
        self.isDataFromCache = NO;
        [[KTNetworkAgent sharedAgent] startRequest:self];
        return;
    }
  
    self.isDataFromCache = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
		[self willFinished];
        if (self.successBlock) {
            self.successBlock(self);
        }
		[self clearRequest];
		[self didFinished];
    });
}

- (void)realyStart
{
	[self.requestTask resume];
	[self didStart];
}

- (void)cancel
{
	[self stop];
	[self clearRequest];
}

- (void)willStart
{
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestWillStart:)]) {
		[self.requestAccessory requestWillStart:self];
	}
}

- (void)didStart
{
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestDidStart:)]) {
		[self.requestAccessory requestDidStart:self];
	}
}

- (void)stop
{
    [[KTNetworkAgent sharedAgent] cancelRequest:self];
}

- (void)willFinished
{
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestWillStop:)]) {
		[self.requestAccessory requestWillStop:self];
	}
}

- (void)didFinished
{	
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestDidStop:)]) {
		[self.requestAccessory requestDidStop:self];
	}
}

- (BOOL)requestSuccessPreHandle
{
#warning TODO cache 0225
    if (self.cacheTimeInSeconds > 0 && self.cacheKey.length > 0) {
		[self writeResponseToCacheFile];
    }
    return NO;
}

- (BOOL)requestFailurePreHandle
{
    return NO;
}

- (void)startWithCompletionSuccess:(nullable void(^)(__kindof KTBaseRequest *request))successBlock
						   failure:(nullable void(^)(__kindof KTBaseRequest *request))failureBlock
{
     self.successBlock = successBlock;
     self.failureBlock = failureBlock;
     [self start];
}

- (void)addRequestHeader:(NSDictionary <NSString *,NSString *>*)header
{
	if (![header isKindOfClass:[NSDictionary class]]) {
		return;
	}
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self.requestHeaders];
	[dic addEntriesFromDictionary:header];
	self.requestHeaders = [dic copy];
}

- (void)addRequestHeader:(NSString *)value forKey:(NSString *)key
{
	if (!value) {
		return;
	}
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self.requestHeaders];
	[dic setValue:value forKey:key];
	self.requestHeaders = [dic copy];
}

- (void)addJsonValidator:(NSDictionary *)validator
{
    if (!self.jsonValidator) {
        self.jsonValidator = validator;
    } else if ([self.jsonValidator isKindOfClass:[NSDictionary class]]) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:self.jsonValidator];
		[dic addEntriesFromDictionary:validator];
		self.jsonValidator = [dic copy];
    } else if ([self.jsonValidator isKindOfClass:[NSArray class]]) {
		NSMutableArray *array = [NSMutableArray arrayWithArray:self.jsonValidator];
		[array addObject:validator];
		self.jsonValidator = [array copy];
    }
}

- (BOOL)statusCodeValidator
{
//    NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.requestTask.response;
//    NSInteger statusCode = response.statusCode;
//#warning todo
    return YES;
}

- (NSString *)buildCustomRequestUrl
{
    return self.customRequestUrl;
}

- (BOOL)customSignature
{
    return NO;
}

- (BOOL)readResponseFromCache
{
    if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(loadCacheDataOfRequest:error:)]) {
        NSError *error = nil;
        id responseObject = [[KTNetworkConfig sharedConfig].requestHelper loadCacheDataOfRequest:self error:&error];
        self.responseObject = responseObject;
        if (self.responseSerializerType == KTResponseSerializerTypeJSON) {
            self.responseJSONObject = responseObject;
        }
        if (!error) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (void)writeResponseToCacheFile
{
    if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(saveResponseToCacheOfRequest:)]) {
        [[KTNetworkConfig sharedConfig].requestHelper saveResponseToCacheOfRequest:self];
    }
}

- (void)clearResponseFromCache
{
    if ([[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(clearResponseFromCacheOfRequest:)]) {
        [[KTNetworkConfig sharedConfig].requestHelper clearResponseFromCacheOfRequest:self];
    }
}


#pragma mark - KTRequestInGroupProtocol
- (BOOL)isIndependentRequest
{
	return self.groupRequest ? NO : YES;
}

- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess
{
#warning TODO 0301
//	if (!self.groupRequest) {
//		return;
//	}
//	[self.groupRequest inAdvanceCompleteWithResult:isSuccess];
}

#pragma mark - KTGroupChildRequestDelegate
- (void)childRequestDidSuccess:(id <KTGroupChildRequestProtocol>)request
{
	if (self != request) {
		return;
	}
	
	if (self.isIndependentRequest) {
		if (self.successBlock) {
			self.successBlock(self);
		}
	} else {
		if (self.delegate) {
			[self.delegate childRequestDidSuccess:request];
		}
	}
}

- (void)childRequestDidFail:(id <KTGroupChildRequestProtocol>)request
{
	if (self != request) {
		return;
	}
	
	if (self.isIndependentRequest) {
		if (self.failureBlock) {
			self.failureBlock(self);
		}
	} else {
		if (self.delegate) {
			[self.delegate childRequestDidFail:request];
		}
	}
}

#pragma mark - getter

- (BOOL)isCancelled
{
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting
{
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

- (NSString *)curlRequest
{
    NSURLRequest *request = self.requestTask.originalRequest;
	NSString *curl = [KTNetworkAgent curlOfRequest:request];
	return curl;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.requestTask.currentRequest.URL, self.requestTask.currentRequest.HTTPMethod, self.params];
}

@end
