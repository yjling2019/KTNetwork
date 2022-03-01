//
//  KTGroupRequest.h
//  KOTU
//
//  Created by KOTU on 2019/11/15.
//

#import <Foundation/Foundation.h>
#import "KTBaseRequest.h"
#import "KTGroupChildRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KTGroupChildRequestProtocol;

@interface KTGroupRequest : NSObject<KTGroupChildRequestProtocol>

/// the class to handle the request indicator
@property (nonatomic, strong, nullable) Class<KTRequestAccessoryProtocol> requestAccessory;

/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign, readonly) BOOL inAdvanceCompleted;
/// the array of the KTBaseRequest
@property (nonatomic, strong, readonly) NSMutableArray <id <KTGroupChildRequestProtocol>> *requestArray;
/// the failed requests
@property (nonatomic, strong, readonly, nullable) NSMutableArray <id <KTGroupChildRequestProtocol>> *failedRequests;

/// add child request,make sure request conform protocol KTRequestProtocol
/// @param request request
- (void)addRequest:(id <KTGroupChildRequestProtocol>)request;

/// add child requests,make sure the request in requestArray conform protocol KTRequestProtocol
/// @param requestArray requestArray
- (void)addRequestsWithArray:(NSArray <id <KTGroupChildRequestProtocol>> *)requestArray;

/// start current request
- (void)start;

/// stop current request
- (void)stop;

/// inadvance self with the result
/// @param isSuccess the result
- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
