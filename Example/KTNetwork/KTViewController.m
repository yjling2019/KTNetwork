//
//  KTViewController.m
//  KTNetwork
//
//  Created by KOTU on 02/24/2022.
//  Copyright (c) 2022 KOTU. All rights reserved.
//

#import "KTViewController.h"
#import "KTBaseRequest.h"

@interface KTViewController ()

@end

@implementation KTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[self testRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testRequest
{
	KTBaseRequest *request = [[KTBaseRequest alloc] init];
	request.baseUrl = @"https://www.phonegap100.com/appapi.php?a=getPortalList&catid=20&page=1";
	[request startWithCompletionSuccess:^(__kindof KTBaseRequest * _Nonnull request) {
			
	} failure:^(__kindof KTBaseRequest * _Nonnull request) {
			
	}];
}

@end
