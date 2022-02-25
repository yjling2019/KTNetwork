//
//  VVChainRequest.m
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVChainRequest.h"
#import "VVNetworkAgent.h"
#import "TDScope.h"
#import "VVBaseRequest+Private.h"
#import "VVGroupRequest+Private.h"
#import "VVBaseRequest+Group.h"

@interface VVChainRequest()

@property (nonatomic, strong, nullable) __kindof NSObject<VVGroupChildRequestProtocol> *lastRequest;
@property (nonatomic, assign, readonly) BOOL canStartNextRequest;

@end

@implementation VVChainRequest

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
	[[VVNetworkAgent sharedAgent] removeChainRequest:self];
	self.executing = NO;
}

- (void)startWithCompletionSuccess:(nullable void (^)(VVChainRequest *chainRequest))successBlock
						   failure:(nullable void (^)(VVChainRequest *chainRequest))failureBlock
{
	self.groupSuccessBlock = successBlock;
	self.groupFailureBlock = failureBlock;
	[[VVNetworkAgent sharedAgent] addChainRequest:self];
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
		VVBaseRequest *request = self.requestArray[self.finishedCount];
		self.finishedCount++;
		if ([request isKindOfClass:[VVBaseUploadRequest class]]) {
			VVBaseUploadRequest *uploadRequest = (VVBaseUploadRequest *)request;
			@weakify(self);
			[uploadRequest uploadWithProgress:uploadRequest.progressBlock formDataBlock:uploadRequest.formDataBlock success:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else if ([request isKindOfClass:[VVBaseDownloadRequest class]]) {
			VVBaseDownloadRequest *downloadRequest = (VVBaseDownloadRequest *)request;
			@weakify(self);
			[downloadRequest downloadWithProgress:downloadRequest.progressBlock success:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else {
			@weakify(self);
			[request startWithCompletionSuccess:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		}
	}
}

- (void)handleSuccessOfRequest:(__kindof VVBaseRequest *)request
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

- (void)handleFailureOfRequest:(__kindof VVBaseRequest *)request
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
	for (__kindof NSObject<VVGroupChildRequestProtocol> *tmpRequest in [self.requestArray copy]) {
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
