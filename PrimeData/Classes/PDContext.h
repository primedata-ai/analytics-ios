//
//  PDContext.h
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDIntegration.h"

typedef NS_ENUM(NSInteger, PDEventType) {
    // Should not happen, but default state
    PDEventTypeUndefined,
    // Core Tracking Methods
    PDEventTypeIdentify,
    PDEventTypeTrack,
    PDEventTypeScreen,
    PDEventTypeGroup,
    PDEventTypeAlias,

    // General utility
    PDEventTypeReset,
    PDEventTypeFlush,

    // Remote Notification
    PDEventTypeReceivedRemoteNotification,
    PDEventTypeFailedToRegisterForRemoteNotifications,
    PDEventTypeRegisteredForRemoteNotifications,
    PDEventTypeHandleActionWithForRemoteNotification,

    // Application Lifecycle
    PDEventTypeApplicationLifecycle,
    //    DidFinishLaunching,
    //    PDEventTypeApplicationDidEnterBackground,
    //    PDEventTypeApplicationWillEnterForeground,
    //    PDEventTypeApplicationWillTerminate,
    //    PDEventTypeApplicationWillResignActive,
    //    PDEventTypeApplicationDidBecomeActive,

    // Misc.
    PDEventTypeContinueUserActivity,
    PDEventTypeOpenURL,

} NS_SWIFT_NAME(EventType);

@class PDAnalytics;
@protocol PDMutableContext;


NS_SWIFT_NAME(Context)
@interface PDContext : NSObject <NSCopying>

// Loopback reference to the top level PDAnalytics object.
// Not sure if it's a good idea to keep this around in the context.
// since we don't really want people to use it due to the circular
// reference and logic (Thus prefixing with underscore). But
// Right now it is required for integrations to work so I guess we'll leave it in.
@property (nonatomic, readonly, nonnull) PDAnalytics *_analytics;
@property (nonatomic, readonly) PDEventType eventType;

@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, readonly, nullable) PDPayload *payload;
@property (nonatomic, readonly) BOOL debug;

- (instancetype _Nonnull)initWithAnalytics:(PDAnalytics *_Nonnull)analytics;

- (PDContext *_Nonnull)modify:(void (^_Nonnull)(id<PDMutableContext> _Nonnull ctx))modify;

@end

@protocol PDMutableContext <NSObject>

@property (nonatomic) PDEventType eventType;
@property (nonatomic, nullable) PDPayload *payload;
@property (nonatomic, nullable) NSError *error;
@property (nonatomic) BOOL debug;

@end
