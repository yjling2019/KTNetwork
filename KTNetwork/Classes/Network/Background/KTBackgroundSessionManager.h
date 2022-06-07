//
//  KTBackgroundSessionManager.h
//  KOTU
//
//  Created by KOTU on 2020/12/12.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@class KTBaseDownloadRequest;
@class AFHTTPRequestSerializer;

@interface KTBackgroundSessionManager : NSObject
/// the background url task identifer
@property (nonatomic, copy, readonly, nonnull) NSString *backgroundTaskIdentifier;

@property (nonatomic, copy, nullable) void (^completionHandler)(void);

- (NSURLSessionTask *)dataTaskWithDownloadRequest:(__kindof KTBaseDownloadRequest *)request
                                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                        URLString:(NSString *)URLString
                                       parameters:(id)parameters
                                         progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                completionHandler:(nullable void (^)(NSURLResponse *response, NSError * _Nullable error))completionHandler
                                            error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
