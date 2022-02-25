//
//  VVNetworkResponse.m
//  VVCommonKit
//
//  Created by 陈栋 on 2019/11/28.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import "VVNetworkResponse.h"

@interface VVNetworkResponse()

@property (nonatomic, assign, readwrite) NSInteger code;

@property (nonatomic, copy, nullable) NSDictionary *data;

@property (nonatomic, copy) NSString * msg;

@end

@implementation VVNetworkResponse

+ (VVNetworkResponse *)responseWithCode:(NSInteger)code dataDic:(nullable NSDictionary *)dic msg:(NSString *)msg
{
    VVNetworkResponse *response = [[VVNetworkResponse alloc] init];
    response.code = code;
    response.data = dic;
    response.msg = msg;
    return response;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{\n  code: %ld\n  msg:%@\n  data:%@ \n}", (long)self.code, self.msg , self.data];
}

@end
