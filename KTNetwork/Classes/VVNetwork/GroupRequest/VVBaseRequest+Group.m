//
//  VVBaseRequest+Group.m
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseRequest+Group.h"
#import "VVGroupRequest.h"

@implementation VVBaseRequest(Group)

@dynamic successBlock;
@dynamic failureBlock;

#warning TODO 0225
- (void)setGroupRequest:(__kindof VVGroupRequest *)groupRequest
{
	
}

- (VVGroupRequest *)groupRequest
{
	return nil;
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
