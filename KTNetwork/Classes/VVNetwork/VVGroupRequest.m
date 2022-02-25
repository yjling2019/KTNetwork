//
//  VVGroupRequest.m
//  vv_rootlib_ios
//
//  Created by JackLee on 2019/11/15.
//

#import "VVGroupRequest.h"
#import "VVNetworkAgent.h"
#import "TDScope.h"

@interface VVBaseRequest(VVGroupRequest)

/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);
/// when upload data cofig the formData
@property (nonatomic, copy, nullable) void (^formDataBlock)(id<AFMultipartFormData> formData);
/// is a default/download/upload request
@property (nonatomic, assign) VVRequestType requestType;
/// the parse block
@property (nonatomic, copy, nullable) id(^parseBlock)(__kindof VVBaseRequest *request, NSRecursiveLock *lock);
/// the childRequest success block
@property (nonatomic, copy, nullable) void(^groupSuccessBlock)(__kindof VVBaseRequest *request);
/// the childRequest failure block
@property (nonatomic, copy, nullable) void(^groupFailureBlock)(__kindof VVBaseRequest *request);

@end

@implementation VVBaseRequest(VVGroupRequest)

@dynamic progressBlock;
@dynamic formDataBlock;
@dynamic requestType;
@dynamic parseBlock;
@dynamic groupSuccessBlock;
@dynamic groupFailureBlock;

@end

@interface VVGroupRequest()

/// the array of the VVBaseRequest
@property (nonatomic, strong, readwrite) NSMutableArray<__kindof NSObject<VVRequestInGroupProtocol> *> *requestArray;
/// the block of success
@property (nonatomic, copy, nullable) void (^successBlock)(__kindof VVGroupRequest *request);
/// the block of failure
@property (nonatomic, copy, nullable) void (^failureBlock)(__kindof VVGroupRequest *request);
/// the count of finished requests
@property (nonatomic, assign) NSInteger finishedCount;
/// the status of the VVGroupRequest is executing or not
@property (nonatomic, assign) BOOL executing;
/// the failed requests
@property (nonatomic, strong, readwrite, nullable) NSMutableArray<__kindof NSObject<VVRequestInGroupProtocol> *> *failedRequests;
/// the status of the groupRequest is complete inadvance
@property (nonatomic, assign, readwrite) BOOL inAdvanceCompleted;


@end

@implementation VVGroupRequest
@synthesize isIndependentRequest;
@synthesize groupRequest;
@synthesize groupSuccessBlock;
@synthesize groupFailureBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray new];
        _finishedCount = 0;
    }
    return self;
}

- (void)addRequest:(__kindof NSObject<VVRequestInGroupProtocol> *)request
{
    if (![request conformsToProtocol:@protocol(VVRequestInGroupProtocol)]) {
#if DEBUG
        NSAssert(NO, @"makesure request is conforms to protocol VVRequestInGroupProtocol");
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

- (void)addRequestsWithArray:(NSArray<__kindof VVBaseRequest *> *)requestArray
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
    for (__kindof NSObject<VVRequestInGroupProtocol> *request  in requestArray) {
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

#pragma mark - - VVRequestInGroupProtocol - -
- (BOOL)isIndependentRequest
{
    return self.groupRequest?NO:YES;
}

- (void)inAdvanceCompleteGroupRequestWithResult:(BOOL)isSuccess
{
    if (self.groupRequest) {
        [self.groupRequest inAdvanceCompleteWithResult:isSuccess];
    }else {
#if DEBUG
        NSAssert(NO, @"self.groupRequest is nil");
#endif
    }
}


+ (void)configNormalRequest:(__kindof VVBaseRequest *)request
                    success:(void(^)(__kindof VVBaseRequest *request))successBlock
                    failure:(void(^)(__kindof VVBaseRequest *request))failureBlock;
{
    [self configNormalRequest:request parseBlock:nil success:successBlock failure:failureBlock];
}

+ (void)configNormalRequest:(__kindof VVBaseRequest *)request
                 parseBlock:(nullable id(^)(__kindof VVBaseRequest *request, NSRecursiveLock *lock))parseBlock
                    success:(void(^)(__kindof VVBaseRequest *request))successBlock
                    failure:(void(^)(__kindof VVBaseRequest *request))failureBlock
{
    NSAssert(request.requestType == VVRequestTypeDefault, @"make sure request.requestType == VVRequestTypeDefault be YES");
    if (request.parseBlock
        || request.groupSuccessBlock
        || request.groupFailureBlock) {
#if DEBUG
    NSAssert(!request.parseBlock, @"can't config the parseBlock");
    NSAssert(!request.groupSuccessBlock, @"can't config the successBlock");
    NSAssert(!request.groupFailureBlock, @"can't config the failureBlock");
#else
        return;
#endif
    }
    request.parseBlock = parseBlock;
    request.groupSuccessBlock = successBlock;
    request.groupFailureBlock = failureBlock;
}

+ (void)configUploadRequest:(__kindof VVBaseUploadRequest *)request
                   progress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
              formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
                    success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                    failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
    NSAssert(request.requestType == VVRequestTypeUpload, @"make sure request.requestType == VVRequestTypeUpload be YES");
    if (request.progressBlock
        || request.formDataBlock
        || request.groupSuccessBlock
        || request.groupFailureBlock) {
#if DEBUG
    NSAssert(!request.progressBlock, @"can't config the uploadProgressBlock");
    NSAssert(!request.formDataBlock, @"can't config the formDataBlock");
    NSAssert(!request.groupSuccessBlock, @"can't config the successBlock");
    NSAssert(!request.groupFailureBlock, @"can't config the failureBlock");
#else
        return;
#endif
    }
    request.progressBlock = uploadProgressBlock;
    request.formDataBlock = formDataBlock;
    request.groupSuccessBlock = successBlock;
    request.groupFailureBlock = failureBlock;
}

+ (void)configDownloadRequest:(__kindof VVBaseDownloadRequest *)request
                     progress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
                      success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
                      failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
    NSAssert(request.requestType == VVRequestTypeDownload, @"make sure request.requestType == VVRequestTypeDownload be YES");
    if (request.progressBlock
        || request.groupSuccessBlock
        || request.groupFailureBlock) {
#if DEBUG
    NSAssert(!request.progressBlock, @"can't config the downloadProgressBlock");
    NSAssert(!request.groupSuccessBlock, @"can't config the successBlock");
    NSAssert(!request.groupFailureBlock, @"can't config the failureBlock");
#else
        return;
#endif
    }
    request.progressBlock = downloadProgressBlock;
    request.groupSuccessBlock = successBlock;
    request.groupFailureBlock = failureBlock;
}

+ (void)configChildGroupRequest:(__kindof VVGroupRequest *)request
                        success:(void(^)(__kindof VVGroupRequest *request))successBlock
                        failure:(void(^)(__kindof VVGroupRequest *request))failureBlock
{
    NSAssert([request isKindOfClass:[VVGroupRequest class]], @"make sure [request isKindOfClass:[VVGroupRequest class]] be YES");
    if (request.groupSuccessBlock
        || request.groupFailureBlock) {
#if DEBUG
    NSAssert(!request.groupSuccessBlock, @"can't config the successBlock");
    NSAssert(!request.groupFailureBlock, @"can't config the failureBlock");
#else
        return;
#endif
    }
    request.groupSuccessBlock = ^(NSObject<VVRequestInGroupProtocol> * _Nonnull request) {
        if (successBlock) {
            successBlock((VVGroupRequest *)request);
        }
    };
    request.groupFailureBlock = ^(NSObject<VVRequestInGroupProtocol> * _Nonnull request) {
        if (failureBlock) {
            failureBlock((VVGroupRequest *)request);
        }
    };
    
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
    if (self.successBlock) {
        self.successBlock = nil;
    }
    if (self.failureBlock) {
        self.failureBlock = nil;
    }
    if (self.groupSuccessBlock) {
        self.groupSuccessBlock = nil;
    }
    if (self.groupFailureBlock) {
        self.groupFailureBlock = nil;
    }
}

@end


#pragma mark - - VVBatchRequest - -

@interface VVBatchRequest()

@property (nonatomic, strong, nullable) NSMutableArray<__kindof NSObject<VVRequestInGroupProtocol> *> *requireSuccessRequests;

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
    
    for (__kindof NSObject<VVRequestInGroupProtocol> *request in self.requestArray) {
        
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
            [baseRequest startWithCompletionParse:baseRequest.parseBlock success:^(__kindof VVBaseRequest * _Nonnull request) {
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

- (void)handleSuccessOfRequest:(__kindof NSObject<VVRequestInGroupProtocol> *)request
{
    self.finishedCount++;
    if (request.groupSuccessBlock) {
        request.groupSuccessBlock(request);
    }
    if (self.finishedCount == self.requestArray.count) {
        //the last request success, the batchRequest should call success block
        [self finishAllRequestsWithSuccessBlock];
    }
}

- (void)handleFailureOfRequest:(__kindof NSObject<VVRequestInGroupProtocol> *)request
{
    if (!self.failedRequests) {
        self.failedRequests = [NSMutableArray new];
    }
    if ([self.requireSuccessRequests containsObject:request]) {
        [self.failedRequests addObject:request];
        if (request.groupFailureBlock) {
            request.groupFailureBlock(request);
        }
        for (__kindof NSObject<VVRequestInGroupProtocol> *tmpRequest in [self.requestArray copy]) {
            [tmpRequest stop];
        }
        [self finishAllRequestsWithFailureBlock];
    } else {
        self.finishedCount++;
        [self.failedRequests addObject:request];
        if (request.groupFailureBlock) {
            request.groupFailureBlock(request);
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
        if (self.successBlock) {
            self.successBlock(self);
        }
    }];
    [self stop];
}

- (void)finishAllRequestsWithFailureBlock
{
    [self handleAccessoryWithBlock:^{
        if (self.failureBlock) {
            self.failureBlock(self);
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

- (void)configRequireSuccessRequests:(nullable NSArray <__kindof NSObject<VVRequestInGroupProtocol> *> *)requests
{
 
    for (__kindof NSObject<VVRequestInGroupProtocol> *request in requests) {
        if (![request conformsToProtocol:@protocol(VVRequestInGroupProtocol)]) {
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
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    [[VVNetworkAgent sharedAgent] addBatchRequest:self];
}

@end

#pragma mark - - VVChainRequest - -

@interface VVChainRequest()

@property (nonatomic, strong, nullable) __kindof NSObject<VVRequestInGroupProtocol> *lastRequest;
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
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    [[VVNetworkAgent sharedAgent] addChainRequest:self];
}

- (void)inAdvanceCompleteWithResult:(BOOL)isSuccess
{
    self.inAdvanceCompleted = YES;
    if (isSuccess) {
        [self handleAccessoryWithBlock:^{
            if (self.successBlock) {
                self.successBlock(self);
            }
        }];
    } else {
        [self handleAccessoryWithBlock:^{
            if (self.failureBlock) {
                self.failureBlock(self);
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
            [request startWithCompletionParse:request.parseBlock success:^(__kindof VVBaseRequest * _Nonnull request) {
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
    if (request.groupSuccessBlock) {
        request.groupSuccessBlock(request);
        if (self.inAdvanceCompleted) {
            return;
        }
    }
    if (self.canStartNextRequest) {
        [self startNextRequest];
    } else {
        [self handleAccessoryWithBlock:^{
            if (self.successBlock) {
                self.successBlock(self);
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
    if (request.groupFailureBlock) {
        request.groupFailureBlock(request);
        if (self.inAdvanceCompleted) {
            return;
        }
    }
    for (__kindof NSObject<VVRequestInGroupProtocol> *tmpRequest in [self.requestArray copy]) {
        [tmpRequest stop];
    }
    [self handleAccessoryWithBlock:^{
        if (self.failureBlock) {
            self.failureBlock(self);
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
