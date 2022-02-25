//
//  VVBaseDownloadRequest.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVBaseDownloadRequest :VVBaseRequest

/// the url of the download file resoure
@property (nonatomic, copy, readonly) NSString *absoluteString;
/// the filePath of the downloaded file
@property (nonatomic, copy, nullable, readonly) NSString *downloadedFilePath;
/// the temp filepath of the download file
@property (nonatomic, copy, nullable, readonly) NSString *tempFilePath;
/// the background policy of the downloadRequest
@property (nonatomic, assign) VVDownloadBackgroundPolicy backgroundPolicy;

+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)init NS_UNAVAILABLE;

+ (instancetype)initWithUrl:(nonnull NSString *)url;

/// downloadFile
/// @param downloadProgressBlock downloadProgressBlock
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)downloadWithProgress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
					 success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
					 failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

@end

NS_ASSUME_NONNULL_END
