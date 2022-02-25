//
//  VVBaseDownloadRequest.m
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseDownloadRequest.h"
#import "VVNetworkAgent.h"
#import "VVNetworkConfig.h"
#import "VVBaseRequest+Private.h"

@interface VVBaseDownloadRequest()

/// the url of the download file resoure
@property (nonatomic, copy, readwrite) NSString *absoluteString;

/// the filePath of the downloaded file
@property (nonatomic, copy, readwrite) NSString *downloadedFilePath;

@property (nonatomic, copy, readwrite) NSString *tempFilePath;

@end

@implementation VVBaseDownloadRequest

+ (instancetype)initWithUrl:(nonnull NSString *)url
{
	VVBaseDownloadRequest *request = [[self alloc] init];
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
					 success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
					 failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock
{
	self.successBlock = successBlock;
	self.failureBlock = failureBlock;
	self.progressBlock = downloadProgressBlock;
	[[VVNetworkAgent sharedAgent] addRequest:self];
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
//        NSString *downloadFolderPath = [VVNetworkConfig sharedConfig].downloadFolderPath;
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
//        _tempFilePath = [[VVNetworkConfig sharedConfig].incompleteCacheFolder stringByAppendingPathComponent:md5URLStr];
//    }
//    return _tempFilePath;
}

@end
