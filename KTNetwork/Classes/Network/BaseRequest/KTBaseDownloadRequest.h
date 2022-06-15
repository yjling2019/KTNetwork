//
//  KTBaseDownloadRequest.h
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface KTBaseDownloadRequest :KTBaseRequest

/// the url of the download file resoure
@property (nonatomic, copy, readonly) NSString *absoluteString;
/// the filePath of the downloaded file
@property (nonatomic, copy, nullable, readonly) NSString *downloadedFilePath;
/// the temp filepath of the download file
@property (nonatomic, copy, nullable, readonly) NSString *tempFilePath;
/// the background policy of the downloadRequest
@property (nonatomic, assign) KTDownloadBackgroundPolicy backgroundPolicy;

/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);

+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)init NS_UNAVAILABLE;

+ (instancetype)initWithUrl:(nonnull NSString *)url;

/// downloadFile
/// @param downloadProgressBlock downloadProgressBlock
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)downloadWithProgress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
					 success:(nullable void(^)(__kindof KTBaseRequest *request))successBlock
					 failure:(nullable void(^)(__kindof KTBaseRequest *request))failureBlock;

@end

NS_ASSUME_NONNULL_END
