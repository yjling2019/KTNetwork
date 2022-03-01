//
//  KTViewController.m
//  KTNetwork
//
//  Created by KOTU on 02/24/2022.
//  Copyright (c) 2022 KOTU. All rights reserved.
//

#import "KTViewController.h"
#import "KTBaseRequest.h"
#import "KTNetworkAgent.h"
#import "KTNetworkConfig.h"
#import "KTGroupRequest.h"
#import "KTChainRequest.h"

@interface KTViewController ()

@end

@implementation KTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[self config];
	
//	[self testRequest];
	[self testChainRequest];
	[self testBatchRequest];
}

- (void)config
{
//	NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:[KTNetworkAgent sharedAgent].jsonResponseSerializer.acceptableContentTypes];
//	[acceptableContentTypes addObject:@"text/html"];
//	[KTNetworkAgent sharedAgent].jsonResponseSerializer.acceptableContentTypes = acceptableContentTypes;
	
	[KTNetworkConfig sharedConfig].acceptableContentTypes = [NSSet setWithObject:@"text/html"];
}

- (void)testRequest
{
	KTBaseRequest *request = [self getRequest];
	[request startWithCompletionSuccess:^(__kindof KTBaseRequest * _Nonnull request) {
			
	} failure:^(__kindof KTBaseRequest * _Nonnull request) {
			
	}];
}

- (void)testChainRequest
{
	KTChainRequest *request = [[KTChainRequest alloc] init];
	[request addRequestsWithArray:@[[self getRequest], [self getRequest]]];
	[request startWithCompletionSuccess:^(id<KTRequestProcessProtocol>  _Nonnull request) {
			
	} failure:^(id<KTRequestProcessProtocol>  _Nonnull request) {
			
	}];
}

- (void)testBatchRequest
{
	
}

- (KTBaseRequest *)getRequest
{
	KTBaseRequest *request = [[KTBaseRequest alloc] init];
	request.baseUrl = @"http://www.phonegap100.com/appapi.php?a=getPortalList&catid=20&page=1";
	return request;
}

@end
