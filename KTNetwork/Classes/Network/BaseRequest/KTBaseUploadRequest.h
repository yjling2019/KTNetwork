//
//  KTBaseUploadRequest.h
//  KTNetwork
//
//  Created by KOTU on 2022/2/25.
//

#import "KTBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface KTBaseUploadRequest : KTBaseRequest

/// the download/upload request progress block
@property (nonatomic, copy, nullable) void(^progressBlock)(NSProgress *progress);
/// when upload data cofig the formData
@property (nonatomic, copy, nullable) void (^formDataBlock)(id<AFMultipartFormData> formData);

/// upload data
/// @param uploadProgressBlock uploadProgressBlock
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)uploadWithProgress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
			 formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
				   success:(nullable void(^)(__kindof KTBaseRequest *request))successBlock
				   failure:(nullable void(^)(__kindof KTBaseRequest *request))failureBlock;

@end

NS_ASSUME_NONNULL_END
