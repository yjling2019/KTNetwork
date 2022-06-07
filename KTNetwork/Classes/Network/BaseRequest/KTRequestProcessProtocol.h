//
//  KTRequestProcessProtocol.h
//  KOTU
//
//  Created by KOTU on 2022/3/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KTRequestProcessProtocol;

typedef void(^KTRequestProcessBlock)(id <KTRequestProcessProtocol> request);

@protocol KTRequestProcessProtocol <NSObject>

/// start the request. not realy start, maybe in queue
- (void)start;
- (void)startWithCompletionSuccess:(nullable KTRequestProcessBlock)successBlock
						   failure:(nullable KTRequestProcessBlock)failureBlock;
/// cancel current request, and do clear
- (void)cancel;

/// the request realy start
- (void)realyStart;
/// stop current request
- (void)stop;

/// called after request will start
- (void)willStart;
/// called after request realy start
- (void)didStart;

/// the request will finished
- (void)willFinished;
/// the request did finished
- (void)didFinished;

/// clean the request
- (void)clearRequest;

@end

NS_ASSUME_NONNULL_END
