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

@interface KTViewController ()

@end

@implementation KTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[self config];
	
	[self testRequest];
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
	KTBaseRequest *request = [[KTBaseRequest alloc] init];
//	[request addRequestHeader:@{
//		@"Accept" : @"application/json",
//	}];
	request.customRequestUrl = @"http://www.phonegap100.com/appapi.php?a=getPortalList&catid=20&page=1";
	[request startWithCompletionSuccess:^(__kindof KTBaseRequest * _Nonnull request) {
			
	} failure:^(__kindof KTBaseRequest * _Nonnull request) {
			
	}];
}

@end
