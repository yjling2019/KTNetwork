//
//  KTNetworkAgent.h
//  KOTU
//
//  Created by KOTU on 2019/9/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class KTBaseRequest;
@class KTBatchRequest;
@class KTChainRequest;

@interface KTNetworkAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedAgent;

/// add the priority request,all the request will start until the prority request is finished
/// @param request the request can ba a KTBaseRequest/KTBatchRequest/KTChainRequest
- (void)addPriorityFirstRequest:(id)request;

- (void)cancelAllRequests;

- (void)startRequest:(id)request;
- (void)cancelRequest:(id)request;

/// all the requests
- (NSArray <__kindof KTBaseRequest *>*)allRequests;

/// app后台完成下载任务的时候出发回调
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
                                                                   completionHandler:(void (^)(void))completionHandler;


+ (NSString *)curlOfRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
