//
//  VVMockManager.m
//  KOTU
//
//  Created by KOTU on 2019/11/15.
//

#import "VVMockManager.h"
#import "KTBaseRequest.h"

#warning TODO 0225

@implementation VVMockManager

//static NSDictionary *mockApiConfig = nil;
//
//+ (void)initMockConfig:(NSDictionary *)config
//{
//    mockApiConfig = config;
//}
//
//+ (BOOL)matchRequest:(__kindof KTBaseRequest *)request
//                 url:(NSString *)url
//{
//    return [self matchMethod:request]
//    && [self matchQueryKeyParams:request url:url]
//    && [self matchesHeaders:request]
//    && [self matchBody:request];
//}
//
//+ (BOOL)matchMethod:(__kindof KTBaseRequest *)request
//{
//    NSString *httpMethod1 = [self httpMethodWithRequest:request];
//    NSArray *array = [request.requestUrl componentsSeparatedByString:@"?"];
//    NSString *apiName = array.firstObject;
//    NSString *httpMethod2 = [self mockHttpMethodWithApiName:apiName method:httpMethod1];
//    if (!vv_isEmptyStr(httpMethod2)) {
//        return YES;
//    }
//    return NO;
//}
//
//+ (BOOL)matchQueryKeyParams:(__kindof KTBaseRequest *)request
//                        url:(NSString *)url
//{
//    NSDictionary *params = [self paramsWithURL:url];
//    NSArray *array = [request.requestUrl componentsSeparatedByString:@"?"];
//    NSString *apiName = array.firstObject;
//    NSString *httpMethod = [self httpMethodWithRequest:request];
//    NSDictionary *mockQueryParams = [self mockQueryParamsWithApiName:apiName method:httpMethod];
//    for (NSDictionary *dic in mockQueryParams) {
//        BOOL status = NO;
//        for (NSDictionary *tmpDic in params) {
//            if ([tmpDic isEqualToDictionary:dic]) {
//                status = YES;
//                break;
//            }
//        }
//        if (!status) {
//            return NO;
//        }
//    }
//    return YES;
//}
//
//+ (BOOL)matchesHeaders:(__kindof KTBaseRequest *)request
//{
//    NSArray *array = [request.requestUrl componentsSeparatedByString:@"?"];
//    NSString *apiName = array.firstObject;
//    NSString *httpMethod = [self httpMethodWithRequest:request];
//    NSDictionary *headers = request.requestHeaders;
//    NSDictionary *mockHeaders = [self mockHeadersWithApiName:apiName method:httpMethod];
//    for (NSDictionary *dic in mockHeaders) {
//        BOOL status = NO;
//        for (NSDictionary *tmpDic in headers) {
//            if ([tmpDic isEqualToDictionary:dic]) {
//                status = YES;
//                break;
//            }
//        }
//        if (!status) {
//            return NO;
//        }
//    }
//    return YES;
//}
//
//+ (BOOL)matchBody:(__kindof KTBaseRequest *)request
//{
//    NSArray *array = [request.requestUrl componentsSeparatedByString:@"?"];
//    NSString *apiName = array.firstObject;
//    NSString *httpMethod = [self httpMethodWithRequest:request];
//    NSDictionary *bodyParams = request.requestArgument;
//    NSDictionary *mockBodyParams = [self mockBodyParamsWithApiName:apiName method:httpMethod];
//    for (NSDictionary *dic in mockBodyParams) {
//        BOOL status = NO;
//        for (NSDictionary *tmpDic in bodyParams) {
//            if ([tmpDic isEqualToDictionary:dic]) {
//                status = YES;
//                break;
//            }
//        }
//        if (!status) {
//            return NO;
//        }
//    }
//    return YES;
//}
//
//+ (NSString *)mockHttpMethodWithApiName:(NSString *)apiName
//                                 method:(NSString *)method
//{
//    NSString *key = [NSString stringWithFormat:@"%@,%@",method,apiName];
//    NSDictionary *dic = [mockApiConfig vv_dictionaryForKey:key];
//    if (dic) {
//        return method;
//    }
//    return nil;
//}
//
//+ (NSDictionary *)mockQueryParamsWithApiName:(NSString *)apiName
//                                      method:(NSString *)method
//{
//    NSString *key = [NSString stringWithFormat:@"%@,%@",method,apiName];
//    NSDictionary *dic = [mockApiConfig vv_dictionaryForKey:key];
//    NSDictionary *queryParams = [dic vv_dictionaryForKey:@"queryParams"];
//    return queryParams;
//}
//
//+ (NSDictionary *)mockHeadersWithApiName:(NSString *)apiName
//                                  method:(NSString *)method
//{
//    NSString *key = [NSString stringWithFormat:@"%@,%@",method,apiName];
//    NSDictionary *dic = [mockApiConfig vv_dictionaryForKey:key];
//    NSDictionary *headers = [dic vv_dictionaryForKey:@"headers"];
//    return headers;
//}
//
//+ (NSDictionary *)mockBodyParamsWithApiName:(NSString *)apiName
//                                     method:(NSString *)method
//{
//    NSString *key = [NSString stringWithFormat:@"%@,%@",method,apiName];
//    NSDictionary *dic = [mockApiConfig vv_dictionaryForKey:key];
//    NSDictionary *bodyParams = [dic vv_dictionaryForKey:@"bodyParams"];
//    return bodyParams;
//}
//
//+ (NSString *)httpMethodWithRequest:(__kindof KTBaseRequest *)request
//{
//    switch (request.requestMethod) {
//        case KTRequestMethodGET:
//            return @"GET";
//            break;
//
//        case KTRequestMethodPOST:
//            return @"POST";
//            break;
//
//        case KTRequestMethodHEAD:
//             return @"HEAD";
//             break;
//
//        case KTRequestMethodPUT:
//             return @"PUT";
//             break;
//
//        case KTRequestMethodDELETE:
//             return @"DELETE";
//             break;
//
//        case KTRequestMethodPATCH:
//             return @"PATCH";
//             break;
//
//        default:
//            break;
//    }
//    return nil;
//}
//
//#pragma mark - private
//
///**
// url的参数 返回key:value
// */
//+ (NSDictionary *)paramsWithURL:(NSString *)url
//{
//    if (![url isKindOfClass:[NSString class]] || url.length == 0) {
//        return nil;
//    }
//
//    NSArray *urls = [url componentsSeparatedByString:@"?"];
//    NSString *paramsURL = nil;
//    if (urls.count == 2) {
//        paramsURL = urls[1];
//    }
//    return [self convertDictionaryWithURLParams:paramsURL];
//}
//
///**
// 根据参数字符串转化为字典 name=1&id=2 ==> name:1,id:2
// */
//+ (NSDictionary *)convertDictionaryWithURLParams:(NSString *)paramsURL
//{
//    NSMutableDictionary *params = [NSMutableDictionary dictionary];
//    for (NSString *item in [paramsURL componentsSeparatedByString:@"&"]) {
//        NSArray *temp = [item componentsSeparatedByString:@"="];
//        if (temp.count == 2) {
//            [params setObject:temp[1] forKey:temp[0]];
//        }
//    }
//
//    return params;
//}

@end
