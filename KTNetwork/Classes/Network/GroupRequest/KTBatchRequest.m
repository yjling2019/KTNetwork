//
//  KTBatchRequest.m
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBatchRequest.h"
#import "KTNetworkAgent.h"
#import "KTBaseRequest+Private.h"
#import "KTGroupRequest+Private.h"
#import "KTChainRequest.h"
#import "KTBaseDownloadRequest.h"
#import "KTBaseUploadRequest.h"

@interface KTBatchRequest() <KTGroupChildRequestDelegate>

@property (nonatomic, strong, nullable) NSMutableArray <id <KTGroupChildRequestProtocol>> *requireSuccessRequests;

@end

@implementation KTBatchRequest

- (void)realyStart
{
	self.executing = YES;

	for (id <KTGroupChildRequestProtocol> request in self.requestArray) {
		request.delegate = self;
		[request start];
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

#pragma mark - KTGroupChildRequestDelegate
- (void)childRequestDidSuccess:(id <KTGroupChildRequestProtocol>)request
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

- (void)childRequestDidFail:(id <KTGroupChildRequestProtocol>)request
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
