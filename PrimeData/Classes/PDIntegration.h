#import <Foundation/Foundation.h>
#import "PDIdentifyPayload.h"
#import "PDTrackPayload.h"
#import "PDScreenPayload.h"
#import "PDAliasPayload.h"
#import "PDIdentifyPayload.h"
#import "PDGroupPayload.h"
#import "PDContext.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Integration)
@protocol PDIntegration <NSObject>

@optional

- (void)initialize:(PDInitializePayload *)payload;

// Identify will be called when the user calls either of the following:
// 1. [[PDAnalytics sharedInstance] identify:someUserId];
// 2. [[PDAnalytics sharedInstance] identify:someUserId traits:someTraits];
// 3. [[PDAnalytics sharedInstance] identify:someUserId traits:someTraits options:someOptions];
// @see https://segment.com/docs/spec/identify/
- (void)identify:(PDIdentifyPayload *)payload;

// Track will be called when the user calls either of the following:
// 1. [[PDAnalytics sharedInstance] track:someEvent];
// 2. [[PDAnalytics sharedInstance] track:someEvent properties:someProperties];
// 3. [[PDAnalytics sharedInstance] track:someEvent properties:someProperties options:someOptions];
// @see https://segment.com/docs/spec/track/
- (void)track:(PDTrackPayload *)payload;

// Screen will be called when the user calls either of the following:
// 1. [[PDAnalytics sharedInstance] screen:someEvent];
// 2. [[PDAnalytics sharedInstance] screen:someEvent properties:someProperties];
// 3. [[PDAnalytics sharedInstance] screen:someEvent properties:someProperties options:someOptions];
// @see https://segment.com/docs/spec/screen/
- (void)screen:(PDScreenPayload *)payload;

// Group will be called when the user calls either of the following:
// 1. [[PDAnalytics sharedInstance] group:someGroupId];
// 2. [[PDAnalytics sharedInstance] group:someGroupId traits:];
// 3. [[PDAnalytics sharedInstance] group:someGroupId traits:someGroupTraits options:someOptions];
// @see https://segment.com/docs/spec/group/
- (void)group:(PDGroupPayload *)payload;

// Alias will be called when the user calls either of the following:
// 1. [[PDAnalytics sharedInstance] alias:someNewId];
// 2. [[PDAnalytics sharedInstance] alias:someNewId options:someOptions];
// @see https://segment.com/docs/spec/alias/
- (void)alias:(PDAliasPayload *)payload;

// Reset is invoked when the user logs out, and any data saved about the user should be cleared.
- (void)reset;

// Flush is invoked when any queued events should be uploaded.
- (void)flush;

// App Delegate Callbacks

// Callbacks for notifications changes.
// ------------------------------------
- (void)receivedRemoteNotification:(NSDictionary *)userInfo;
- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo;

// Callbacks for app state changes
// -------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

- (void)continueUserActivity:(NSUserActivity *)activity;
- (void)openURL:(NSURL *)url options:(NSDictionary *)options;

@end

NS_ASSUME_NONNULL_END
