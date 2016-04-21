//
//  ViewController.m
//  MUNetworkRequest
//
//  Created by Muer on 16/4/20.
//  Copyright © 2016年 Muer. All rights reserved.
//

#import "ViewController.h"
#import "MUNetworkRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [MUNetworkRequest getRequest:@"https://api.github.com/" parameters:nil success:^(MUNetworkRequest *request, id responseObject) {
        NSLog(@"responseObject: %@", responseObject);
    } failure:^(MUNetworkRequest *request, NSError *error) {
        NSLog(@"error: %@", error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

