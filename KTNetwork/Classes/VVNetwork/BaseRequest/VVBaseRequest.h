//
//  VVBaseRequest.h
//  VVRootLib
//
//  Created by KOTU on 2019/9/10.
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

#pragma mark - request
/// the request apiName,fact is a path of url,it can contain path and query params
@property (nonatomic, copy, nonnull) NSString *requestUrl;
/// the request baseurl, it can contain host,port,and some path
@property (nonatomic, copy, nullable) NSString *baseUrl;
/// the string of curl request
@property (nonatomic, copy, readonly) NSString *curlRequest;
/// the customUrl of the request,it contain domain,path,query, and so on.
@property (nonatomic, copy, nullable) NSString *customRequestUrl;
/// the method of the request,default is GET
@property (nonatomic, assign) VVRequestMethod requestMethod;
/// the params of the request
@property (nonatomic, copy, nullable) NSDictionary *requestArgument;

/// the custom func of filter url,default is nil
- (NSString *)buildCustomRequestUrl;

#pragma mark - config
/// the request timeout interval
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;
/// the request serializer type
@property (nonatomic, assign) VVRequestSerializerType requestSerializerType;
/// the response serializer type
@property (nonatomic, assign) VVResponseSerializerType responseSerializerType;
/// the request header dic
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *requestHeaders;

/// the network status handle class
@property (nonatomic,strong, nullable) Class<VVRequestAccessoryProtocol> requestAccessory;

- (void)addRequestHeader:(NSDictionary <NSString *,NSString *>*)header;

#pragma mark - identifier
@property (nonatomic, copy) NSString *module;
@property (nonatomic, copy) NSString *tag;

#pragma mark - context
@property (nonatomic, assign, readonly) BOOL isIndependentRequest;
/// the requestTask of the Request
@property (nonatomic, strong, readonly, nullable) NSURLSessionTask *requestTask;

#pragma mark - response
/// the responseObject of the request
@property (nonatomic, strong, readonly, nullable) id responseObject;
/// the requestJSONObject of the request if the responseObject can not convert to a JSON object it is nil
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseJSONObject;
/// the data is from response is parsed
@property (nonatomic, strong, readonly, nullable) id parsedData;
/// the error of the requestTask
@property (atomic, strong, readonly, nullable) NSError *error;

#pragma mark - validator
/// the object of the json validate config
@property (nonatomic, strong, nullable) id jsonValidator;
/// add the validator for the reponse,if the jsonValidator isn't kind of NSArray or NSDictionary,the func do nothing
- (void)addJsonValidator:(NSDictionary *)validator;

- (BOOL)statusCodeValidator;

#pragma mark - status
/// the status of the requestTask is cancelled or not
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;
/// the status of the requestTask is executing or not
@property (nonatomic, assign, readonly, getter=isExecuting) BOOL executing;

#pragma mark - cache
/// use cache or not default is NO
@property (nonatomic, assign) BOOL ignoreCache;
/// if the use the cache please make sure the value bigger than zero
@property (nonatomic, assign) NSInteger cacheTimeInSeconds;
/// is the response is use the cache data,default is NO
@property (nonatomic, assign, readonly) BOOL isDataFromCache;
/// 缓存key，子类设置
@property (nonatomic, copy) NSString *cacheKey;

- (BOOL)readResponseFromCache;
- (void)writeResponseToCacheFile;
- (void)clearResponseFromCache;

#pragma mark - signature
/// is use the signature for the request
@property (nonatomic, assign) BOOL useSignature;
/// the url has signatured
@property (nonatomic, copy, nullable) NSString *signaturedUrl;
/// the params has signatured
@property (nonatomic, strong, nullable) id signaturedParams;

/// the custom signature func, default is NO，if use custom signature do the signature in this func
- (BOOL)customSignature;

#pragma mark - CDN
/// use cdn or not,default is NO
@property (nonatomic, assign) BOOL useCDN;
/// the request baseurl of cdn it can contain host,port,and some path
@property (nonatomic, copy, nullable) NSString *cdnBaseUrl;

#pragma mark - handle
/// after request success before successBlock callback,do this func,if you want extra handle,return YES,else return NO
- (BOOL)requestSuccessPreHandle;

///after request failure before successBlock callback,do this func,if you want extra handle,return YES,else return NO
- (BOOL)requestFailurePreHandle;

#pragma mark - operation
- (void)start;

- (void)stop;

- (void)startWithCompletionSuccess:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                           failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

- (void)clearCompletionBlock;

#pragma mark - utils
+ (NSString *)makeCURLWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
