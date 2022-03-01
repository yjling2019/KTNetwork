//
//  KTBatchRequest.h
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTGroupRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class KTBatchRequest;

typedef void(^KTBatchRequestBlock)(KTBatchRequest *batchRequest);

@interface KTBatchRequest : KTGroupRequest

/*
 config the require success requests
 if not config,or the config requests has no elment, only one request success, the batchRequest success block will be called;only all requests in batchRequest failed,the batchRequest fail block will be called.
 if config the requests,only the requests in the config requests all success,then the batchRequest success block will be called,if one of request in config request failed,the batchRequest fail block will be called.
 this method should invoke after you add the request in the batchRequest.
 */
- (void)configRequireSuccessRequests:(nullable NSArray <__kindof NSObject <KTGroupChildRequestProtocol> *> *)requests;

@end

NS_ASSUME_NONNULL_END
