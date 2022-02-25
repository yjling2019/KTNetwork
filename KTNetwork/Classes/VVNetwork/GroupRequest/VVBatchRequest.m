//
//  VVBatchRequest.m
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBatchRequest.h"
#import "VVNetworkAgent.h"
#import "TDScope.h"
#import "VVBaseRequest+Private.h"
#import "VVGroupRequest+Private.h"
#import "VVChainRequest.h"
#import "VVBaseRequest+Group.h"

@interface VVBatchRequest()

@property (nonatomic, strong, nullable) NSMutableArray<__kindof NSObject<VVGroupChildRequestProtocol> *> *requireSuccessRequests;

@end

@implementation VVBatchRequest

- (void)start
{
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
	if (self.isIndependentRequest) {
		if (self.requestAccessory
			&& [self.requestAccessory respondsToSelector:@selector(requestWillStart:)]) {
			[self.requestAccessory requestWillStart:self];
		}
	}
	
	for (__kindof NSObject<VVGroupChildRequestProtocol> *request in self.requestArray) {
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
		} else  if ([request isKindOfClass:[VVBaseRequest class]]) {
			@weakify(self);
			VVBaseRequest *baseRequest = (VVBaseRequest *)request;
			[baseRequest startWithCompletionSuccess:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(__kindof VVBaseRequest * _Nonnull request) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else if ([request isKindOfClass:[VVBatchRequest class]]) {
			VVBatchRequest *batchRequest = (VVBatchRequest *)request;
			@weakify(self);
			[batchRequest startWithCompletionSuccess:^(VVBatchRequest * _Nonnull batchRequest) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(VVBatchRequest * _Nonnull batchRequest) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		} else if ([request isKindOfClass:[VVChainRequest class]]) {
			VVChainRequest *chainRequest = (VVChainRequest *)request;
			@weakify(self);
			[chainRequest startWithCompletionSuccess:^(VVChainRequest * _Nonnull chainRequest) {
				@strongify(self);
				[self handleSuccessOfRequest:request];
			} failure:^(VVChainRequest * _Nonnull chainRequest) {
				@strongify(self);
				[self handleFailureOfRequest:request];
			}];
		}
	}
}

- (void)handleSuccessOfRequest:(__kindof NSObject<VVGroupChildRequestProtocol> *)request
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

- (void)handleFailureOfRequest:(__kindof NSObject<VVGroupChildRequestProtocol> *)request
{
	if (!self.failedRequests) {
		self.failedRequests = [NSMutableArray new];
	}
	
	if ([self.requireSuccessRequests containsObject:request]) {
		[self.failedRequests addObject:request];
		if (request.failureBlock) {
			request.failureBlock(request);
		}
		for (__kindof NSObject<VVGroupChildRequestProtocol> *tmpRequest in [self.requestArray copy]) {
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
			}else {
				// all requests failed,the batchRequests should call fail block
				[self finishAllRequestsWithFailureBlock];
			}
		}
	}
}

- (void)finishAllRequestsWithSuccessBlock
{
	[self handleAccessoryWithBlock:^{
		if (self.groupSuccessBlock) {
			self.groupSuccessBlock(self);
		}
	}];
	[self stop];
}

- (void)finishAllRequestsWithFailureBlock
{
	[self handleAccessoryWithBlock:^{
		if (self.groupFailureBlock) {
			self.groupFailureBlock(self);
		}
	}];
	[self stop];
}

- (void)stop
{
	[self clearCompletionBlock];
	self.finishedCount = 0;
	self.failedRequests = nil;
	[[VVNetworkAgent sharedAgent] removeBatchRequest:self];
	self.executing = NO;
}

- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
#if DEBUG
	NSAssert(NO, @"not support now");
#endif
}

- (void)configRequireSuccessRequests:(nullable NSArray <__kindof NSObject<VVGroupChildRequestProtocol> *> *)requests
{
	for (__kindof NSObject<VVGroupChildRequestProtocol> *request in requests) {
		if (![request conformsToProtocol:@protocol(VVGroupChildRequestProtocol)]) {
#if DEBUG
			NSAssert(NO, @"please make sure request conforms protocol VVRequestInGroupProtocol");
#endif
			return;
		}
	}
	self.requireSuccessRequests = [NSMutableArray arrayWithArray:requests];
}

- (void)startWithCompletionSuccess:(nullable void (^)(VVBatchRequest *batchRequest))successBlock
						   failure:(nullable void (^)(VVBatchRequest *batchRequest))failureBlock
{
	self.groupSuccessBlock = successBlock;
	self.groupFailureBlock = failureBlock;
	[[VVNetworkAgent sharedAgent] addBatchRequest:self];
}

@end
