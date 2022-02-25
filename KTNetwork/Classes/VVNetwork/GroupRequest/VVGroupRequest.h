//
//  VVGroupRequest.h
//  vv_rootlib_ios
//
//  Created by JackLee on 2019/11/15.
//

#import <Foundation/Foundation.h>
#import "VVBaseRequest.h"
#import "VVGroupChildRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VVGroupChildRequestProtocol;

@interface VVGroupRequest : NSObject<VVGroupChildRequestProtocol>

/// the array of the VVBaseRequest
@property (nonatomic, strong, readonly) NSMutableArray<__kindof NSObject<VVGroupChildRequestProtocol> *> *requestArray;
/// the class to handle the request indicator
@property (nonatomic, strong, nullable) Class<VVRequestAccessoryProtocol> requestAccessory;
/// the failed requests
@property (nonatomic, strong, readonly, nullable) NSMutableArray<__kindof NSObject<VVGroupChildRequestProtocol> *> *failedRequests;

/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign, readonly) BOOL inAdvanceCompleted;

/// add child request,make sure request conform protocol VVRequestProtocol
/// @param request request
- (void)addRequest:(__kindof NSObject<VVGroupChildRequestProtocol> *)request;

/// add child requests,make sure the request in requestArray conform protocol VVRequestProtocol
/// @param requestArray requestArray
- (void)addRequestsWithArray:(NSArray<__kindof NSObject<VVGroupChildRequestProtocol> *>*)requestArray;

- (void)start;

- (void)stop;

/// inadvance self with the result
/// @param isSuccess the result
- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
