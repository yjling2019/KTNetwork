//
//  KTBaseDownloadRequest.m
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBaseDownloadRequest.h"
#import "KTNetworkAgent.h"
#import "KTNetworkConfig.h"
#import "KTBaseRequest+Private.h"

@interface KTBaseDownloadRequest()

/// the url of the download file resoure
@property (nonatomic, copy, readwrite) NSString *absoluteString;

/// the filePath of the downloaded file
@property (nonatomic, copy, readwrite) NSString *downloadedFilePath;

@property (nonatomic, copy, readwrite) NSString *tempFilePath;

@end

@implementation KTBaseDownloadRequest

+ (instancetype)initWithUrl:(nonnull NSString *)url
{
	KTBaseDownloadRequest *request = [[self alloc] init];
	if (request) {
#if DEBUG
		NSAssert(url, @"url can't be nil");
#endif
		request.absoluteString = url;
	}
	return request;
}

- (NSString *)buildCustomRequestUrl
{
	return self.absoluteString;
}

- (void)downloadWithProgress:(nullable void(^)(NSProgress *downloadProgress))downloadProgressBlock
					 success:(nullable void(^)(__kindof KTBaseRequest *request))successBlock
					 failure:(nullable void(^)(__kindof KTBaseRequest *request))failureBlock
{
	self.successBlock = successBlock;
	self.failureBlock = failureBlock;
	self.progressBlock = downloadProgressBlock;
	[[KTNetworkAgent sharedAgent] startRequest:self];
}

#pragma mark - - getter - -
- (nullable NSString *)downloadedFilePath
{
#warning TODO 0225
	return nil;
	
//    if (!_downloadedFilePath) {
//        if (!vv_safeStr(self.absoluteString)) {
//            return nil;
//        }
//        NSString *downloadFolderPath = [KTNetworkConfig sharedConfig].downloadFolderPath;
//        NSString *fileName = [VVEncryptHelper MD5String:self.absoluteString];
//        fileName = [fileName stringByAppendingPathExtension:[self.absoluteString pathExtension]]?:@"";
//        _downloadedFilePath = [NSString pathWithComponents:@[downloadFolderPath, fileName]];
//    }
//    return _downloadedFilePath;
}

- (nullable NSString *)tempFilePath
{
#warning TODO 0225
	return nil;
	
//    if (!_tempFilePath) {
//        if (!vv_safeStr(self.absoluteString)) {
//            return nil;
//        }
//        NSString *str = [NSString stringWithFormat:@"backgroundPolicy_%@_%@",@(self.backgroundPolicy),self.absoluteString];
//        NSString *md5URLStr = [VVEncryptHelper MD5String:str];
//        _tempFilePath = [[KTNetworkConfig sharedConfig].incompleteCacheFolder stringByAppendingPathComponent:md5URLStr];
//    }
//    return _tempFilePath;
}

@end
