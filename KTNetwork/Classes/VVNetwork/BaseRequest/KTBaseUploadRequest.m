//
//  KTBaseUploadRequest.m
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBaseUploadRequest.h"
#import "KTNetworkAgent.h"
#import "KTNetworkConfig.h"
#import "KTBaseRequest+Private.h"

@implementation KTBaseUploadRequest

- (void)uploadWithProgress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
			 formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
				   success:(nullable void(^)(__kindof KTBaseRequest *request))successBlock
				   failure:(nullable void(^)(__kindof KTBaseRequest *request))failureBlock
{
	self.successBlock = successBlock;
	self.failureBlock = failureBlock;
	self.progressBlock = uploadProgressBlock;
	self.formDataBlock = formDataBlock;
	[[KTNetworkAgent sharedAgent] addRequest:self];
}

@end
