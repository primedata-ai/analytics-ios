//
//  ViewController.m
//  ManualExample
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Analytics/Analytics.h>
#import "ViewController.h"


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[PDAnalytics sharedAnalytics] track:@"Manual Example Main View Loaded"];
    [[PDAnalytics sharedAnalytics] flush];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fireEvent:(id)sender
{
    [[PDAnalytics sharedAnalytics] track:@"Manual Example Fire Event"];
    [[PDAnalytics sharedAnalytics] flush];
}

@end
