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
/// the failed requests
@property (nonatomic, strong, nullable) NSMutableArray<id <KTGroupChildRequestProtocol>> *failedRequests;


/// the status of the KTGroupRequest is executing or not
@property (nonatomic, assign) BOOL executing;
/// the count of finished requests
@property (nonatomic, assign) NSInteger finishedCount;
/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign) BOOL inAdvanceCompleted;


- (void)finishAllRequestsWithSuccessBlock;
- (void)finishAllRequestsWithFailureBlock;

@end

NS_ASSUME_NONNULL_END
