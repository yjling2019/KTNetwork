//
//  VVNetworkResponse.h
//  VVCommonKit
//
//  Created by 陈栋 on 2019/11/28.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VVNetworkResponse : NSObject

@property (nonatomic, assign, readonly) NSInteger code;

@property (nonatomic, copy, readonly, nullable) NSDictionary *data;

@property (nonatomic, copy, readonly) NSString * msg;

+ (VVNetworkResponse *)responseWithCode:(NSInteger)code dataDic:(nullable NSDictionary *)dic msg:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END
