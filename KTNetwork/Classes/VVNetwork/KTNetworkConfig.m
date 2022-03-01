//
//  KTNetworkConfig.m
//  KOTU
//
//  Created by KOTU on 2019/9/10.
//

#import "KTNetworkConfig.h"

@interface KTNetworkConfig()

@property (nonatomic, strong, readwrite, nullable) id<KTRequestHelperProtocol> requestHelper;

@property (nonatomic, copy, readwrite) NSString *incompleteCacheFolder;

@end

@implementation KTNetworkConfig

+ (instancetype)sharedConfig
{
    static KTNetworkConfig *_networkConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _networkConfig = [[self alloc] init];
    });
    return _networkConfig;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _mockModelTimeoutInterval = 300;
    }
    return self;
}

- (void)configRequestHelper:(id<KTRequestHelperProtocol>)requestHelper
{
    self.requestHelper = requestHelper;
}

#pragma mark - - getter - -
- (NSString *)incompleteCacheFolder
{
    if (!_incompleteCacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        NSString *cacheFolder = [cacheDir stringByAppendingPathComponent:@"com.kotu.networking.incomplete"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
    #if DEBUG
            NSLog(@"Failed to create cache directory at %@", cacheFolder);
    #endif
            return nil;
        }
        _incompleteCacheFolder = cacheFolder;
    }
    return _incompleteCacheFolder;
}

- (NSString *)downloadFolderPath
{
    if (!_downloadFolderPath) {
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
       NSString *downloadFolder = [documentPath stringByAppendingPathComponent:@"com.kotu.networking.download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:downloadFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
    #if DEBUG
            NSLog(@"Failed to create download directory at %@", downloadFolder);
    #endif
            return @"";
        }
        _downloadFolderPath = downloadFolder;
    }
    return _downloadFolderPath;
}

@end
