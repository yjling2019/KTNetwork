//
//  KTNetworkResponse.h
//  KTCommonKit
//
//  Created by KOTU on 2019/11/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KTNetworkResponse : NSObject

@property (nonatomic, assign, readonly) NSInteger code;

@property (nonatomic, copy, readonly, nullable) NSDictionary *data;

@property (nonatomic, copy, readonly) NSString * msg;

+ (KTNetworkResponse *)responseWithCode:(NSInteger)code dataDic:(nullable NSDictionary *)dic msg:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END
