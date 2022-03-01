//
//  KTGroupRequest.m
//  KOTU
//
//  Created by KOTU on 2019/11/15.
//

#import "KTGroupRequest.h"
#import "KTNetworkAgent.h"
#import "TDScope.h"
#import "KTBaseRequest+Private.h"
#import "KTGroupRequest+Private.h"

@implementation KTGroupRequest

@synthesize groupRequest = _groupRequest;

@synthesize successBlock = _successBlock;
@synthesize failureBlock = _failureBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray new];
        _finishedCount = 0;
    }
    return self;
}

#pragma mark - public
- (void)addRequest:(id <KTGroupChildRequestProtocol>)request
{
    if (![request conformsToProtocol:@protocol(KTGroupChildRequestProtocol)]) {
#if DEBUG
        NSAssert(NO, @"makesure request is conforms to protocol KTRequestInGroupProtocol");
#endif
        return;
    }
    if ([self.requestArray containsObject:request]) {
#if DEBUG
        NSAssert(NO, @"request was added");
#endif
        return;
    }
    request.groupRequest = self;
    [self.requestArray addObject:request];
}

- (void)addRequestsWithArray:(NSArray <id <KTGroupChildRequestProtocol>> *)requestArray
{
    NSMutableSet *tmpSet = [NSMutableSet setWithArray:requestArray];
    if (tmpSet.count != requestArray.count) {
#if DEBUG
        NSAssert(NO, @"requestArray has duplicated requests");
#endif
        return;
    }
    NSMutableSet *requestSet = [NSMutableSet setWithArray:self.requestArray];
    BOOL hasCommonRequest = [requestSet intersectsSet:tmpSet];
    if (hasCommonRequest) {
#if DEBUG
        NSAssert(NO, @"requestArray has common request with the added requests");
#endif
        return;
    }
    for (id <KTGroupChildRequestProtocol> request in requestArray) {
        [self addRequest:request];
    }
}

#pragma mark - private
- (void)finishAllRequestsWithSuccessBlock
{
	[self willFinished];
	if (self.successBlock) {
		self.successBlock(self);
	}
	
	[self stop];
	[self clearRequest];
	[self didFinished];
}

- (void)finishAllRequestsWithFailureBlock
{
	[self willFinished];
	if (self.failureBlock) {
		self.failureBlock(self);
	}
	
	[self stop];
	[self clearRequest];
	[self didFinished];
}

#pragma mark - KTRequestProcessProtocol
- (void)start
{
	if (self.requestArray.count == 0) {
		return;
	}
	
	if (self.executing) {
		return;
	}
	
	[self willStart];
	[[KTNetworkAgent sharedAgent] startRequest:self];
}

- (void)startWithCompletionSuccess:(nullable KTRequestProcessBlock)successBlock
						   failure:(nullable KTRequestProcessBlock)failureBlock
{
	self.successBlock = successBlock;
	self.failureBlock = failureBlock;
	[self start];
}

- (void)cancel
{
	[self stop];
	[self clearRequest];
}

- (void)realyStart
{
}

- (void)willStart
{
	self.inAdvanceCompleted = NO;
	self.executing = YES;
	
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestWillStart:)]) {
		[self.requestAccessory requestWillStart:self];
	}
}

- (void)didStart
{
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestDidStart:)]) {
		[self.requestAccessory requestDidStart:self];
	}
}

- (void)stop
{
	for (__kindof KTBaseRequest *baseRequest in [self.requestArray copy]) {
		[baseRequest stop];
	}
	[[KTNetworkAgent sharedAgent] cancelRequest:self];
}

- (void)willFinished
{
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestWillStop:)]) {
		[self.requestAccessory requestWillStop:self];
	}
}

- (void)didFinished
{
	if (self.isIndependentRequest &&
		self.requestAccessory &&
		[self.requestAccessory respondsToSelector:@selector(requestDidStop:)]) {
		[self.requestAccessory requestDidStop:self];
	}
}

- (void)clearRequest
{
	self.successBlock = nil;
	self.failureBlock = nil;
	
	self.finishedCount = 0;
	self.failedRequests = nil;
	self.executing = NO;
}

#pragma mark - KTGroupChildRequestProtocol
- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
    
}

#pragma mark - KTRequestInGroupProtocol 
- (BOOL)isIndependentRequest
{
    return self.groupRequest?NO:YES;
}

- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess
{
    if (self.groupRequest) {
        [self.groupRequest inAdvanceCompleteWithResult:isSuccess];
    }
}

@end
