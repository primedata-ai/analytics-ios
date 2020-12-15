//
//  AppDelegate.m
//  YoutubeDataAPISample
//
//  Created by Abhijeet Mishra on 11/02/18.
//  Copyright © 2018 Abhijeet Mishra. All rights reserved.
//

#import "AppDelegate.h"
#import <PrimeData.h>
#import <AdSupport/AdSupport.h>

@import GoogleSignIn;

@interface AppDelegate () <GIDSignInDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [GIDSignIn sharedInstance].clientID = @"106698409480-midbp7dd96hn6ehsgdt1uuv271o29vnd.apps.googleusercontent.com";
    [GIDSignIn sharedInstance].scopes = [[GIDSignIn sharedInstance].scopes arrayByAddingObject:@"https://www.googleapis.com/auth/youtube"];
    [GIDSignIn sharedInstance].delegate = self;
    
    PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey:@"1klTIBeF4McXUFp2WySSjYtJroA" scopeKey:@"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD" url:@"https://powehi.primedata.ai"];
    
//    PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey:@"1kdtO39R21tTzFxB9Un4u7kgLex" scopeKey:@"IOS-1kdtO13OTiGdlyFLFMdjqzHQ4u7" url:@"https://powehi.primedata.ai"];
    
    configuration.adSupportBlock = ^NSString * _Nonnull{
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    };
    
    [PDAnalytics setupWithConfiguration:configuration];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // ...
}
- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Google Sign In Methods

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *idToken = user.authentication.accessToken; // Safe to send to the server
    [[NSUserDefaults standardUserDefaults] setValue:idToken forKey:@"token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[PDAnalytics sharedAnalytics] identify:user.userID email:user.profile.email];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userLoggedIn" object:nil];
}

@end
