//
//  VVNetworkAgent.h
//  VVRootLib
//
//  Created by JackLee on 2019/9/10.
//  Copyright © 2019 com.lebby.www. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class VVBaseRequest;
@class VVBatchRequest;
@class VVChainRequest;

@interface VVNetworkAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedAgent;

- (void)addRequest:(__kindof VVBaseRequest *)request;

- (void)cancelRequest:(__kindof VVBaseRequest *)request;

- (void)cancelAllRequests;

- (void)addBatchRequest:(__kindof VVBatchRequest *)request;

- (void)removeBatchRequest:(__kindof VVBatchRequest *)request;

- (void)addChainRequest:(__kindof VVChainRequest *)request;

- (void)removeChainRequest:(__kindof VVChainRequest *)request;

/// add the priority request,all the request will start until the prority request is finished
/// @param request the request can ba a VVBaseRequest/VVBatchRequest/VVChainRequest
- (void)addPriorityFirstRequest:(id)request;

/// all the requests
- (NSArray <__kindof VVBaseRequest *>*)allRequests;

/// app后台完成下载任务的时候出发回调
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
                                                                   completionHandler:(void (^)(void))completionHandler;


@end

NS_ASSUME_NONNULL_END
