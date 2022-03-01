//
//  KTChainRequest.h
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTGroupRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class KTChainRequest;

typedef void(^KTChainRequestBlock)(KTChainRequest *chainRequest);

@interface KTChainRequest : KTGroupRequest

- (void)startWithCompletionSuccess:(nullable KTChainRequestBlock)successBlock
						   failure:(nullable KTChainRequestBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
