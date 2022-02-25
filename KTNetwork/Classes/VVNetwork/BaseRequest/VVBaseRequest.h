//
//  VVBaseRequest.h
//  VVRootLib
//
//  Created by JackLee on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN
@class VVBaseRequest,VVNetworkResponse;

typedef NS_ENUM(NSInteger,VVRequestMethod)
{
    VVRequestMethodGET = 0,
    VVRequestMethodPOST,
    VVRequestMethodHEAD,
    VVRequestMethodPUT,
    VVRequestMethodDELETE,
    VVRequestMethodPATCH,
};

typedef NS_ENUM(NSInteger,VVRequestSerializerType)
{
    VVRequestSerializerTypeHTTP = 0,
    VVRequestSerializerTypeJSON,
};

typedef NS_ENUM(NSInteger,VVResponseSerializerType)
{
    VVResponseSerializerTypeHTTP = 0,
    VVResponseSerializerTypeJSON,
    VVResponseSerializerTypeXMLParser,
};

typedef NS_ENUM(NSInteger,VVRequestType)
{
    /// 正常的网络请求
    VVRequestTypeDefault = 0,
    /// 下载文件的网路请求
    VVRequestTypeDownload,
    /// 上传内容的网络请求
    VVRequestTypeUpload
};

typedef NS_ENUM(NSInteger,VVNetworkErrorType) {
  /// the request not support signature
  VVNetworkErrorNotSupportSignature = 10000,
  /// the response is not a valid json
  VVNetworkErrorInvalidJSONFormat,
};

typedef NS_ENUM(NSInteger,VVDownloadBackgroundPolicy) {
 // if the download task not complete, it will apply to some minutes to download
  VVDownloadBackgroundDefault = 0,
  // if the download task not complete,it forbidden to download at background
  VVDownloadBackgroundForbidden,
  // if the download task not complete,it apply download at background until complete
  VVDownloadBackgroundRequire,
};

static NSString * const VVNetworkErrorDomain = @"VVNetworkError";

@protocol VVRequestAccessoryProtocol <NSObject>

@optional

+ (void)requestWillStart:(id)request;

+ (void)requestWillStop:(id)request;

+ (void)requestDidStop:(id)request;

@end


@interface VVBaseRequest : NSObject

@property (nonatomic, assign, readonly) BOOL isIndependentRequest;


/// the request apiName,fact is a path of url,it can contain path and query params
@property (nonatomic, copy, nonnull) NSString *requestUrl;

/// the request baseurl, it can contain host,port,and some path
@property (nonatomic, copy, nullable) NSString *baseUrl;

/// the request baseurl of cdn it can contain host,port,and some path
@property (nonatomic, copy, nullable) NSString *cdnBaseUrl;

/// use cdn or not,default is NO
@property (nonatomic, assign) BOOL useCDN;

/// the request timeout interval
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/// the method of the request,default is GET
@property (nonatomic, assign) VVRequestMethod requestMethod;

/// the request serializer type
@property (nonatomic, assign) VVRequestSerializerType requestSerializerType;

/// the response serializer type
@property (nonatomic, assign) VVResponseSerializerType responseSerializerType;
/// the requestTask of the Request
@property (nonatomic, strong, readonly, nullable) NSURLSessionTask *requestTask;

/// the responseObject of the request
@property (nonatomic, strong, readonly, nullable) id responseObject;

/// the requestJSONObject of the request if the responseObject can not convert to a JSON object it is nil
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseJSONObject;

/// the object of the json validate config
@property (nonatomic, strong, nullable) id jsonValidator;

/// the error of the requestTask
@property (atomic, strong, readonly, nullable) NSError *error;

/// the status of the requestTask is cancelled or not
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

/// the status of the requestTask is executing or not
@property (nonatomic, assign, readonly, getter=isExecuting) BOOL executing;

/// the request header dic
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *requestHeaders;

/// the params of the request
@property (nonatomic, copy, nullable) NSDictionary *requestArgument;

/// use cache or not default is NO
@property (nonatomic, assign) BOOL ignoreCache;

/// if the use the cache please make sure the value bigger than zero
@property (nonatomic, assign) NSInteger cacheTimeInSeconds;

/// 缓存key，子类设置
@property (nonatomic, copy) NSString *cacheKey;

/// is the response is use the cache data,default is NO
@property (nonatomic, assign, readonly) BOOL isDataFromCache;

/// is use the signature for the request
@property (nonatomic, assign) BOOL useSignature;

/// the url has signatured
@property (nonatomic, copy, nullable) NSString *signaturedUrl;

/// the params has signatured
@property (nonatomic, strong, nullable) id signaturedParams;

/// the network status handle class
@property (nonatomic,strong, nullable) Class<VVRequestAccessoryProtocol> requestAccessory;

/// the string of curl request
@property (nonatomic, copy, readonly) NSString *curlRequest;
/// the customUrl of the request,it contain domain,path,query, and so on.
@property (nonatomic, copy, nullable) NSString *customRequestUrl;
/// the data is from response is parsed
@property (nonatomic, strong, readonly, nullable) id parsedData;


- (void)clearCompletionBlock;

- (void)start;

- (void)stop;

/// after request success before successBlock callback,do this func,if you want extra handle,return YES,else return NO
- (BOOL)requestSuccessPreHandle;

///after request failure before successBlock callback,do this func,if you want extra handle,return YES,else return NO
- (BOOL)requestFailurePreHandle;

- (void)startWithCompletionSuccess:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                           failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;
/// start the request
/// @param parseBlock the block used to parse response, exec not in mainThread
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)startWithCompletionParse:(nullable id(^)(__kindof VVBaseRequest *request, NSRecursiveLock *lock))parseBlock
                         success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                         failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

- (void)addRequestHeader:(NSDictionary <NSString *,NSString *>*)header;

/// add the validator for the reponse,if the jsonValidator isn't kind of NSArray or NSDictionary,the func do nothing
- (void)addJsonValidator:(NSDictionary *)validator;

- (BOOL)statusCodeValidator;

/// the custom func of filter url,default is nil
- (NSString *)buildCustomRequestUrl;

/// the custom signature func, default is NO，if use custom signature do the signature in this func
- (BOOL)customSignature;

- (BOOL)readResponseFromCache;

- (void)writeResponseToCacheFile;

- (void)clearResponseFromCache;

+ (NSString *)makeCURLWithRequest:(NSURLRequest *)request;

@end

@interface VVBaseUploadRequest : VVBaseRequest

/// upload data
/// @param uploadProgressBlock uploadProgressBlock
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)uploadWithProgress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
             formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
                   success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                   failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;
@end

@interface VVBaseDownloadRequest :VVBaseRequest

/// the url of the download file resoure
@property (nonatomic, copy, readonly) NSString *absoluteString;
/// the filePath of the downloaded file
@property (nonatomic, copy, nullable, readonly) NSString *downloadedFilePath;
/// the temp filepath of the download file
@property (nonatomic, copy, nullable, readonly) NSString *tempFilePath;
/// the background policy of the downloadRequest
@property (nonatomic, assign) VVDownloadBackgroundPolicy backgroundPolicy;

+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)init NS_UNAVAILABLE;

+ (instancetype)initWithUrl:(nonnull NSString *)url;

/// downloadFile
/// @param downloadProgressBlock downloadProgressBlock
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)downloadWithProgress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
                     success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                     failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

@end

NS_ASSUME_NONNULL_END
