//
//  KTRequestInGroupProtocol.h
//  KOTU
//
//  Created by KOTU on 2021/4/21.
//

#ifndef KTRequestInGroupProtocol_h
#define KTRequestInGroupProtocol_h

@class KTGroupRequest;

@protocol KTGroupChildRequestProtocol <NSObject>

@property (nonatomic, weak, nullable) __kindof KTGroupRequest *groupRequest;

/// the childRequest success block
@property (nonatomic, copy, nullable) void(^successBlock)(id <KTGroupChildRequestProtocol> _Nonnull request);

/// the childRequest failure block
@property (nonatomic, copy, nullable) void(^failureBlock)(id <KTGroupChildRequestProtocol> _Nonnull request);

/// the status of the request is not in a batchRequest or not in a chainRequest,default is YES
- (BOOL)isIndependentRequest;
/// complete the groupRequest(batchRequest or chainRequest) in advance,even if the groupRequest has requests not complete.
- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess;

- (void)start;

- (void)stop;

@end

#endif /* KTRequestInGroupProtocol_h */
