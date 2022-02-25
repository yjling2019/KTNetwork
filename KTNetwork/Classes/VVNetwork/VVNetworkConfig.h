//
//  VVNetworkConfig.h
//  VVRootLib
//
//  Created by JackLee on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN
@class VVBaseRequest;

@protocol VVRequestHelperProtocol <NSObject>

@optional

/// this is the url append or filter func
/// @param originUrl originUrl
/// @param request request
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(__kindof VVBaseRequest *)request;

/// use this func to signature the request
/// @param request the request
- (void)signatureRequest:(__kindof VVBaseRequest *)request;

/// load Cache data of the request
/// @param request request
- (id)loadCacheDataOfRequest:(__kindof VVBaseRequest *)request error:(NSError **)error;

/// save the request's reponse to cache
/// @param request request
- (void)saveResponseToCacheOfRequest:(__kindof VVBaseRequest *)request;

/// clear the the request's response from cache
/// @param request request
- (void)clearResponseFromCacheOfRequest:(__kindof VVBaseRequest *)request;

/// get the baseUrl of the request
/// @param request request
- (NSString *)baseUrlOfRequest:(__kindof VVBaseRequest *)request;

/// do some action before the request success block
/// @param request request
- (void)preHandleSuccessRequest:(__kindof VVBaseRequest *)request;

/// do some action before the request failure block
/// @param request request
- (void)preHandleFailureRequest:(__kindof VVBaseRequest *)request;

/// before all requests, you can use this func do something
/// this func can only excute once in app lifetime
- (void)beforeAllRequests;

/// before each request,you can use this func do something
/// this func invoked after - (void)beforeAllRequests
/// @param request request
- (void)beforeEachRequest:(__kindof VVBaseRequest *)request;

/// after each request,you can use this func do something
/// @param request request
- (void)afterEachRequest:(__kindof VVBaseRequest *)request;

/// according one api response to judge the request need to cache or not,and cacheTime
/// @param request request
- (void)judgeToChangeCachePolicy:(__kindof VVBaseRequest *)request;

@end

@interface VVNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedConfig;

/// the request baseurl, it can contain host,port,and some path
@property (nonatomic, copy, nullable) NSString *baseUrl;

/// the request baseurl of cdn it can contain host,port,and some path
@property (nonatomic, copy, nullable) NSString *cdnBaseUrl;

/// the baseUrl of the mockRequest
@property (nonatomic, copy, nullable) NSString *mockBaseUrl;

/// the status of the mock,default is NO
@property (nonatomic, assign) BOOL isMock;

/// the all request timeoutInterval in mock model,default is 300 second.
@property (nonatomic, assign) NSUInteger mockModelTimeoutInterval;

/// the security policy ,it use AFNetworking  AFSecurityPolicy
@property (nonatomic, strong, nonnull) AFSecurityPolicy *securityPolicy;

@property (nonatomic, strong, nonnull) NSURLSessionConfiguration *sessionConfiguration;

/// the folder filePath of the download file,the defalut is under doment /VVNetworking_download
@property (nonatomic, copy, nonnull) NSString *downloadFolderPath;

/// the uncompleted folder of the download requests
@property (nonatomic, copy, readonly) NSString *incompleteCacheFolder;

@property (nonatomic, strong, readonly, nullable) id<VVRequestHelperProtocol> requestHelper;
/// HTTP methods for which serialized requests will encode parameters as a query string. `GET`, `HEAD`, and `DELETE` by default.
/// if not set,use the default config
@property (nonatomic, strong, nullable) NSSet <NSString *> *HTTPMethodsEncodingParametersInURI;

- (void)configRequestHelper:(id<VVRequestHelperProtocol>)requestHelper;

@end

NS_ASSUME_NONNULL_END
