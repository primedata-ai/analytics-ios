#import <objc/runtime.h>
#import "PDAnalyticsUtils.h"
#import "PDAnalytics.h"
#import "PDIntegrationFactory.h"
#import "PDIntegration.h"
#import "PDPrimeDataIntegrationFactory.h"
#import "UIViewController+PDScreen.h"
#import "NSViewController+PDScreen.h"
#import "PDStoreKitTracker.h"
#import "PDHTTPClient.h"
#import "PDStorage.h"
#import "PDFileStorage.h"
#import "PDUserDefaultsStorage.h"
#import "PDMiddleware.h"
#import "PDContext.h"
#import "PDIntegrationsManager.h"
#import "PDState.h"
#import "PDUtils.h"

static PDAnalytics *__sharedInstance = nil;


@interface PDAnalytics ()

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) PDAnalyticsConfiguration *oneTimeConfiguration;
@property (nonatomic, strong) PDStoreKitTracker *storeKitTracker;
@property (nonatomic, strong) PDIntegrationsManager *integrationsManager;
@property (nonatomic, strong) PDMiddlewareRunner *runner;
@property (nonatomic, strong) PDHTTPClient *httpClient;

@end


@implementation PDAnalytics

+ (void)setupWithConfiguration:(PDAnalyticsConfiguration *)configuration
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] initWithConfiguration:configuration];
    });
}

- (instancetype)initWithConfiguration:(PDAnalyticsConfiguration *)configuration
{
    NSCParameterAssert(configuration != nil);

    if (self = [self init]) {
        self.oneTimeConfiguration = configuration;
        self.enabled = YES;

        // In swift this would not have been OK... But hey.. It's objc
        // TODO: Figure out if this is really the best way to do things here.
        self.integrationsManager = [[PDIntegrationsManager alloc] initWithAnalytics:self];
        
        self.runner = [[PDMiddlewareRunner alloc] initWithMiddleware:
                                                       [configuration.sourceMiddleware ?: @[] arrayByAddingObject:self.integrationsManager]];

        // Pass through for application state change events
        id<PDApplicationProtocol> application = configuration.application;
        if (application) {
#if TARGET_OS_IPHONE
            // Attach to application state change hooks
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            for (NSString *name in @[ UIApplicationDidEnterBackgroundNotification,
                                      UIApplicationDidFinishLaunchingNotification,
                                      UIApplicationWillEnterForegroundNotification,
                                      UIApplicationWillTerminateNotification,
                                      UIApplicationWillResignActiveNotification,
                                      UIApplicationDidBecomeActiveNotification ]) {
                [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:application];
            }
#elif TARGET_OS_OSX
            // Attach to application state change hooks
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            for (NSString *name in @[ NSApplicationDidResignActiveNotification,
                                      NSApplicationDidFinishLaunchingNotification,
                                      NSApplicationWillBecomeActiveNotification,
                                      NSApplicationWillTerminateNotification,
                                      NSApplicationWillResignActiveNotification,
                                      NSApplicationDidBecomeActiveNotification]) {
                [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:application];
            }
#endif
        }

#if TARGET_OS_IPHONE
        if (configuration.recordScreenViews) {
            [UIViewController seg_swizzleViewDidAppear];
        }
#elif TARGET_OS_OSX
        if (configuration.recordScreenViews) {
            [NSViewController seg_swizzleViewDidAppear];
        }
#endif
        if (configuration.trackInAppPurchases) {
            _storeKitTracker = [PDStoreKitTracker trackTransactionsForAnalytics:self];
        }

#if !TARGET_OS_TV
        if (configuration.trackPushNotifications && configuration.launchOptions) {
#if TARGET_OS_IOS
            NSDictionary *remoteNotification = configuration.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
#else
            NSDictionary *remoteNotification = configuration.launchOptions[NSApplicationLaunchUserNotificationKey];
#endif
            if (remoteNotification) {
                [self trackPushNotification:remoteNotification fromLaunch:YES];
            }
        }
#endif
        
        [PDState sharedInstance].configuration = configuration;
        [[PDState sharedInstance].context updateStaticContext];
        
        
        self.httpClient = [[PDHTTPClient alloc] initWithRequestFactory:self.oneTimeConfiguration.requestFactory url:self.oneTimeConfiguration.url];
        
        [self initSDK:^(BOOL valid) {
            NSLog(@"===>>>>SDK init successful");
        }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

NSString *const PDVersionKey = @"PDVersionKey";
NSString *const PDBuildKeyV1 = @"PDBuildKey";
NSString *const PDBuildKeyV2 = @"PDBuildKeyV2";

#if TARGET_OS_IPHONE
- (void)handleAppStateNotification:(NSNotification *)note
{
    PDApplicationLifecyclePayload *payload = [[PDApplicationLifecyclePayload alloc] init];
    payload.notificationName = note.name;
    [self run:PDEventTypeApplicationLifecycle payload:payload];

    if ([note.name isEqualToString:UIApplicationDidFinishLaunchingNotification]) {
        [self _applicationDidFinishLaunchingWithOptions:note.userInfo];
    } else if ([note.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        [self _applicationWillEnterForeground];
    } else if ([note.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
      [self _applicationDidEnterBackground];
    }
}
#elif TARGET_OS_OSX
- (void)handleAppStateNotification:(NSNotification *)note
{
    PDApplicationLifecyclePayload *payload = [[PDApplicationLifecyclePayload alloc] init];
    payload.notificationName = note.name;
    [self run:PDEventTypeApplicationLifecycle payload:payload];

    if ([note.name isEqualToString:NSApplicationDidFinishLaunchingNotification]) {
        [self _applicationDidFinishLaunchingWithOptions:note.userInfo];
    } else if ([note.name isEqualToString:NSApplicationWillBecomeActiveNotification]) {
        [self _applicationWillEnterForeground];
    } else if ([note.name isEqualToString:NSApplicationDidResignActiveNotification]) {
      [self _applicationDidEnterBackground];
    }
}
#endif

- (void)_applicationDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (!self.oneTimeConfiguration.trackApplicationLifecycleEvents) {
        return;
    }
    // Previously PDBuildKey was stored an integer. This was incorrect because the CFBundleVersion
    // can be a string. This migrates PDBuildKey to be stored as a string.
    NSInteger previousBuildV1 = [[NSUserDefaults standardUserDefaults] integerForKey:PDBuildKeyV1];
    if (previousBuildV1) {
        [[NSUserDefaults standardUserDefaults] setObject:[@(previousBuildV1) stringValue] forKey:PDBuildKeyV2];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:PDBuildKeyV1];
    }

    NSString *previousVersion = [[NSUserDefaults standardUserDefaults] stringForKey:PDVersionKey];
    NSString *previousBuildV2 = [[NSUserDefaults standardUserDefaults] stringForKey:PDBuildKeyV2];

    NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *currentBuild = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];

//    if (!previousBuildV2) {
//        [self track:@"Application Installed" properties:@{
//            @"version" : currentVersion ?: @"",
//            @"build" : currentBuild ?: @"",
//        }];
//    } else if (![currentBuild isEqualToString:previousBuildV2]) {
//        [self track:@"Application Updated" properties:@{
//            @"previous_version" : previousVersion ?: @"",
//            @"previous_build" : previousBuildV2 ?: @"",
//            @"version" : currentVersion ?: @"",
//            @"build" : currentBuild ?: @"",
//        }];
//    }

#if TARGET_OS_IPHONE
//    [self track:@"Application Opened" properties:@{
//        @"from_background" : @NO,
//        @"version" : currentVersion ?: @"",
//        @"build" : currentBuild ?: @"",
//        @"referring_application" : launchOptions[UIApplicationLaunchOptionsSourceApplicationKey] ?: @"",
//        @"url" : launchOptions[UIApplicationLaunchOptionsURLKey] ?: @"",
//    }];
#elif TARGET_OS_OSX
    [self track:@"Application Opened" properties:@{
        @"from_background" : @NO,
        @"version" : currentVersion ?: @"",
        @"build" : currentBuild ?: @"",
        @"default_launch" : launchOptions[NSApplicationLaunchIsDefaultLaunchKey] ?: @(YES),
    }];
#endif


    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:PDVersionKey];
    [[NSUserDefaults standardUserDefaults] setObject:currentBuild forKey:PDBuildKeyV2];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_applicationWillEnterForeground
{
    if (!self.oneTimeConfiguration.trackApplicationLifecycleEvents) {
        return;
    }
    NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *currentBuild = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
//    [self track:@"Application Opened" properties:@{
//        @"from_background" : @YES,
//        @"version" : currentVersion ?: @"",
//        @"build" : currentBuild ?: @"",
//    }];
    
    [[PDState sharedInstance].context updateStaticContext];
}

- (void)_applicationDidEnterBackground
{
  if (!self.oneTimeConfiguration.trackApplicationLifecycleEvents) {
    return;
  }
  [self track: @"Application Backgrounded"];
}


#pragma mark - Public API

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, [self class], [self dictionaryWithValuesForKeys:@[ @"configuration" ]]];
}

- (nullable PDAnalyticsConfiguration *)configuration
{
    // Remove deprecated configuration on 4.2+
    return nil;
}

#pragma mark - Validate Session

- (void)validateSession:(void (^)(BOOL valid))completionHandler
{
    if([self.oneTimeConfiguration sessionIsValid])
    {
        // add sessionTimeout minutes to  current session
        [self.oneTimeConfiguration updateExistingSession];
        completionHandler(YES);
    }else
    {
        //create new session
        [self initSDK: completionHandler];
    }
}

#pragma mark - Initialize

- (NSDictionary *)generateInitializePayload:(PDInitializePayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.event forKey:@"eventType"];
    [dictionary setValue:self.oneTimeConfiguration.scopeKey forKey:@"scope"];
    [dictionary setValue:payload.pd_properties forKey:@"properties"];
    
    NSMutableDictionary *combinedTarget = [[NSMutableDictionary alloc] init];
    [combinedTarget addEntriesFromDictionary:payload.pd_target];
    [combinedTarget setValue:self.oneTimeConfiguration.scopeKey forKey:@"scope"];
    [dictionary setValue:combinedTarget forKey:@"target"];
    
    NSMutableDictionary *combinedSource = [[NSMutableDictionary alloc] init];
    [combinedSource addEntriesFromDictionary:payload.pd_source];
    [combinedSource setValue:self.oneTimeConfiguration.scopeKey forKey:@"scope"];
    [dictionary setValue:combinedSource forKey:@"source"];
    
    [dictionary setValue:payload.timestamp forKey:@"timeStamp"];
    
    NSMutableDictionary *batch = [[NSMutableDictionary alloc] init];
    [batch setObject:iso8601FormattedString([NSDate date]) forKey:@"sendAt"];
    
    NSString *profileId =  [[NSUserDefaults standardUserDefaults] objectForKey:@"___profileId___"];
    if (profileId != nil)
    {
        [batch setObject:profileId forKey:@"profileId"];
    }
    
    NSMutableDictionary *combinedInternalSource = [[NSMutableDictionary alloc] init];
    [combinedInternalSource addEntriesFromDictionary:payload.internal_source];
    [combinedInternalSource setValue:self.oneTimeConfiguration.scopeKey forKey:@"scope"];
    [batch setValue:combinedInternalSource forKey:@"source"];
    
    [batch setObject:@[dictionary] forKey:@"events"];
    [batch setObject:self.oneTimeConfiguration.sessionId forKey:@"sessionId"];
    return batch;
}

- (void)initSDK:(void (^)(BOOL valid))completionHandler
{
    [self  initSDKWithEvent:@"open_app"
                 properties:@{}
                     source:
                           @{
                                 @"itemId": @"home",
                                 @"itemType": @"screen"
                           }
                    target:
                           @{

                                @"itemId": @"home",
                                @"itemType": @"screen"
                           } completionHandler:(void (^)(BOOL valid))completionHandler];
}

- (void)initSDKWithEvent:(NSString *)event properties:(NSDictionary *)properties source:(NSDictionary *)source target:(NSDictionary *)target completionHandler:(void (^)(BOOL valid))completionHandler
{
    [self.oneTimeConfiguration createNewSession:GenerateUUIDString()];
    
    PDInitializePayload *payload = [[PDInitializePayload alloc] initWithEvent:event
                                    properties:PDCoerceDictionary(properties)
                                        source:PDCoerceDictionary(source)
                                        target:PDCoerceDictionary(target)
                                       context:PDCoerceDictionary(nil)
                                  integrations:PDCoerceDictionary(nil)];
    
    if (self.oneTimeConfiguration.experimental.nanosecondTimestamps) {
        payload.timestamp = iso8601NanoFormattedString([NSDate date]);
    } else {
        payload.timestamp = iso8601FormattedString([NSDate date]);
    }

    [self.httpClient uploadContextEvents:[self generateInitializePayload:payload] forWriteKey:self.oneTimeConfiguration.writeKey completionHandler:^(BOOL retry) {
        completionHandler(YES);
    }];
}

#pragma mark - Identify

- (void)identify:(NSString *)userId
{
    [self identify:userId email:nil];
}

- (void)identify:(NSString *)userId email:(NSString* _Nullable)email
{
    NSCAssert1(userId.length > 0 , @"either userId (%@) must be provided.", userId);
    [self identify:userId email:email
        properties:nil
            source:@{
                      @"itemId": @"home",
                      @"itemType": @"screen"
                    }
            target:@{
                     @"itemId": userId,
                     @"itemType": @"analyticsUser"
                    }];
}

- (void)identify:(NSString *)userId email:(NSString*)email properties:(NSDictionary *)properties source:(NSDictionary *)source target:(NSDictionary *)target
{
    NSCAssert2(userId.length > 0 || target.count > 0, @"either userId (%@) or target (%@) must be provided.", userId, target);
    
    NSMutableDictionary *combined_target = [[NSMutableDictionary alloc] init];
    [combined_target addEntriesFromDictionary:target];
    NSDictionary *targetProperties = PDCoerceDictionary([target objectForKey:@"properties"]);
    
    
    NSMutableDictionary *combined_target_properties = [[NSMutableDictionary alloc] init];
    [combined_target_properties addEntriesFromDictionary:targetProperties];
    [combined_target_properties setValue:userId forKey:@"id"];
    [combined_target_properties setValue:[[[PDState sharedInstance].context.payload objectForKey:@"device"] objectForKey:@"id"] forKey:@"device_id"];
    [combined_target_properties setValue:[[[PDState sharedInstance].context.payload objectForKey:@"device"] objectForKey:@"advertisingId"] forKey:@"advertisingId"];
    if (email)
    {
        [combined_target_properties setValue:email forKey:@"email"];
    }
    
    [combined_target setValue:combined_target_properties forKey:@"properties"];
    
    [self validateSession:^(BOOL valid) {
        PDInitializePayload *payload = [[PDInitializePayload alloc] initWithEvent:@"identify"
                                         properties:PDCoerceDictionary(properties)
                                             source:PDCoerceDictionary(source)
                                             target:PDCoerceDictionary(combined_target)
                                            context:PDCoerceDictionary(nil)
                                       integrations:PDCoerceDictionary(nil)];
        
        if (self.oneTimeConfiguration.experimental.nanosecondTimestamps) {
            payload.timestamp = iso8601NanoFormattedString([NSDate date]);
        } else {
            payload.timestamp = iso8601FormattedString([NSDate date]);
        }
        
        [self.httpClient uploadContextEvents:[self generateInitializePayload:payload] forWriteKey:self.oneTimeConfiguration.writeKey completionHandler:^(BOOL retry) {
            NSLog(@"Identify successful");
        }];
    }];
}

#pragma mark - Track

- (void)track:(NSString *)event
{
    [self track:event
     properties:nil
         source:@{
                  @"itemId": @"home",
                  @"itemType": @"screen"
                 }
         target:@{
                 @"itemId": @"home",
                 @"itemType": @"screen"
                 }];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties source:(NSDictionary *)source target:(NSDictionary *)target
{
    NSCAssert1(event.length > 0, @"event (%@) must not be empty.", event);
    
    [self validateSession:^(BOOL valid) {
            [self run:PDEventTypeTrack payload:
         [[PDTrackPayload alloc] initWithEvent:event
                                    properties:PDCoerceDictionary(properties)
                                        source:PDCoerceDictionary(source)
                                        target:PDCoerceDictionary(target)
                                       context:PDCoerceDictionary(nil)
                                  integrations:PDCoerceDictionary(nil)]];
    }];
}

#pragma mark - Screen

- (void)screen:(NSString *)screenTitle
{
    [self screen:screenTitle category:nil properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle category:(NSString *)category
{
    [self screen:screenTitle category:category properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties
{
    [self screen:screenTitle category:nil properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle category:(NSString *)category properties:(SERIALIZABLE_DICT _Nullable)properties
{
    [self screen:screenTitle category:category properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self screen:screenTitle category:nil properties:properties options:options];
}

- (void)screen:(NSString *)screenTitle category:(NSString *)category properties:(SERIALIZABLE_DICT _Nullable)properties options:(SERIALIZABLE_DICT _Nullable)options
{
    NSCAssert1(screenTitle.length > 0, @"screen name (%@) must not be empty.", screenTitle);

    [self run:PDEventTypeScreen payload:
                                     [[PDScreenPayload alloc] initWithName:screenTitle
                                                                   category:category
                                                                 properties:PDCoerceDictionary(properties)
                                                                    context:PDCoerceDictionary([options objectForKey:@"context"])
                                                               integrations:[options objectForKey:@"integrations"]]];
}

#pragma mark - Group

- (void)group:(NSString *)groupId
{
    [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits
{
    [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    [self run:PDEventTypeGroup payload:
                                    [[PDGroupPayload alloc] initWithGroupId:groupId
                                                                      traits:PDCoerceDictionary(traits)
                                                                     context:PDCoerceDictionary([options objectForKey:@"context"])
                                                                integrations:[options objectForKey:@"integrations"]]];
}

#pragma mark - Alias

- (void)alias:(NSString *)newId
{
    [self alias:newId options:nil];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options
{
    [self run:PDEventTypeAlias payload:
                                    [[PDAliasPayload alloc] initWithNewId:newId
                                                                   context:PDCoerceDictionary([options objectForKey:@"context"])
                                                              integrations:[options objectForKey:@"integrations"]]];
}

- (void)trackPushNotification:(NSDictionary *)properties fromLaunch:(BOOL)launch
{
//    if (launch) {
//        [self track:@"Push Notification Tapped" properties:properties];
//    } else {
//        [self track:@"Push Notification Received" properties:properties];
//    }
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo
{
    if (self.oneTimeConfiguration.trackPushNotifications) {
        [self trackPushNotification:userInfo fromLaunch:NO];
    }
    PDRemoteNotificationPayload *payload = [[PDRemoteNotificationPayload alloc] init];
    payload.userInfo = userInfo;
    [self run:PDEventTypeReceivedRemoteNotification payload:payload];
}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    PDRemoteNotificationPayload *payload = [[PDRemoteNotificationPayload alloc] init];
    payload.error = error;
    [self run:PDEventTypeFailedToRegisterForRemoteNotifications payload:payload];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSParameterAssert(deviceToken != nil);
    PDRemoteNotificationPayload *payload = [[PDRemoteNotificationPayload alloc] init];
    payload.deviceToken = deviceToken;
    [PDState sharedInstance].context.deviceToken = deviceTokenToString(deviceToken);
    [self run:PDEventTypeRegisteredForRemoteNotifications payload:payload];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo
{
    PDRemoteNotificationPayload *payload = [[PDRemoteNotificationPayload alloc] init];
    payload.actionIdentifier = identifier;
    payload.userInfo = userInfo;
    [self run:PDEventTypeHandleActionWithForRemoteNotification payload:payload];
}

- (void)continueUserActivity:(NSUserActivity *)activity
{
    PDContinueUserActivityPayload *payload = [[PDContinueUserActivityPayload alloc] init];
    payload.activity = activity;
    [self run:PDEventTypeContinueUserActivity payload:payload];

    if (!self.oneTimeConfiguration.trackDeepLinks) {
        return;
    }

    if ([activity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSString *urlString = activity.webpageURL.absoluteString;
        [PDState sharedInstance].context.referrer = @{
            @"url" : urlString,
        };

        NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:activity.userInfo.count + 2];
        [properties addEntriesFromDictionary:activity.userInfo];
        properties[@"url"] = urlString;
        properties[@"title"] = activity.title ?: @"";
        properties = [PDUtils traverseJSON:properties
                      andReplaceWithFilters:self.oneTimeConfiguration.payloadFilters];
//        [self track:@"Deep Link Opened" properties:[properties copy]];
    }
}

- (void)openURL:(NSURL *)url options:(NSDictionary *)options
{
    PDOpenURLPayload *payload = [[PDOpenURLPayload alloc] init];
    payload.url = [NSURL URLWithString:[PDUtils traverseJSON:url.absoluteString
                                        andReplaceWithFilters:self.oneTimeConfiguration.payloadFilters]];
    payload.options = options;
    [self run:PDEventTypeOpenURL payload:payload];

    if (!self.oneTimeConfiguration.trackDeepLinks) {
        return;
    }
    
    NSString *urlString = url.absoluteString;
    [PDState sharedInstance].context.referrer = @{
        @"url" : urlString,
    };

    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:options.count + 2];
    [properties addEntriesFromDictionary:options];
    properties[@"url"] = urlString;
    properties = [PDUtils traverseJSON:properties
                  andReplaceWithFilters:self.oneTimeConfiguration.payloadFilters];
//    [self track:@"Deep Link Opened" properties:[properties copy]];
}

- (void)reset
{
    [self run:PDEventTypeReset payload:nil];
}

- (void)flush
{
    [self run:PDEventTypeFlush payload:nil];
}

- (void)enable
{
    _enabled = YES;
}

- (void)disable
{
    _enabled = NO;
}

- (NSString *)getAnonymousId
{
    return [PDState sharedInstance].userInfo.anonymousId;
}

- (NSString *)getDeviceToken
{
    return [PDState sharedInstance].context.deviceToken;
}

- (NSDictionary *)bundledIntegrations
{
    return [self.integrationsManager.registeredIntegrations copy];
}

#pragma mark - Class Methods

+ (instancetype)sharedAnalytics
{
    NSCAssert(__sharedInstance != nil, @"library must be initialized before calling this method.");
    return __sharedInstance;
}

+ (void)debug:(BOOL)showDebugLogs
{
    PDSetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version
{
    // this has to match the actual version, NOT what's in info.plist
    // because Apple only accepts X.X.X as versions in the review process.
    return @"4.1.1";
}

#pragma mark - Helpers

- (void)run:(PDEventType)eventType payload:(PDPayload *)payload
{
    if (!self.enabled) {
        return;
    }
    
    if (self.oneTimeConfiguration.experimental.nanosecondTimestamps) {
        payload.timestamp = iso8601NanoFormattedString([NSDate date]);
    } else {
        payload.timestamp = iso8601FormattedString([NSDate date]);
    }
    
    PDContext *context = [[[PDContext alloc] initWithAnalytics:self] modify:^(id<PDMutableContext> _Nonnull ctx) {
        ctx.eventType = eventType;
        ctx.payload = payload;
        ctx.payload.messageId = GenerateUUIDString();
        if (ctx.payload.userId == nil) {
            ctx.payload.userId = [PDState sharedInstance].userInfo.userId;
        }
        if (ctx.payload.anonymousId == nil) {
            ctx.payload.anonymousId = [PDState sharedInstance].userInfo.anonymousId;
        }
    }];
    
    // Could probably do more things with callback later, but we don't use it yet.
    [self.runner run:context callback:^(BOOL earlyExit, NSArray<id<PDMiddleware>> * _Nonnull remainingMiddlewares) {
        NSLog(@"finish...");
    }];
}

- (id<PDEdgeFunctionMiddleware>)edgeFunction
{
    return _oneTimeConfiguration.edgeFunctionMiddleware;
}

@end
