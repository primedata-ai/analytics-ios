//
//  PDIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import "PDAnalyticsConfiguration.h"
#import "PDAnalytics.h"
#import "PDMiddleware.h"
#import "PDCrypto.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

#if TARGET_OS_IPHONE
@implementation UIApplication (PDApplicationProtocol)

- (UIBackgroundTaskIdentifier)seg_beginBackgroundTaskWithName:(nullable NSString *)taskName expirationHandler:(void (^__nullable)(void))handler
{
    return [self beginBackgroundTaskWithName:taskName expirationHandler:handler];
}

- (void)seg_endBackgroundTask:(UIBackgroundTaskIdentifier)identifier
{
    [self endBackgroundTask:identifier];
}

@end
#endif

@implementation PDAnalyticsExperimental
@end

@interface PDAnalyticsConfiguration ()

@property (nonatomic, copy, readwrite) NSString *writeKey;
@property (nonatomic, copy, readwrite) NSString *scopeKey;
@property (nonatomic, copy, readwrite) NSString *url;
@property (nonatomic, strong, readonly) NSMutableArray *factories;
@property (nonatomic, strong) PDAnalyticsExperimental *experimental;


@property (nonatomic, assign) NSUInteger sessionLifeTime;

@property (nonatomic, assign) NSUInteger currentSessionLifeTime;

@end


@implementation PDAnalyticsConfiguration

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey scopeKey:(NSString *)scopeKey url:(NSString*)url
{
    return [[PDAnalyticsConfiguration alloc] initWithWriteKey:writeKey scopeKey:scopeKey url:url];
}

- (instancetype)initWithWriteKey:(NSString *)writeKey scopeKey:(NSString *)scopeKey  url:(NSString*)url
{
    if (self = [self init]) {
        self.writeKey = writeKey;
        self.scopeKey = scopeKey;
        self.url = url;
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.experimental = [[PDAnalyticsExperimental alloc] init];
        self.shouldUseLocationServices = NO;
        self.enableAdvertisingTracking = YES;
        self.shouldUseBluetooth = NO;
        self.flushAt = 1;
        self.sessionTimeout = 30;
        self.flushInterval = 30;
        self.maxQueueSize = 1000;
        self.payloadFilters = @{
            @"(fb\\d+://authorize#access_token=)([^ ]+)": @"$1((redacted/fb-auth-token))"
        };
        _factories = [NSMutableArray array];
#if TARGET_OS_IPHONE
        if ([UIApplication respondsToSelector:@selector(sharedApplication)]) {
            _application = [UIApplication performSelector:@selector(sharedApplication)];
        }
#elif TARGET_OS_OSX
        if ([NSApplication respondsToSelector:@selector(sharedApplication)]) {
            _application = [NSApplication performSelector:@selector(sharedApplication)];
        }
#endif
    }
    return self;
}

- (void)createNewSession:(NSString *)newSessionID
{
    self.sesstionTime = [NSDate date];
    self.currentSessionLifeTime = self.sessionTimeout;
    _sessionId = newSessionID;
}

- (BOOL)sessionIsValid
{
    NSDate *now = [NSDate date];
    NSInteger minuteDifference = [now timeIntervalSinceDate:self.sesstionTime] / 60.0;
    if (minuteDifference  > self.currentSessionLifeTime)
    {
        return NO;
    }
    return YES;
}

- (void)updateExistingSession
{
    self.currentSessionLifeTime = self.currentSessionLifeTime + self.sessionTimeout;
}

- (void)use:(id<PDIntegrationFactory>)factory
{
    [self.factories addObject:factory];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, [self dictionaryWithValuesForKeys:@[ @"writeKey", @"shouldUseLocationServices", @"flushAt" ]]];
}

// MARK: remove these when `middlewares` property is removed.

- (void)setMiddlewares:(NSArray<id<PDMiddleware>> *)middlewares
{
    self.sourceMiddleware = middlewares;
}

- (NSArray<id<PDMiddleware>> *)middlewares
{
    return self.sourceMiddleware;
}

- (void)setEdgeFunctionMiddleware:(id<PDEdgeFunctionMiddleware>)edgeFunctionMiddleware
{
    _edgeFunctionMiddleware = edgeFunctionMiddleware;
    self.sourceMiddleware = edgeFunctionMiddleware.sourceMiddleware;
    self.destinationMiddleware = edgeFunctionMiddleware.destinationMiddleware;
}

@end
