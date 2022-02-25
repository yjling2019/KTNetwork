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
@property (nonatomic, strong, readwrite) NSMutableArray<__kindof NSObject<VVGroupChildRequestProtocol> *> *requestArray;
/// the block of success
@property (nonatomic, copy, nullable) void (^groupSuccessBlock)(__kindof VVGroupRequest *request);
/// the block of failure
@property (nonatomic, copy, nullable) void (^groupFailureBlock)(__kindof VVGroupRequest *request);
/// the count of finished requests
@property (nonatomic, assign) NSInteger finishedCount;
/// the status of the VVGroupRequest is executing or not
@property (nonatomic, assign) BOOL executing;
/// the failed requests
@property (nonatomic, strong, readwrite, nullable) NSMutableArray<__kindof NSObject<VVGroupChildRequestProtocol> *> *failedRequests;
/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign, readwrite) BOOL inAdvanceCompleted;

- (void)handleAccessoryWithBlock:(void(^)(void))block;

- (void)clearCompletionBlock;

@end

NS_ASSUME_NONNULL_END
