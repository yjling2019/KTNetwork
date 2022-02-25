//
//  VVBaseUploadRequest.m
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseUploadRequest.h"
#import "VVNetworkAgent.h"
#import "VVNetworkConfig.h"
#import "VVBaseRequest+Private.h"

@implementation VVBaseUploadRequest

- (void)uploadWithProgress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
			 formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
				   success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
				   failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
	self.successBlock = successBlock;
	self.failureBlock = failureBlock;
	self.progressBlock = uploadProgressBlock;
	self.formDataBlock = formDataBlock;
	[[VVNetworkAgent sharedAgent] addRequest:self];
}

@end
