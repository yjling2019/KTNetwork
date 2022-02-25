//
//  VVChainRequest.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVGroupRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class VVChainRequest;

typedef void(^KTChainRequestBlock)(VVChainRequest *chainRequest);

@interface VVChainRequest : VVGroupRequest

- (void)startWithCompletionSuccess:(nullable KTChainRequestBlock)successBlock
						   failure:(nullable KTChainRequestBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
