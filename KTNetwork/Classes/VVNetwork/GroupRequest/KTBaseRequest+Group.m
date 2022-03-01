//
//  KTBaseRequest+Group.m
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBaseRequest+Group.h"
#import "KTGroupRequest.h"
#import <objc/runtime.h>

static char const *const kGroupRequest ="com.kotu.network.groupRequest";

@implementation KTBaseRequest(Group)

@dynamic successBlock;
@dynamic failureBlock;

- (void)setGroupRequest:(__kindof KTGroupRequest *)groupRequest
{
	objc_setAssociatedObject(self, kGroupRequest, groupRequest, OBJC_ASSOCIATION_RETAIN);
}

- (KTGroupRequest *)groupRequest
{
	return objc_getAssociatedObject(self, kGroupRequest);
}

#pragma mark - - KTRequestInGroupProtocol - -
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
