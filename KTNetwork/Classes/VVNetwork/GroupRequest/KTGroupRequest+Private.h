//
//  KTGroupRequest+Private.h
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTGroupRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface KTGroupRequest()

/// the array of the KTBaseRequest
@property (nonatomic, strong) NSMutableArray <id <KTGroupChildRequestProtocol>> *requestArray;

/// the block of success
@property (nonatomic, copy, nullable) void (^groupSuccessBlock)(__kindof KTGroupRequest *request);
/// the block of failure
@property (nonatomic, copy, nullable) void (^groupFailureBlock)(__kindof KTGroupRequest *request);

/// the status of the KTGroupRequest is executing or not
@property (nonatomic, assign) BOOL executing;
/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign) BOOL inAdvanceCompleted;

/// the count of finished requests
@property (nonatomic, assign) NSInteger finishedCount;
/// the failed requests
@property (nonatomic, strong, nullable) NSMutableArray<id <KTGroupChildRequestProtocol>> *failedRequests;

- (void)handleAccessoryWithBlock:(void(^)(void))block;

- (void)clearCompletionBlock;

@end

NS_ASSUME_NONNULL_END
