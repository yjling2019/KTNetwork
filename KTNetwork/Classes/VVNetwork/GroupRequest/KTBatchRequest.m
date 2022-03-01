//
//  KTBatchRequest.m
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBatchRequest.h"
#import "KTNetworkAgent.h"
#import "TDScope.h"
#import "KTBaseRequest+Private.h"
#import "KTGroupRequest+Private.h"
#import "KTChainRequest.h"
#import "KTBaseRequest+Group.h"
#import "KTBaseDownloadRequest.h"
#import "KTBaseUploadRequest.h"

@interface KTBatchRequest()

@property (nonatomic, strong, nullable) NSMutableArray <id <KTGroupChildRequestProtocol>> *requireSuccessRequests;

@end

@implementation KTBatchRequest

- (void)realyStart
{
	self.executing = YES;

	for (id <KTGroupChildRequestProtocol> request in self.requestArray) {
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
			KTBaseRequest *baseRequest = (KTBaseRequest *)request;
			[baseRequest startWithCompletionSuccess:^(id <KTRequestProcessProtocol> _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:(KTBaseRequest *)request];
			} failure:^(id <KTRequestProcessProtocol> _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:(KTBaseRequest *)request];
			}];
		} else if ([request isKindOfClass:[KTBatchRequest class]]) {
			KTBatchRequest *batchRequest = (KTBatchRequest *)request;
			@weakify(self);
			[batchRequest startWithCompletionSuccess:^(id <KTRequestProcessProtocol> batchRequest) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(id <KTRequestProcessProtocol> batchRequest) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else if ([request isKindOfClass:[KTChainRequest class]]) {
			KTChainRequest *chainRequest = (KTChainRequest *)request;
			@weakify(self);
			[chainRequest startWithCompletionSuccess:^(id <KTRequestProcessProtocol> chainRequest) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(id <KTRequestProcessProtocol> chainRequest) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		}
	}
	
	[self didStart];
}

#pragma mark - public
- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
#if DEBUG
	NSAssert(NO, @"not support now");
#endif
}

- (void)configRequireSuccessRequests:(nullable NSArray <id <KTGroupChildRequestProtocol>> *)requests
{
	for (id <KTGroupChildRequestProtocol> request in requests) {
		if (![request conformsToProtocol:@protocol(KTGroupChildRequestProtocol)]) {
#if DEBUG
			NSAssert(NO, @"please make sure request conforms protocol KTRequestInGroupProtocol");
#endif
			return;
		}
	}
	self.requireSuccessRequests = [NSMutableArray arrayWithArray:requests];
}

#pragma mark - finish handle
- (void)handleSuccessOfRequest:(id <KTGroupChildRequestProtocol>)request
{
	self.finishedCount++;
	if (request.successBlock) {
		request.successBlock(request);
	}
	if (self.finishedCount == self.requestArray.count) {
		//the last request success, the batchRequest should call success block
		[self finishAllRequestsWithSuccessBlock];
	}
}

- (void)handleFailureOfRequest:(id <KTGroupChildRequestProtocol>)request
{
	if (!self.failedRequests) {
		self.failedRequests = [NSMutableArray new];
	}
	
	if ([self.requireSuccessRequests containsObject:request]) {
		[self.failedRequests addObject:request];
		if (request.failureBlock) {
			request.failureBlock(request);
		}
		for (id <KTGroupChildRequestProtocol> tmpRequest in [self.requestArray copy]) {
			[tmpRequest stop];
		}
		[self finishAllRequestsWithFailureBlock];
	} else {
		self.finishedCount++;
		[self.failedRequests addObject:request];
		if (request.failureBlock) {
			request.failureBlock(request);
		}
		if (self.finishedCount == self.requestArray.count) {
			if (self.failedRequests.count != self.requestArray.count) {
				// not all requests failed ,the batchRequest should call success block
				[self finishAllRequestsWithSuccessBlock];
			} else {
				// all requests failed,the batchRequests should call fail block
				[self finishAllRequestsWithFailureBlock];
			}
		}
	}
}

@end
