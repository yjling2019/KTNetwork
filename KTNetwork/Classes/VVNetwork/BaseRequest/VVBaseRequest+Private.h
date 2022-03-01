//
//  VVBaseRequest+Private.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseRequest.h"
#import "VVBaseUploadRequest.h"
#import "VVBaseDownloadRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVBaseRequest()

@property (nonatomic, strong, nullable) NSURLSessionTask *requestTask;

@property (nonatomic, assign) BOOL isDataFromCache;

@property (nonatomic, strong, nullable) id responseObject;
@property (nonatomic, strong, nullable) NSDictionary *responseJSONObject;
@property (nonatomic, strong, nullable) id parsedData;

@property (atomic, strong, nullable) NSError *error;

/// the request success block
@property (nonatomic, copy, nullable) void(^successBlock)(__kindof VVBaseRequest *request);
/// the request failure block
@property (nonatomic, copy, nullable) void(^failureBlock)(__kindof VVBaseRequest *request);

@end


@interface VVBaseUploadRequest ()

/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);
/// when upload data cofig the formData
@property (nonatomic, copy, nullable) void (^formDataBlock)(id<AFMultipartFormData> formData);

@end


@interface VVBaseDownloadRequest ()

/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);

@end

NS_ASSUME_NONNULL_END
