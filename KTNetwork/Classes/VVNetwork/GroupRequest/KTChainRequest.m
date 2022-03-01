//
//  KTChainRequest.m
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTChainRequest.h"
#import "KTNetworkAgent.h"
#import "TDScope.h"
#import "KTBaseRequest+Private.h"
#import "KTGroupRequest+Private.h"
#import "KTBaseRequest+Group.h"
#import "KTBaseDownloadRequest.h"
#import "KTBaseUploadRequest.h"

@interface KTChainRequest()

@property (nonatomic, strong, nullable) id <KTGroupChildRequestProtocol> lastRequest;
@property (nonatomic, assign, readonly) BOOL canStartNextRequest;

@end

@implementation KTChainRequest

- (void)clearRequest
{
	[super clearRequest];
	self.lastRequest = nil;
}

- (void)realyStart
{
	[self startNextRequest];
}

- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
	self.inAdvanceCompleted = YES;
	if (isSuccess) {
		[self finishAllRequestsWithSuccessBlock];
	} else {
		[self finishAllRequestsWithFailureBlock];
	}
}

#pragma mark - finish handle
- (void)startNextRequest
{
	if (self.canStartNextRequest) {
		KTBaseRequest *request = self.requestArray[self.finishedCount];
		self.finishedCount++;
		if ([request isKindOfClass:[KTBaseUploadRequest class]]) {
			KTBaseUploadRequest *uploadRequest = (KTBaseUploadRequest *)request;
			@weakify(self);
			[uploadRequest uploadWithProgress:uploadRequest.progressBlock formDataBlock:uploadRequest.formDataBlock success:^(__kindof KTBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof KTBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else if ([request isKindOfClass:[KTBaseDownloadRequest class]]) {
			KTBaseDownloadRequest *downloadRequest = (KTBaseDownloadRequest *)request;
			@weakify(self);
			[downloadRequest downloadWithProgress:downloadRequest.progressBlock success:^(__kindof KTBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof KTBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else if ([request isKindOfClass:[KTBaseRequest class]]) {
			@weakify(self);
			[request startWithCompletionSuccess:^(id <KTRequestProcessProtocol> request) {
				@strongify(self);
				[self handleSuccessOfRequest:(KTBaseRequest *)request];
			} failure:^(id <KTRequestProcessProtocol> request) {
				@strongify(self);
				[self handleFailureOfRequest:(KTBaseRequest *)request];
			}];
		}
	}
}

- (void)handleSuccessOfRequest:(__kindof KTBaseRequest *)request
{
	self.lastRequest = request;
	if (request.successBlock) {
		request.successBlock(request);
		if (self.inAdvanceCompleted) {
			return;
		}
	}
	if (self.canStartNextRequest) {
		[self startNextRequest];
	} else {
		[self finishAllRequestsWithSuccessBlock];
	}
}

- (void)handleFailureOfRequest:(__kindof KTBaseRequest *)request
{
	if (!self.failedRequests) {
		self.failedRequests = [NSMutableArray new];
	}
	[self.failedRequests addObject:request];
	self.lastRequest = request;
	if (request.failureBlock) {
		request.failureBlock(request);
		if (self.inAdvanceCompleted) {
			return;
		}
	}
	for (id <KTGroupChildRequestProtocol> tmpRequest in [self.requestArray copy]) {
		[tmpRequest stop];
	}
	[self finishAllRequestsWithFailureBlock];
}

#pragma mark - getter
- (BOOL)canStartNextRequest
{
	return self.finishedCount < [self.requestArray count] && !self.inAdvanceCompleted;
}

@end
