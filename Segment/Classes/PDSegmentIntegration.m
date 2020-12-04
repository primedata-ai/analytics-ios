#include <sys/sysctl.h>

#import "PDAnalytics.h"
#import "PDUtils.h"
#import "PDSegmentIntegration.h"
#import "PDReachability.h"
#import "PDHTTPClient.h"
#import "PDStorage.h"
#import "PDMacros.h"
#import "PDState.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_IOS
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

NSString *const PDSegmentDidSendRequestNotification = @"SegmentDidSendRequest";
NSString *const PDSegmentRequestDidSucceedNotification = @"SegmentRequestDidSucceed";
NSString *const PDSegmentRequestDidFailNotification = @"SegmentRequestDidFail";

NSString *const PDUserIdKey = @"PDUserId";
NSString *const PDQueueKey = @"PDQueue";
NSString *const PDTraitsKey = @"PDTraits";

NSString *const kPDUserIdFilename = @"segmentio.userId";
NSString *const kPDQueueFilename = @"segmentio.queue.plist";
NSString *const kPDTraitsFilename = @"segmentio.traits.plist";

// Equiv to UIBackgroundTaskInvalid.
NSUInteger const kPDBackgroundTaskInvalid = 0;

@interface PDSegmentIntegration ()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSURLSessionUploadTask *batchRequest;
@property (nonatomic, strong) PDReachability *reachability;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t backgroundTaskQueue;
@property (nonatomic, strong) NSDictionary *traits;
@property (nonatomic, assign) PDAnalytics *analytics;
@property (nonatomic, assign) PDAnalyticsConfiguration *configuration;
@property (atomic, copy) NSDictionary *referrer;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) NSURL *apiURL;
@property (nonatomic, strong) PDHTTPClient *httpClient;
@property (nonatomic, strong) id<PDStorage> fileStorage;
@property (nonatomic, strong) id<PDStorage> userDefaultsStorage;

#if TARGET_OS_IPHONE
@property (nonatomic, assign) UIBackgroundTaskIdentifier flushTaskID;
#else
@property (nonatomic, assign) NSUInteger flushTaskID;
#endif

@end

@interface PDAnalytics ()
@property (nonatomic, strong, readonly) PDAnalyticsConfiguration *oneTimeConfiguration;
@end

@implementation PDSegmentIntegration

- (id)initWithAnalytics:(PDAnalytics *)analytics httpClient:(PDHTTPClient *)httpClient fileStorage:(id<PDStorage>)fileStorage userDefaultsStorage:(id<PDStorage>)userDefaultsStorage;
{
    if (self = [super init]) {
        self.analytics = analytics;
        self.configuration = analytics.oneTimeConfiguration;
        self.httpClient = httpClient;
        self.httpClient.httpSessionDelegate = analytics.oneTimeConfiguration.httpSessionDelegate;
        self.fileStorage = fileStorage;
        self.userDefaultsStorage = userDefaultsStorage;
        self.apiURL = [PDMENT_API_BASE URLByAppendingPathComponent:@"import"];
        self.reachability = [PDReachability reachabilityWithHostname:@"google.com"];
        [self.reachability startNotifier];
        self.serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        self.backgroundTaskQueue = seg_dispatch_queue_create_specific("io.segment.analytics.backgroundTask", DISPATCH_QUEUE_SERIAL);
#if TARGET_OS_IPHONE
        self.flushTaskID = UIBackgroundTaskInvalid;
#else
        self.flushTaskID = 0; // the actual value of UIBackgroundTaskInvalid
#endif
        
        // load traits & user from disk.
        [self loadUserId];
        [self loadTraits];

        [self dispatchBackground:^{
            // Check for previous queue data in NSUserDefaults and remove if present.
            if ([[NSUserDefaults standardUserDefaults] objectForKey:PDQueueKey]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:PDQueueKey];
            }
#if !TARGET_OS_TV
            // Check for previous track data in NSUserDefaults and remove if present (Traits still exist in NSUserDefaults on tvOS)
            if ([[NSUserDefaults standardUserDefaults] objectForKey:PDTraitsKey]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:PDTraitsKey];
            }
#endif
        }];

        self.flushTimer = [NSTimer timerWithTimeInterval:self.configuration.flushInterval
                                                  target:self
                                                selector:@selector(flush)
                                                userInfo:nil
                                                 repeats:YES];
        
        [NSRunLoop.mainRunLoop addTimer:self.flushTimer
                                forMode:NSDefaultRunLoopMode];        
    }
    return self;
}

- (void)dispatchBackground:(void (^)(void))block
{
    seg_dispatch_specific_async(_serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void (^)(void))block
{
    seg_dispatch_specific_sync(_serialQueue, block);
}

- (void)beginBackgroundTask
{
    [self endBackgroundTask];

    seg_dispatch_specific_sync(_backgroundTaskQueue, ^{
        
        id<PDApplicationProtocol> application = [self.analytics oneTimeConfiguration].application;
        if (application && [application respondsToSelector:@selector(seg_beginBackgroundTaskWithName:expirationHandler:)]) {
            self.flushTaskID = [application seg_beginBackgroundTaskWithName:@"Segmentio.Flush"
                                                          expirationHandler:^{
                                                              [self endBackgroundTask];
                                                          }];
        }
    });
}

- (void)endBackgroundTask
{
    // endBackgroundTask and beginBackgroundTask can be called from main thread
    // We should not dispatch to the same queue we use to flush events because it can cause deadlock
    // inside @synchronized(self) block for PDIntegrationsManager as both events queue and main queue
    // attempt to call forwardSelector:arguments:options:
    // See https://github.com/segmentio/analytics-ios/issues/683
    seg_dispatch_specific_sync(_backgroundTaskQueue, ^{
        if (self.flushTaskID != kPDBackgroundTaskInvalid) {
            id<PDApplicationProtocol> application = [self.analytics oneTimeConfiguration].application;
            if (application && [application respondsToSelector:@selector(seg_endBackgroundTask:)]) {
                [application seg_endBackgroundTask:self.flushTaskID];
            }

            self.flushTaskID = kPDBackgroundTaskInvalid;
        }
    });
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, self.configuration.writeKey];
}

- (NSString *)userId
{
    return [PDState sharedInstance].userInfo.userId;
}

- (void)setUserId:(NSString *)userId
{
    [self dispatchBackground:^{
        [PDState sharedInstance].userInfo.userId = userId;
#if TARGET_OS_TV
        [self.userDefaultsStorage setString:userId forKey:PDUserIdKey];
#else
        [self.fileStorage setString:userId forKey:kPDUserIdFilename];
#endif
    }];
}

- (NSDictionary *)traits
{
    return [PDState sharedInstance].userInfo.traits;
}

- (void)setTraits:(NSDictionary *)traits
{
    [self dispatchBackground:^{
        [PDState sharedInstance].userInfo.traits = traits;
#if TARGET_OS_TV
        [self.userDefaultsStorage setDictionary:[self.traits copy] forKey:PDTraitsKey];
#else
        [self.fileStorage setDictionary:[self.traits copy] forKey:kPDTraitsFilename];
#endif
    }];
}

#pragma mark - Analytics API

- (void)identify:(PDIdentifyPayload *)payload
{
    [self dispatchBackground:^{
        self.userId = payload.userId;
        self.traits = payload.traits;
    }];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.traits forKey:@"traits"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];
    [self enqueueAction:@"identify" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)track:(PDTrackPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.event forKey:@"event"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];
    [self enqueueAction:@"track" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)screen:(PDScreenPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.name forKey:@"name"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueueAction:@"screen" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)group:(PDGroupPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.groupId forKey:@"groupId"];
    [dictionary setValue:payload.traits forKey:@"traits"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueueAction:@"group" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)alias:(PDAliasPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.theNewId forKey:@"userId"];
    [dictionary setValue:self.userId ?: [self.analytics getAnonymousId] forKey:@"previousId"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueueAction:@"alias" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

#pragma mark - Queueing

// Merges user provided integration options with bundled integrations.
- (NSDictionary *)integrationsDictionary:(NSDictionary *)integrations
{
    NSMutableDictionary *dict = [integrations ?: @{} mutableCopy];
    for (NSString *integration in self.analytics.bundledIntegrations) {
        // Don't record Segment.io in the dictionary. It is always enabled.
        if ([integration isEqualToString:@"Segment.io"]) {
            continue;
        }
        dict[integration] = @NO;
    }
    return [dict copy];
}

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)payload context:(NSDictionary *)context integrations:(NSDictionary *)integrations
{
    // attach these parts of the payload outside since they are all synchronous
    payload[@"type"] = action;

    [self dispatchBackground:^{
        // attach userId and anonymousId inside the dispatch_async in case
        // they've changed (see identify function)

        // Do not override the userId for an 'alias' action. This value is set in [alias:] already.
        if (![action isEqualToString:@"alias"]) {
            [payload setValue:[PDState sharedInstance].userInfo.userId forKey:@"userId"];
        }
        [payload setValue:[self.analytics getAnonymousId] forKey:@"anonymousId"];

        [payload setValue:[self integrationsDictionary:integrations] forKey:@"integrations"];

        [payload setValue:[context copy] forKey:@"context"];

        PDLog(@"%@ Enqueueing action: %@", self, payload);
        
        NSDictionary *queuePayload = [payload copy];
        
        if (self.configuration.experimental.rawSegmentModificationBlock != nil) {
            NSDictionary *tempPayload = self.configuration.experimental.rawSegmentModificationBlock(queuePayload);
            if (tempPayload == nil) {
                PDLog(@"rawSegmentModificationBlock cannot be used to drop events!");
            } else {
                // prevent anything else from modifying it at this point.
                queuePayload = [tempPayload copy];
            }
        }
        [self queuePayload:queuePayload];
    }];
}

- (void)queuePayload:(NSDictionary *)payload
{
    @try {
        PDLog(@"Queue is at max capacity (%tu), removing oldest payload.", self.queue.count);
        // Trim the queue to maxQueueSize - 1 before we add a new element.
        trimQueue(self.queue, self.analytics.oneTimeConfiguration.maxQueueSize - 1);
        [self.queue addObject:payload];
        [self persistQueue];
        [self flushQueueByLength];
    }
    @catch (NSException *exception) {
        PDLog(@"%@ Error writing payload: %@", self, exception);
    }
}

- (void)flush
{
    [self flushWithMaxSize:self.maxBatchSize];
}

- (void)flushWithMaxSize:(NSUInteger)maxBatchSize
{
    void (^startBatch)(void) = ^{
        NSArray *batch;
        if ([self.queue count] >= maxBatchSize) {
            batch = [self.queue subarrayWithRange:NSMakeRange(0, maxBatchSize)];
        } else {
            batch = [NSArray arrayWithArray:self.queue];
        }
        [self sendData:batch];
    };
    
    [self dispatchBackground:^{
        if ([self.queue count] == 0) {
            PDLog(@"%@ No queued API calls to flush.", self);
            [self endBackgroundTask];
            return;
        }
        if (self.batchRequest != nil) {
            PDLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        }
        // here
        startBatch();
    }];
}

- (void)flushQueueByLength
{
    [self dispatchBackground:^{
        PDLog(@"%@ Length is %lu.", self, (unsigned long)self.queue.count);

        if (self.batchRequest == nil && [self.queue count] >= self.configuration.flushAt) {
            [self flush];
        }
    }];
}

- (void)reset
{
    [self dispatchBackgroundAndWait:^{
#if TARGET_OS_TV
        [self.userDefaultsStorage removeKey:PDUserIdKey];
        [self.userDefaultsStorage removeKey:PDTraitsKey];
#else
        [self.fileStorage removeKey:kPDUserIdFilename];
        [self.fileStorage removeKey:kPDTraitsFilename];
#endif
        self.userId = nil;
        self.traits = [NSMutableDictionary dictionary];
    }];
}

- (void)notifyForName:(NSString *)name userInfo:(id)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:userInfo];
        PDLog(@"sent notification %@", name);
    });
}

- (void)sendData:(NSArray *)batch
{
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload setObject:iso8601FormattedString([NSDate date]) forKey:@"sentAt"];
    [payload setObject:batch forKey:@"batch"];

    PDLog(@"%@ Flushing %lu of %lu queued API calls.", self, (unsigned long)batch.count, (unsigned long)self.queue.count);
    PDLog(@"Flushing batch %@.", payload);

    self.batchRequest = [self.httpClient upload:payload forWriteKey:self.configuration.writeKey completionHandler:^(BOOL retry) {
        void (^completion)(void) = ^{
            if (retry) {
                [self notifyForName:PDSegmentRequestDidFailNotification userInfo:batch];
                self.batchRequest = nil;
                [self endBackgroundTask];
                return;
            }

            [self.queue removeObjectsInArray:batch];
            [self persistQueue];
            [self notifyForName:PDSegmentRequestDidSucceedNotification userInfo:batch];
            self.batchRequest = nil;
            [self endBackgroundTask];
        };
        
        [self dispatchBackground:completion];
    }];

    [self notifyForName:PDSegmentDidSendRequestNotification userInfo:batch];
}

- (void)applicationDidEnterBackground
{
    [self beginBackgroundTask];
    // We are gonna try to flush as much as we reasonably can when we enter background
    // since there is a chance that the user will never launch the app again.
    [self flush];
}

- (void)applicationWillTerminate
{
    [self dispatchBackgroundAndWait:^{
        if (self.queue.count)
            [self persistQueue];
    }];
}

#pragma mark - Private

- (NSMutableArray *)queue
{
    if (!_queue) {
        _queue = [[self.fileStorage arrayForKey:kPDQueueFilename] ?: @[] mutableCopy];
    }

    return _queue;
}

- (void)loadTraits
{
    if (![PDState sharedInstance].userInfo.traits) {
        NSDictionary *traits = nil;
#if TARGET_OS_TV
        traits = [[self.userDefaultsStorage dictionaryForKey:PDTraitsKey] ?: @{} mutableCopy];
#else
        traits = [[self.fileStorage dictionaryForKey:kPDTraitsFilename] ?: @{} mutableCopy];
#endif
        [PDState sharedInstance].userInfo.traits = traits;
    }
}

- (NSUInteger)maxBatchSize
{
    return 100;
}

- (void)loadUserId
{
    NSString *result = nil;
#if TARGET_OS_TV
    result = [[NSUserDefaults standardUserDefaults] valueForKey:PDUserIdKey];
#else
    result = [self.fileStorage stringForKey:kPDUserIdFilename];
#endif
    [PDState sharedInstance].userInfo.userId = result;
}

- (void)persistQueue
{
    [self.fileStorage setArray:[self.queue copy] forKey:kPDQueueFilename];
}

@end
