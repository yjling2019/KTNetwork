//
//  VVBaseRequest.m
//  VVRootLib
//
//  Created by JackLee on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import "VVBaseRequest.h"
#import "VVNetworkAgent.h"
#import "VVNetworkConfig.h"
#import "VVGroupRequest.h"

@interface VVBaseRequest()

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;

@property (nonatomic, strong, readwrite, nullable) id responseObject;

@property (nonatomic, strong, readwrite, nullable) NSDictionary *responseJSONObject;

@property (atomic, strong, readwrite, nullable) NSError *error;

@property (nonatomic, assign, readwrite) BOOL isDataFromCache;
/// the parse block
@property (nonatomic, copy, nullable) id(^parseBlock)(__kindof VVBaseRequest *request, NSRecursiveLock *lock);
/// the request success block
@property (nonatomic, copy, nullable) void(^successBlock)(__kindof VVBaseRequest *request);
/// the request failure block
@property (nonatomic, copy, nullable) void(^failureBlock)(__kindof VVBaseRequest *request);
/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);
/// is a default/download/upload request
@property (nonatomic, assign) VVRequestType requestType;
/// when upload data cofig the formData
@property (nonatomic, copy, nullable) void (^formDataBlock)(id<AFMultipartFormData> formData);

@property (nonatomic, strong, readwrite, nullable) id parsedData;

@end

@implementation VVBaseRequest
@synthesize isIndependentRequest;
@synthesize groupRequest;
@synthesize groupSuccessBlock;
@synthesize groupFailureBlock;


- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestTimeoutInterval = 60;
    }
    return self;
}

- (void)clearCompletionBlock
{
    if (self.parseBlock) {
        self.parseBlock = nil;
    }
    if (self.successBlock) {
        self.successBlock = nil;
    }
    if (self.failureBlock) {
        self.failureBlock = nil;
    }
    if (self.groupSuccessBlock) {
        self.groupSuccessBlock = nil;
    }
    if (self.groupFailureBlock) {
        self.groupFailureBlock = nil;
    }
}

- (void)start
{
    if (self.requestType != VVRequestTypeDefault) {
#if DEBUG
		NSAssert(NO, @" request is upload request or download request,please use the specified func");
#endif
        return;
    }
    
    if (self.isIndependentRequest) {
        if (self.requestAccessory && [self.requestAccessory respondsToSelector:@selector(requestWillStart:)]) {
            [self.requestAccessory requestWillStart:self];
        }
    }
    
    if ([VVNetworkConfig sharedConfig].requestHelper
        && [[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(judgeToChangeCachePolicy:)]) {
        [[VVNetworkConfig sharedConfig].requestHelper judgeToChangeCachePolicy:self];
    }
	
    if (self.ignoreCache) {
        self.isDataFromCache = NO;
        [[VVNetworkAgent sharedAgent] addRequest:self];
        return;
    }
    
    if (![self readResponseFromCache]) {
        self.isDataFromCache = NO;
        [[VVNetworkAgent sharedAgent] addRequest:self];
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
    [[VVNetworkAgent sharedAgent] cancelRequest:self];
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

- (void)startWithCompletionSuccess:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                           failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
    [self startWithCompletionParse:nil success:successBlock failure:failureBlock];
}

- (void)startWithCompletionParse:(nullable id(^)(__kindof VVBaseRequest *request, NSRecursiveLock *lock))parseBlock
                         success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                         failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
    if (self.requestType != VVRequestTypeDefault) {
 #if DEBUG
         NSAssert(NO, @" request is upload request or download request,please use the specified func");
 #endif
         return;
     }
     self.parseBlock = parseBlock;
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
    if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(loadCacheDataOfRequest:error:)]) {
        NSError *error = nil;
        id responseObject = [[VVNetworkConfig sharedConfig].requestHelper loadCacheDataOfRequest:self error:&error];
        self.responseObject = responseObject;
        if (self.responseSerializerType == VVResponseSerializerTypeJSON) {
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
    if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(saveResponseToCacheOfRequest:)]) {
        [[VVNetworkConfig sharedConfig].requestHelper saveResponseToCacheOfRequest:self];
    }
}

- (void)clearResponseFromCache
{
    if ([[VVNetworkConfig sharedConfig].requestHelper respondsToSelector:@selector(clearResponseFromCacheOfRequest:)]) {
        [[VVNetworkConfig sharedConfig].requestHelper clearResponseFromCacheOfRequest:self];
    }
}

#pragma mark - - VVRequestInGroupProtocol - -
- (BOOL)isIndependentRequest
{
    return self.groupRequest?NO:YES;
}

- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess
{
    if (self.groupRequest) {
        [self.groupRequest inAdvanceCompleteWithResult:isSuccess];
    }else {
#if DEBUG
        NSAssert(NO, @"self.groupRequest is nil");
#endif
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
    return [VVBaseRequest makeCURLWithRequest:request];
}

+ (NSString *)makeCURLWithRequest:(NSURLRequest *)request {
#warning TODO 0225
	return nil;
	
//    NSURLSession *session = VVRequestManager.manager.sharedSession;
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

@interface VVBaseUploadRequest()

@end

@implementation VVBaseUploadRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestType = VVRequestTypeUpload;
    }
    return self;
}

- (void)uploadWithProgress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
             formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
                   success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                   failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.progressBlock = uploadProgressBlock;
    self.formDataBlock = formDataBlock;
    [[VVNetworkAgent sharedAgent] addRequest:self];
}
@end

@interface VVBaseDownloadRequest()

/// the url of the download file resoure
@property (nonatomic, copy, readwrite) NSString *absoluteString;

/// the filePath of the downloaded file
@property (nonatomic, copy, readwrite) NSString *downloadedFilePath;

@property (nonatomic, copy, readwrite) NSString *tempFilePath;


@end

@implementation VVBaseDownloadRequest

+ (instancetype)initWithUrl:(nonnull NSString *)url
{
    VVBaseDownloadRequest *request = [[self alloc] init];
    if (request) {
#if DEBUG
        NSAssert(url, @"url can't be nil");
#endif
        request.absoluteString = url;
    }
    return request;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestType = VVRequestTypeDownload;
    }
    return self;
}

- (NSString *)buildCustomRequestUrl
{
    return self.absoluteString;
}

- (void)downloadWithProgress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
                     success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                     failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.progressBlock = downloadProgressBlock;
    [[VVNetworkAgent sharedAgent] addRequest:self];
}

#pragma mark - - getter - -
- (nullable NSString *)downloadedFilePath
{
#warning TODO 0225
	return nil;
	
//    if (!_downloadedFilePath) {
//        if (!vv_safeStr(self.absoluteString)) {
//            return nil;
//        }
//        NSString *downloadFolderPath = [VVNetworkConfig sharedConfig].downloadFolderPath;
//        NSString *fileName = [VVEncryptHelper MD5String:self.absoluteString];
//        fileName = [fileName stringByAppendingPathExtension:[self.absoluteString pathExtension]]?:@"";
//        _downloadedFilePath = [NSString pathWithComponents:@[downloadFolderPath, fileName]];
//    }
//    return _downloadedFilePath;
}

- (nullable NSString *)tempFilePath
{
#warning TODO 0225
	return nil;
	
//    if (!_tempFilePath) {
//        if (!vv_safeStr(self.absoluteString)) {
//            return nil;
//        }
//        NSString *str = [NSString stringWithFormat:@"backgroundPolicy_%@_%@",@(self.backgroundPolicy),self.absoluteString];
//        NSString *md5URLStr = [VVEncryptHelper MD5String:str];
//        _tempFilePath = [[VVNetworkConfig sharedConfig].incompleteCacheFolder stringByAppendingPathComponent:md5URLStr];
//    }
//    return _tempFilePath;
}


@end


