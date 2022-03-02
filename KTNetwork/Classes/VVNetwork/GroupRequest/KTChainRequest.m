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
#import "KTBaseDownloadRequest.h"
#import "KTBaseUploadRequest.h"

@interface KTChainRequest() <KTGroupChildRequestDelegate>

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
		id <KTGroupChildRequestProtocol> request = self.requestArray[self.finishedCount];
		self.finishedCount++;
		request.delegate = self;
		[request start];
	}
}

#pragma mark - KTGroupChildRequestDelegate
- (void)childRequestDidSuccess:(id <KTGroupChildRequestProtocol> _Nonnull)request
{
	self.lastRequest = request;
	if (request.successBlock) {
		request.successBlock(request);
	}
	if (self.inAdvanceCompleted) {
		return;
	}
	if (self.canStartNextRequest) {
		[self startNextRequest];
	} else {
		[self finishAllRequestsWithSuccessBlock];
	}
}

- (void)childRequestDidFail:(id <KTGroupChildRequestProtocol> _Nonnull)request
{
	if (!self.failedRequests) {
		self.failedRequests = [NSMutableArray new];
	}
	[self.failedRequests addObject:request];
	self.lastRequest = request;
	if (request.failureBlock) {
		request.failureBlock(request);
	}
	if (self.inAdvanceCompleted) {
		return;
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
