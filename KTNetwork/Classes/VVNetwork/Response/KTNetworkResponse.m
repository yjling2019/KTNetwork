//
//  KTNetworkResponse.m
//  KTCommonKit
//
//  Created by KOTU on 2019/11/28.
//

#import "KTNetworkResponse.h"

@interface KTNetworkResponse()

@property (nonatomic, assign, readwrite) NSInteger code;

@property (nonatomic, copy, nullable) NSDictionary *data;

@property (nonatomic, copy) NSString * msg;

@end

@implementation KTNetworkResponse

+ (KTNetworkResponse *)responseWithCode:(NSInteger)code dataDic:(nullable NSDictionary *)dic msg:(NSString *)msg
{
    KTNetworkResponse *response = [[KTNetworkResponse alloc] init];
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
