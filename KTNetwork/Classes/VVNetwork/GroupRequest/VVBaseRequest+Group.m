//
//  VVBaseRequest+Group.m
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseRequest+Group.h"
#import "VVGroupRequest.h"
#import <objc/runtime.h>

static char const *const kGroupRequest ="com.kotu.network.groupRequest";

@implementation VVBaseRequest(Group)

@dynamic successBlock;
@dynamic failureBlock;

- (void)setGroupRequest:(__kindof VVGroupRequest *)groupRequest
{
	objc_setAssociatedObject(self, kGroupRequest, groupRequest, OBJC_ASSOCIATION_RETAIN);
}

- (VVGroupRequest *)groupRequest
{
	return objc_getAssociatedObject(self, kGroupRequest);
}

#pragma mark - - VVRequestInGroupProtocol - -
- (BOOL)isIndependentRequest
{
	return self.groupRequest ? NO : YES;
}

- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess
{
	if (!self.groupRequest) {
		return;
	}
	[self.groupRequest inAdvanceCompleteWithResult:isSuccess];
}

@end
