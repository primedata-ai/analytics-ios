//
//  AppDelegate.m
//  CocoapodsExample
//
//  Created by Tony Xiao on 11/28/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Segment/PDAnalytics.h>
#import "AppDelegate.h"


@interface AppDelegate ()

@end

// https://segment.com/segment-mobile/sources/ios_cocoapods_example/overview
NSString *const PDMENT_WRITE_KEY = @"zr5x22gUVBDM3hO3uHkbMkVe6Pd6sCna";


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [PDAnalytics debug:YES];
    PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey:PDMENT_WRITE_KEY];
    configuration.trackApplicationLifecycleEvents = YES;
    configuration.flushAt = 1;
    [PDAnalytics setupWithConfiguration:configuration];
    [[PDAnalytics sharedAnalytics] identify:@"Prateek" traits:nil options: @{
                                                                              @"anonymousId":@"test_anonymousId"
                                                                              }];
    [[PDAnalytics sharedAnalytics] track:@"Cocoapods Example Launched"];

    [[PDAnalytics sharedAnalytics] flush];
    NSLog(@"application:didFinishLaunchingWithOptions: %@", launchOptions);
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive:");
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground:");
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground:");
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive:");
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate:");
}

@end
