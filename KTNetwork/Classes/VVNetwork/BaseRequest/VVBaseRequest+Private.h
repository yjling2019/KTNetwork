//
//  VVBaseRequest+Private.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVBaseRequest()

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;

@property (nonatomic, strong, readwrite, nullable) id responseObject;

@property (nonatomic, strong, readwrite, nullable) NSDictionary *responseJSONObject;

@property (atomic, strong, readwrite, nullable) NSError *error;

@property (nonatomic, assign, readwrite) BOOL isDataFromCache;
/// the request success block
@property (nonatomic, copy, nullable) void(^successBlock)(__kindof VVBaseRequest *request);
/// the request failure block
@property (nonatomic, copy, nullable) void(^failureBlock)(__kindof VVBaseRequest *request);
/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);
/// when upload data cofig the formData
@property (nonatomic, copy, nullable) void (^formDataBlock)(id<AFMultipartFormData> formData);

@property (nonatomic, strong, readwrite, nullable) id parsedData;

@end

NS_ASSUME_NONNULL_END
