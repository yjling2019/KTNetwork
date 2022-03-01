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

- (void)start
{
	self.inAdvanceCompleted = NO;
	if (self.requestArray.count == 0) {
#if DEBUG
		NSAssert(NO, @"please makesure self.requestArray.count > 0");
#endif
		return;
	}
	if (self.executing) {
		return;
	}
	self.executing = YES;
	if ([self.requestArray count] > 0) {
		if (self.requestAccessory  && [self.requestAccessory respondsToSelector:@selector(requestWillStart:)]) {
			[self.requestAccessory requestWillStart:self];
		}
		[self startNextRequest];
	}
}

- (void)stop
{
	[self clearCompletionBlock];
	self.finishedCount = 0;
	self.failedRequests = nil;
	self.lastRequest = nil;
	[[KTNetworkAgent sharedAgent] removeChainRequest:self];
	self.executing = NO;
}

- (void)startWithCompletionSuccess:(nullable void (^)(KTChainRequest *chainRequest))successBlock
						   failure:(nullable void (^)(KTChainRequest *chainRequest))failureBlock
{
	self.groupSuccessBlock = successBlock;
	self.groupFailureBlock = failureBlock;
	[[KTNetworkAgent sharedAgent] addChainRequest:self];
}

- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
	self.inAdvanceCompleted = YES;
	if (isSuccess) {
		[self handleAccessoryWithBlock:^{
			if (self.groupSuccessBlock) {
				self.groupSuccessBlock(self);
			}
		}];
	} else {
		[self handleAccessoryWithBlock:^{
			if (self.groupFailureBlock) {
				self.groupFailureBlock(self);
			}
		}];
	}
	[self stop];
}

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
		} else {
			@weakify(self);
			[request startWithCompletionSuccess:^(__kindof KTBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof KTBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
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
		[self handleAccessoryWithBlock:^{
			if (self.groupSuccessBlock) {
				self.groupSuccessBlock(self);
			}
		}];
		[self stop];
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
	[self handleAccessoryWithBlock:^{
		if (self.groupFailureBlock) {
			self.groupFailureBlock(self);
		}
	}];
	[self stop];
}

#pragma mark - - getter - -
- (BOOL)canStartNextRequest
{
	return self.finishedCount < [self.requestArray count] && !self.inAdvanceCompleted;
}

@end
