//
//  VVGroupRequest+Private.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVGroupRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVGroupRequest()

/// the array of the VVBaseRequest
@property (nonatomic, strong) NSMutableArray <id <VVGroupChildRequestProtocol>> *requestArray;

/// the block of success
@property (nonatomic, copy, nullable) void (^groupSuccessBlock)(__kindof VVGroupRequest *request);
/// the block of failure
@property (nonatomic, copy, nullable) void (^groupFailureBlock)(__kindof VVGroupRequest *request);

/// the status of the VVGroupRequest is executing or not
@property (nonatomic, assign) BOOL executing;
/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign) BOOL inAdvanceCompleted;

/// the count of finished requests
@property (nonatomic, assign) NSInteger finishedCount;
/// the failed requests
@property (nonatomic, strong, nullable) NSMutableArray<id <VVGroupChildRequestProtocol>> *failedRequests;

- (void)handleAccessoryWithBlock:(void(^)(void))block;

- (void)clearCompletionBlock;

@end

NS_ASSUME_NONNULL_END
