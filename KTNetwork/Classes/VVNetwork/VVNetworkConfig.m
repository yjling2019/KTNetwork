//
//  VVNetworkConfig.m
//  VVRootLib
//
//  Created by JackLee on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import "VVNetworkConfig.h"

@interface VVNetworkConfig()

@property (nonatomic, strong, readwrite, nullable) id<VVRequestHelperProtocol> requestHelper;

@property (nonatomic, copy, readwrite) NSString *incompleteCacheFolder;

@end

@implementation VVNetworkConfig

+ (instancetype)sharedConfig
{
    static VVNetworkConfig *_networkConfig = nil;
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

- (void)configRequestHelper:(id<VVRequestHelperProtocol>)requestHelper
{
    self.requestHelper = requestHelper;
}

#pragma mark - - getter - -
- (NSString *)incompleteCacheFolder
{
    if (!_incompleteCacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        NSString *cacheFolder = [cacheDir stringByAppendingPathComponent:@"VVIncomplete"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
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
       NSString *downloadFolder = [documentPath stringByAppendingPathComponent:@"VVNetworking_download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        if(![fileManager createDirectoryAtPath:downloadFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
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
