//
//  VVBaseUploadRequest.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/25.
//

#import "VVBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVBaseUploadRequest : VVBaseRequest

/// upload data
/// @param uploadProgressBlock uploadProgressBlock
/// @param successBlock successBlock
/// @param failureBlock failureBlock
- (void)uploadWithProgress:(nullable void(^)(NSProgress *progress))uploadProgressBlock
			 formDataBlock:(nullable void(^)(id <AFMultipartFormData> formData))formDataBlock
				   success:(nullable void(^)(__kindof VVBaseRequest *request))successBlock
				   failure:(nullable void(^)(__kindof VVBaseRequest *request))failureBlock;

@end

NS_ASSUME_NONNULL_END
