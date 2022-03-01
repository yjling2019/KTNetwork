//
//  KTNetworkTaskDelegate.h
//  KOTU
//
//  Created by KOTU on 2020/12/4.
//

#import <Foundation/Foundation.h>
#import "KTBaseDownloadRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface KTNetworkBaseDownloadTaskDelegate : NSObject

@property (nonatomic, weak, readonly) __kindof KTBaseDownloadRequest *request;
@property (nonatomic, copy) void(^downloadProgressBlock)(NSProgress *downloadProgress);
@property (nonatomic, copy) void(^completionHandler)(NSURLResponse *response, NSError *error);

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequest:(__kindof KTBaseDownloadRequest *)request;

- (void)URLSession:(NSURLSession *)session task:(__kindof NSURLSessionTask *)task
                      didBecomeInvalidWithError:(NSError *)error;

@end

@interface KTNetworkDownloadTaskDelegate : KTNetworkBaseDownloadTaskDelegate < NSURLSessionDataDelegate>

@end

@interface KTNetworkBackgroundDownloadTaskDelegate : KTNetworkBaseDownloadTaskDelegate <NSURLSessionDownloadDelegate>

@end

NS_ASSUME_NONNULL_END
