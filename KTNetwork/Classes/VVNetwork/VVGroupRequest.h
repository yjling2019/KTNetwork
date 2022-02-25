//
//  VVGroupRequest.h
//  vv_rootlib_ios
//
//  Created by JackLee on 2019/11/15.
//

#import <Foundation/Foundation.h>
#import "VVBaseRequest.h"
#import "VVRequestInGroupProtocol.h"
NS_ASSUME_NONNULL_BEGIN
@protocol VVRequestInGroupProtocol;

@interface VVGroupRequest : NSObject<VVRequestInGroupProtocol>
/// the array of the VVBaseRequest
@property (nonatomic, strong, readonly) NSMutableArray<__kindof NSObject<VVRequestInGroupProtocol> *> *requestArray;
/// the class to handle the request indicator
@property (nonatomic, strong, nullable) Class<VVRequestAccessoryProtocol> requestAccessory;
/// the failed requests
@property (nonatomic, strong, readonly, nullable) NSMutableArray<__kindof NSObject<VVRequestInGroupProtocol> *> *failedRequests;

/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign, readonly) BOOL inAdvanceCompleted;

/// add child request,make sure request conform protocol VVRequestProtocol
/// @param request request
- (void)addRequest:(__kindof NSObject<VVRequestInGroupProtocol> *)request;

/// add child requests,make sure the request in requestArray conform protocol VVRequestProtocol
/// @param requestArray requestArray
- (void)addRequestsWithArray:(NSArray<__kindof NSObject<VVRequestInGroupProtocol> *>*)requestArray;

- (void)start;

- (void)stop;

/// inadvance self with the result
/// @param isSuccess the result
- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess;

+ (void)configNormalRequest:(__kindof VVBaseRequest *)request
                    success:(void(^)(__kindof VVBaseRequest *request))successBlock
                    failure:(void(^)(__kindof VVBaseRequest *request))failureBlock;

+ (void)configNormalRequest:(__kindof VVBaseRequest *)request
                 parseBlock:(nullable id(^)(__kindof VVBaseRequest *request, NSRecursiveLock *lock))parseBlock
                    success:(void(^)(__kindof VVBaseRequest *request))successBlock
                    failure:(void(^)(__kindof VVBaseRequest *request))failureBlock;

+ (void)configUploadRequest:(__kindof VVBaseUploadRequest *)request
                   progress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
              formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
                    success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                    failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

+ (void)configDownloadRequest:(__kindof VVBaseDownloadRequest *)request
                     progress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
                      success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                      failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

+ (void)configChildGroupRequest:(__kindof VVGroupRequest *)request
                        success:(void(^)(__kindof VVGroupRequest *request))successBlock
                        failure:(void(^)(__kindof VVGroupRequest *request))failureBlock;

@end

#pragma mark - - VVBatchRequest - -

@interface VVBatchRequest : VVGroupRequest

/*
 config the require success requests
 if not config,or the config requests has no elment, only one request success, the batchRequest success block will be called;only all requests in batchRequest failed,the batchRequest fail block will be called.
 if config the requests,only the requests in the config requests all success,then the batchRequest success block will be called,if one of request in config request failed,the batchRequest fail block will be called.
 this method should invoke after you add the request in the batchRequest.
 */
- (void)configRequireSuccessRequests:(nullable NSArray <__kindof NSObject<VVRequestInGroupProtocol> *> *)requests;

- (void)startWithCompletionSuccess:(nullable void (^)(VVBatchRequest *batchRequest))successBlock
                           failure:(nullable void (^)(VVBatchRequest *batchRequest))failureBlock;

@end

#pragma mark - - VVChainRequest - -
@interface VVChainRequest : VVGroupRequest

- (void)startWithCompletionSuccess:(nullable void (^)(VVChainRequest *chainRequest))successBlock
                           failure:(nullable void (^)(VVChainRequest *chainRequest))failureBlock;

@end

NS_ASSUME_NONNULL_END
