//
//  KTRequestInGroupProtocol.h
//  KOTU
//
//  Created by KOTU on 2021/4/21.
//

#ifndef KTRequestInGroupProtocol_h
#define KTRequestInGroupProtocol_h

#import "KTRequestProcessProtocol.h"

@class KTGroupRequest;
@protocol KTGroupChildRequestProtocol;

@protocol KTGroupChildRequestDelegate <NSObject>

- (void)childRequestDidSuccess:(id <KTGroupChildRequestProtocol> _Nonnull)request;
- (void)childRequestDidFail:(id <KTGroupChildRequestProtocol> _Nonnull)request;

@end

@protocol KTGroupChildRequestProtocol <KTRequestProcessProtocol>

@property (nonatomic, weak, nullable) id <KTGroupChildRequestDelegate> delegate;
@property (nonatomic, weak, nullable) __kindof KTGroupRequest *groupRequest;

/// the childRequest success block
@property (nonatomic, copy, nullable) void(^successBlock)(id <KTGroupChildRequestProtocol> _Nonnull request);

/// the childRequest failure block
@property (nonatomic, copy, nullable) void(^failureBlock)(id <KTGroupChildRequestProtocol> _Nonnull request);

/// the status of the request is not in a batchRequest or not in a chainRequest,default is YES
- (BOOL)isIndependentRequest;
/// complete the groupRequest(batchRequest or chainRequest) in advance,even if the groupRequest has requests not complete.
- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess;

@end

#endif /* KTRequestInGroupProtocol_h */
