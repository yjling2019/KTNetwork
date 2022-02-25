//
//  VVNetworkTaskDelegate.h
//  vv_rootlib_ios
//
//  Created by JackLee on 2020/12/4.
//

#import <Foundation/Foundation.h>
#import "VVBaseDownloadRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVNetworkBaseDownloadTaskDelegate : NSObject

@property (nonatomic, weak, readonly) __kindof VVBaseDownloadRequest *request;
@property (nonatomic, copy) void(^downloadProgressBlock)(NSProgress *downloadProgress);
@property (nonatomic, copy) void(^completionHandler)(NSURLResponse *response, NSError *error);

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequest:(__kindof VVBaseDownloadRequest *)request;

- (void)URLSession:(NSURLSession *)session task:(__kindof NSURLSessionTask *)task
                      didBecomeInvalidWithError:(NSError *)error;

@end

@interface VVNetworkDownloadTaskDelegate : VVNetworkBaseDownloadTaskDelegate < NSURLSessionDataDelegate>

@end

@interface VVNetworkBackgroundDownloadTaskDelegate : VVNetworkBaseDownloadTaskDelegate <NSURLSessionDownloadDelegate>

@end

NS_ASSUME_NONNULL_END
