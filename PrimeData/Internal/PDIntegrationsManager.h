//
//  PDIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDMiddleware.h"

/**
 * Filenames of "Application Support" files where essential data is stored.
 */
extern NSString *_Nonnull const kPDAnonymousIdFilename;
extern NSString *_Nonnull const kPDCachedSettingsFilename;

/**
 * NSNotification name, that is posted after integrations are loaded.
 */
extern NSString *_Nonnull PDAnalyticsIntegrationDidStart;

@class PDAnalytics;

NS_SWIFT_NAME(IntegrationsManager)
@interface PDIntegrationsManager : NSObject

// Exposed for testing.
+ (BOOL)isIntegration:(NSString *_Nonnull)key enabledInOptions:(NSDictionary *_Nonnull)options;
+ (BOOL)isTrackEvent:(NSString *_Nonnull)event enabledForIntegration:(NSString *_Nonnull)key inPlan:(NSDictionary *_Nonnull)plan;

// @Deprecated - Exposing for backward API compat reasons only
@property (nonatomic, readonly) NSMutableDictionary *_Nonnull registeredIntegrations;

- (instancetype _Nonnull)initWithAnalytics:(PDAnalytics *_Nonnull)analytics;

// @Deprecated - Exposing for backward API compat reasons only
- (NSString *_Nonnull)getAnonymousId;

@end


@interface PDIntegrationsManager (PDMiddleware) <PDMiddleware>

@end
