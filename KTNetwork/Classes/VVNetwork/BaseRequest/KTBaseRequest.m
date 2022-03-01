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

@implementation KTBaseRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestTimeoutInterval = 15;
    }
    return self;
}

- (void)clearCompletionBlock
{
	self.successBlock = nil;
	self.failureBlock = nil;
	self.successBlock = nil;
	self.failureBlock = nil;
}

- (void)start
{
    if (self.isIndependentRequest) {
        if (self.requestAccessory && [self.requestAccessory respondsToSelector:@selector(requestWillStart:)]) {
            [self.requestAccessory requestWillStart:self];
        }
    }
    
    if ([KTNetworkConfig sharedConfig].requestHelper
        && [[KTNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(judgeToChangeCachePolicy:)]) {
        [[KTNetworkConfig sharedConfig].requestHelper judgeToChangeCachePolicy:self];
    }
	
    if (self.ignoreCache) {
        self.isDataFromCache = NO;
        [[KTNetworkAgent sharedAgent] addRequest:self];
        return;
    }
    
    if (![self readResponseFromCache]) {
        self.isDataFromCache = NO;
        [[KTNetworkAgent sharedAgent] addRequest:self];
        return;
    }
    
    self.isDataFromCache = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.successBlock) {
            self.successBlock(self);
        }
        [self clearCompletionBlock];
    });
}

- (void)stop
{
    [[KTNetworkAgent sharedAgent] cancelRequest:self];
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

#pragma mark - getter -

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
    NSURLRequest *request = self.requestTask.currentRequest;
    return [KTBaseRequest makeCURLWithRequest:request];
}

+ (NSString *)makeCURLWithRequest:(NSURLRequest *)request {
#warning TODO 0225
	return nil;
	
//    NSURLSession *session = KTRequestManager.manager.sharedSession;
//    NSMutableArray *components = @[@"curl "].mutableCopy;
//
//    NSURL *URL = request.URL;
//    NSString *host = URL.host;
//    if (!URL || !host) {
//        return @"curl command could not be created";
//    }
//
//    NSString *HTTPMethod = request.HTTPMethod;
//    if (![HTTPMethod isEqualToString:@"GET"] && !vv_isEmptyStr(HTTPMethod)) {
//        [components addObject:[NSString stringWithFormat:@"-X %@",HTTPMethod]];
//    }
//
//    NSURLCredentialStorage *credentialStorage = session.configuration.URLCredentialStorage;
//
//    NSURLProtectionSpace *protectionSpace = [NSURLProtectionSpace.alloc initWithHost:host port:URL.port.integerValue protocol:URL.scheme realm:host authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
//
//    NSArray <NSURLCredential *>*credentials = [credentialStorage credentialsForProtectionSpace:protectionSpace].allValues;
//    for (NSURLCredential *credential in credentials) {
//        if (!vv_isEmptyStr(credential.user) && !vv_isEmptyStr(credential.password)) {
//            NSString *str = [NSString stringWithFormat:@"-u %@:%@",credential.user, credential.password];
//            [components addObject:str];
//        }
//    }
//
//    if (session.configuration.HTTPShouldSetCookies) {
//        NSHTTPCookieStorage *cookieStorage = session.configuration.HTTPCookieStorage;
//        NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:URL];
//        if (cookies.count > 0) {
//            NSMutableString *cookieString = NSMutableString.string;
//            for (NSHTTPCookie *cookie in cookies) {
//                [cookieString appendFormat:@"%@=%@;",cookie.name,cookie.value];
//            }
//            if (!vv_isEmptyStr(cookieString)) {
//                NSString *str = [NSString stringWithFormat:@"-b \"%@\"",cookieString];
//                [components addObject:str];
//            }
//        }
//    }
//
//    NSMutableDictionary *headers = NSMutableDictionary.dictionary;
//    NSDictionary *additionalHeaders = session.configuration.HTTPAdditionalHeaders;
//    NSDictionary *headerFields = request.allHTTPHeaderFields;
//    [headers addEntriesFromDictionary:additionalHeaders];
//    [headers addEntriesFromDictionary:headerFields];
//    [headers removeObjectForKey:@"Cookie"];
//
//    for (id key in headers.allKeys) {
//        if (!vv_isEmptyStr(key) && !vv_isEmptyStr(headers[key])) {
//            NSString *str = [NSString stringWithFormat:@"-H \"%@:%@\"",key, headers[key]];
//            [components addObject:str];
//        }
//    }
//
//    NSData *HTTPBodyData = request.HTTPBody;
//    NSString *HTTPBody = [[NSString alloc] initWithData:HTTPBodyData encoding:NSUTF8StringEncoding];
//    if (HTTPBody) {
//        NSString *escapedBody = [HTTPBody stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\\\\\""];
//        escapedBody = [escapedBody stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//        NSString *str = [NSString stringWithFormat:@"-d \"%@\"",escapedBody];
//        if (!vv_isEmptyStr(escapedBody)) {
//            [components addObject:str];
//        }
//    }
//
//    if (!vv_isEmptyStr(URL.absoluteString)) {
//        NSString *str = [NSString stringWithFormat:@"--compressed \"%@\"",URL.absoluteString];
//        [components addObject:str];
//    }
//
//    NSString *command = [components componentsJoinedByString:@" \\\n\t"];
//
//    return command;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.requestTask.currentRequest.URL, self.requestTask.currentRequest.HTTPMethod, self.requestArgument];
}

@end
