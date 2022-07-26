//
//  KTBackgroundSessionManager.m
//  KOTU
//
//  Created by KOTU on 2020/12/12.
//

#import "KTBackgroundSessionManager.h"
#import "KTNetworkTaskDelegate.h"
#import "KTBaseRequest+Private.h"

static NSString * const kKTNetwork_background_task_identifier = @"kKTNetwork_background_task_identifier";

@interface KTBackgroundSessionManager()<NSURLSessionDataDelegate,NSURLSessionDownloadDelegate>

/// the background url task identifer
@property (nonatomic, copy, readwrite, nonnull) NSString *backgroundTaskIdentifier;
/// the background urlSessionDataTask
@property (nonatomic, copy, readwrite, nonnull) NSURLSession *backgroundURLSession;
///the key value of the taskIdentier and the real delegate of NSURLSessionDelegate
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSNumber *,id> *taskIdentifierAndDelegateDic;
@property (nonatomic, strong, nonnull) NSLock *lock;

@end

@implementation KTBackgroundSessionManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _backgroundTaskIdentifier = [NSString stringWithFormat:@"%@_networkAgent.backgroundSession",[NSBundle mainBundle].bundleIdentifier];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_backgroundTaskIdentifier];
        configuration.networkServiceType = NSURLNetworkServiceTypeBackground;
        configuration.allowsCellularAccess = YES;
        _backgroundURLSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        _taskIdentifierAndDelegateDic = [NSMutableDictionary new];
        _lock = [NSLock new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - - NSURLSessionDelegate - -
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    [session getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        for (NSURLSessionTask *task in tasks) {
            id delegate = [self delegateForkTaskIdentifier:task.taskIdentifier];
            if (delegate
                && [delegate respondsToSelector:@selector(URLSession:task:didBecomeInvalidWithError:)]) {
                [delegate URLSession:session task:task didBecomeInvalidWithError:error];
            }
        }
    }];
}

#if !TARGET_OS_OSX
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (self.completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler();
        });
    }
}
#endif

#pragma mark - - NSURLSessionTaskDelegate - -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                           didCompleteWithError:(nullable NSError *)error
{
    id delegate = [self delegateForkTaskIdentifier:task.taskIdentifier];
    if (delegate
        && [delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [delegate URLSession:session task:task didCompleteWithError:error];
    }
}

#pragma mark - - NSURLSessionDataDelegate - -
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSURLResponse *)response
                                  completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    id delegate = [self delegateForkTaskIdentifier:dataTask.taskIdentifier];
    if (delegate
        && [delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)] ) {
        [delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(NSURLSessionResponseAllow);
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                     didReceiveData:(NSData *)data
{
    id delegate = [self delegateForkTaskIdentifier:dataTask.taskIdentifier];
    if (delegate
        && [delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [delegate URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location
{
    id delegate = [self delegateForkTaskIdentifier:downloadTask.taskIdentifier];
    if (delegate
        && [delegate respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)]) {
        [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    id delegate = [self delegateForkTaskIdentifier:downloadTask.taskIdentifier];
    if (delegate
        && [delegate respondsToSelector:@selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [delegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                      didResumeAtOffset:(int64_t)fileOffset
                                     expectedTotalBytes:(int64_t)expectedTotalBytes
{
    id delegate = [self delegateForkTaskIdentifier:downloadTask.taskIdentifier];
    if (delegate
        && [delegate respondsToSelector:@selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:)]) {
        [delegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
    }
}

- (NSURLSessionTask *)dataTaskWithDownloadRequest:(__kindof KTBaseDownloadRequest *)request
                                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                        URLString:(NSString *)URLString
                                       parameters:(id)parameters
                                         progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                completionHandler:(nullable void (^)(NSURLResponse *response, NSError * _Nullable error))completionHandler
                                            error:(NSError * _Nullable __autoreleasing *)error
{
    // add parameters to URL;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    NSString *downloadedFilePath = request.downloadedFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadedFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadedFilePath error:nil];
    }

    NSString *tempFilePath = request.tempFilePath;
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:tempFilePath];
    NSData *resumeData = [NSData dataWithContentsOfFile:tempFilePath];

    BOOL canBeResumed = resumeDataFileExists && resumeData;
    NSURLSessionTask *sessionTask = nil;
    [self.lock lock];
    if (request.backgroundPolicy == KTDownloadBackgroundRequire) {
        if (canBeResumed) {
            sessionTask = [self.backgroundURLSession downloadTaskWithResumeData:resumeData];
        } else {
            sessionTask = [self.backgroundURLSession downloadTaskWithRequest:urlRequest];
        }
        request.requestTask = sessionTask;
        KTNetworkBackgroundDownloadTaskDelegate *taskDelegate = [[KTNetworkBackgroundDownloadTaskDelegate alloc] initWithRequest:request];
        taskDelegate.downloadProgressBlock = downloadProgressBlock;
        taskDelegate.completionHandler = completionHandler;
        self.taskIdentifierAndDelegateDic[@(sessionTask.taskIdentifier)] = taskDelegate;
    } else {
        if (canBeResumed) {
            NSString *rangeStr = [NSString stringWithFormat:@"bytes=%zd-", resumeData.length];
            [urlRequest setValue:rangeStr forHTTPHeaderField:@"Range"];
            sessionTask = [self.backgroundURLSession dataTaskWithRequest:urlRequest];
        } else {
            sessionTask = [self.backgroundURLSession dataTaskWithRequest:urlRequest];
        }
        request.requestTask = sessionTask;
        KTNetworkDownloadTaskDelegate *taskDelegate = [[KTNetworkDownloadTaskDelegate alloc] initWithRequest:request];
        taskDelegate.downloadProgressBlock = downloadProgressBlock;
        taskDelegate.completionHandler = completionHandler;
        self.taskIdentifierAndDelegateDic[@(sessionTask.taskIdentifier)] = taskDelegate;
    }
    [self.lock unlock];
    return sessionTask;
}

- (BOOL)needHandleBackgroundTask
{
    [self.lock lock];
    NSArray <__kindof KTNetworkBaseDownloadTaskDelegate *>*delegates = [self.taskIdentifierAndDelegateDic allValues];
    [self.lock unlock];
    for (__kindof KTNetworkBaseDownloadTaskDelegate *delegate in delegates) {
        if (delegate.request.backgroundPolicy == KTDownloadBackgroundDefault) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - - private - -

- (void)applicationDidEnterBackground:(NSNotification *)notif
{
    if ([self needHandleBackgroundTask]) {
     __block UIBackgroundTaskIdentifier background_identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:kKTNetwork_background_task_identifier expirationHandler:^{
         [[UIApplication sharedApplication] endBackgroundTask:background_identifier];
         background_identifier = UIBackgroundTaskInvalid;
        }];
    }
}

- (id)delegateForkTaskIdentifier:(NSUInteger)taskIdentifier
{
    [self.lock lock];
    id delegate = self.taskIdentifierAndDelegateDic[@(taskIdentifier)];
    [self.lock unlock];
    return delegate;
}

@end
