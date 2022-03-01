//
//  VVMockURLProtocol.m
//  vv_rootlib_ios
//
//  Created by KOTU on 2019/11/15.
//

#import "VVMockURLProtocol.h"
//#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager.h>

#import "VVNetworkConfig.h"
#import "VVMockManager.h"
//#import "VVDataHelper.h"

#warning TODO 0225

@interface VVMockURLProtocol()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation VVMockURLProtocol
//
//static AFHTTPSessionManager *_vvSessionManager = nil;
//
//- (AFHTTPSessionManager *)sessionManager
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _vvSessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
//    });
//    return _vvSessionManager;
//}
//
//+ (BOOL)canInitWithRequest:(NSURLRequest *)request
//{
//    if (![VVNetworkConfig sharedConfig].isMock) {
//        return NO;
//    }
//    if ([self matchMethod:request]
//        && [self matchQueryKeyParams:request]
//        && [self matchesHeaders:request]
//        && [self matchBody:request]
//        ) {
//        return YES;
//    }
//    return NO;
//}
//
//+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
//
//    NSMutableURLRequest *newRequest = [request mutableCopy];
//    NSString *host = newRequest.URL.host;
//    NSString *url = newRequest.URL.absoluteString;
//    NSNumber *port = newRequest.URL.port;
//    NSString *scheme = newRequest.URL.scheme;
//    NSString *baseUrl = nil;
//    if (port) {
//        baseUrl = [NSString stringWithFormat:@"%@://%@:%@",scheme,host,port];
//    } else {
//        baseUrl = [NSString stringWithFormat:@"%@://%@",scheme,host];
//    }
//    url = [url stringByReplacingOccurrencesOfString:baseUrl withString:[VVNetworkConfig sharedConfig].mockBaseUrl];
//    NSURL *mockUrl = [NSURL URLWithString:url];
//    [newRequest setURL:mockUrl];
//    return newRequest;
//}
//
//- (void)startLoading
//{
//   NSURLSessionTask *dataTask = [[self sessionManager] dataTaskWithRequest:self.request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
//        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//        [self.client URLProtocolDidFinishLoading:self];
//        [self.client URLProtocol:self didFailWithError:error];
//
//    }];
//    [dataTask resume];
//}
//
//- (void)stopLoading
//{
//
//}
//
///**
// 判断方法是否相同
// */
//+ (BOOL)matchMethod:(NSURLRequest *)request
//{
//    NSString *httpMethod = [self getMockHttpMethodWithRequest:request];
//    if (httpMethod && [httpMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame) {
//        return YES;
//    }
//    return NO;
//}
//
///**
// 匹配query参数：关键参数是否相同
// */
//+ (BOOL)matchQueryKeyParams:(NSURLRequest *)request
//{
//    NSDictionary *params = [VVMockManager paramsWithURL:request.URL.absoluteString];
//    NSDictionary *mockQueryParams = [self getMockQueryParamsWithRequest:request];
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
///**
// 判断头关键参数是否相同
// */
//+ (BOOL)matchesHeaders:(NSURLRequest *)request
//{
//    NSDictionary *mockHeaders = [self getMockHeadersWithRequest:request];
//    NSDictionary *headers = request.allHTTPHeaderFields;
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
///**
// 判断body 只匹配关键参数
// */
//+ (BOOL)matchBody:(NSURLRequest *)request
//{
//    NSDictionary *mockParams = [self getMockBodyParamsWithRequest:request];
//    if (!mockParams) {
//        return YES;
//    }
//    NSData *reqBody = request.HTTPBody;
//    NSString *reqBodyString = [[NSString alloc] initWithData:reqBody encoding:NSUTF8StringEncoding];
//    NSDictionary *params = [VVMockManager convertDictionaryWithURLParams:reqBodyString];
//    for (NSDictionary *dic in mockParams) {
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
///// 根据request获取本地配置的需要mock的请求的请求方法
///// @param request request
//+ (NSString *)getMockHttpMethodWithRequest:(NSURLRequest *)request
//{
//    NSString *apiName = [self getAPINameWithRequest:request];
//    NSString *method = [request.HTTPMethod uppercaseString];
//    return [VVMockManager mockHttpMethodWithApiName:apiName method:method];
//}
//
///// 根据request按照制定规则解析获取APIName
///// @param request request
//+ (NSString *)getAPINameWithRequest:(NSURLRequest *)request
//{
//    NSString *path = [request.URL path];
//    NSArray *components = [path componentsSeparatedByString:@"/"];
//    NSString *language = [NSString stringWithFormat:@"/%@",[components vv_stringWithIndex:1]];
//    NSString *apiName = [path stringByReplacingOccurrencesOfString:language withString:@""];
//    return apiName;
//}
//
//+ (NSDictionary *)getMockQueryParamsWithRequest:(NSURLRequest *)request
//{
//    NSString *apiName = [self getAPINameWithRequest:request];
//    NSString *method = [request.HTTPMethod uppercaseString];
//    return [VVMockManager mockQueryParamsWithApiName:apiName method:method];
//}
//
//+ (NSDictionary *)getMockHeadersWithRequest:(NSURLRequest *)request
//{
//    NSString *apiName = [self getAPINameWithRequest:request];
//    NSString *method = [request.HTTPMethod uppercaseString];
//    return [VVMockManager mockHeadersWithApiName:apiName method:method];
//}
//
//+ (NSDictionary *)getMockBodyParamsWithRequest:(NSURLRequest *)request
//{
//    NSString *apiName = [self getAPINameWithRequest:request];
//    NSString *method = [request.HTTPMethod uppercaseString];
//    return [VVMockManager mockBodyParamsWithApiName:apiName method:method];
//}

@end
