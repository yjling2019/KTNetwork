//
//  VVRequestInGroupProtocol.h
//  vv_rootlib_ios
//
//  Created by JackLee on 2021/4/21.
//

#ifndef VVRequestInGroupProtocol_h
#define VVRequestInGroupProtocol_h

@class VVGroupRequest;

@protocol VVGroupChildRequestProtocol <NSObject>

/// the status of the request is not in a batchRequest or not in a chainRequest,default is YES
@property (nonatomic, assign, readonly) BOOL isIndependentRequest;

@property (nonatomic, weak, nullable) __kindof VVGroupRequest *groupRequest;

/// the childRequest success block
@property (nonatomic, copy, nullable) void(^childSuccessBlock)(NSObject<VVGroupChildRequestProtocol> * _Nonnull request);

/// the childRequest failure block
@property (nonatomic, copy, nullable) void(^childFailureBlock)(NSObject<VVGroupChildRequestProtocol> * _Nonnull request);

/// complete the groupRequest(batchRequest or chainRequest) in advance,even if the groupRequest has requests not complete.
- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess;

@end
#endif /* VVRequestInGroupProtocol_h */
