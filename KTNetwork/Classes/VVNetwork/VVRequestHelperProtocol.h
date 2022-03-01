//
//  VVRequestHelperProtocol.h
//  KTNetwork
//
//  Created by 凌永剑 on 2022/2/28.
//

#import <Foundation/Foundation.h>
#import "VVBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VVRequestHelperProtocol <NSObject>

@optional

#pragma mark - request handle
/// before all requests, you can use this func do something
/// this func can only excute once in app lifetime
- (void)beforeAllRequests;

/// before each request,you can use this func do something
/// this func invoked after - (void)beforeAllRequests
/// @param request request
- (void)beforeEachRequest:(__kindof VVBaseRequest *)request;

/// after each request,you can use this func do something
/// @param request request
- (void)afterEachRequest:(__kindof VVBaseRequest *)request;

/// do some action before the request success block
/// @param request request
- (void)preHandleSuccessRequest:(__kindof VVBaseRequest *)request;

/// do some action before the request failure block
/// @param request request
- (void)preHandleFailureRequest:(__kindof VVBaseRequest *)request;

#pragma mark - url handle
/// get the baseUrl of the request
/// @param request request
- (NSString *)baseUrlOfRequest:(__kindof VVBaseRequest *)request;

/// this is the url append or filter func
/// @param originUrl originUrl
/// @param request request
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(__kindof VVBaseRequest *)request;

/// use this func to signature the request
/// @param request the request
- (void)signatureRequest:(__kindof VVBaseRequest *)request;

#pragma mark - cache
/// load Cache data of the request
/// @param request request
- (id)loadCacheDataOfRequest:(__kindof VVBaseRequest *)request error:(NSError **)error;

/// save the request's reponse to cache
/// @param request request
- (void)saveResponseToCacheOfRequest:(__kindof VVBaseRequest *)request;

/// clear the the request's response from cache
/// @param request request
- (void)clearResponseFromCacheOfRequest:(__kindof VVBaseRequest *)request;

/// according one api response to judge the request need to cache or not,and cacheTime
/// @param request request
- (void)judgeToChangeCachePolicy:(__kindof VVBaseRequest *)request;

@end

NS_ASSUME_NONNULL_END
