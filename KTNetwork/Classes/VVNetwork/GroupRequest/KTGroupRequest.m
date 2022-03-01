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
#import "KTBaseRequest+Group.h"

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

- (void)start
{
    
}

- (void)stop
{
    
}

- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
    
}

#pragma mark - - KTRequestInGroupProtocol - -
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

- (void)handleAccessoryWithBlock:(void(^)(void))block
{
    if (self.isIndependentRequest) {
        if (self.requestAccessory
            && [self.requestAccessory respondsToSelector:@selector(requestWillStop:)]) {
            [self.requestAccessory requestWillStop:self];
        }
    }
    if (block) {
        block();
    }
    if (self.isIndependentRequest) {
        if (self.requestAccessory
            && [self.requestAccessory respondsToSelector:@selector(requestDidStop:)]) {
            [self.requestAccessory requestDidStop:self];
        }
    }
}

- (void)clearCompletionBlock
{
	self.groupSuccessBlock = nil;
	self.groupFailureBlock = nil;
	self.successBlock = nil;
	self.failureBlock = nil;
}

@end
