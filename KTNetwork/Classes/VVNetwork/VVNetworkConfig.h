//
//  VVNetworkConfig.h
//  VVRootLib
//
//  Created by KOTU on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import "VVRequestHelperProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@class VVBaseRequest;

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
