//
//  ViewController.m
//  CocoapodsExample
//
//  Created by Tony Xiao on 11/28/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <PrimeData/PDAnalytics.h>
#import "ViewController.h"


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    userActivity.webpageURL = [NSURL URLWithString:@"http://www.segment.com"];
    [[PDAnalytics sharedAnalytics] continueUserActivity:userActivity];
    [[PDAnalytics sharedAnalytics] track:@"test"];
    [[PDAnalytics sharedAnalytics] flush];
}

- (IBAction)fireEvent:(id)sender
{
    [[PDAnalytics sharedAnalytics] track:@"Cocoapods Example Button"];
    [[PDAnalytics sharedAnalytics] flush];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
