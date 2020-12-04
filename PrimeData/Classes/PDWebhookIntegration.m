#import <Foundation/Foundation.h>
#import "PDWebhookIntegration.h"
#import "PDHTTPClient.h"
#import "PDState.h"
#import "PDAnalyticsUtils.h"
#import "PDUtils.h"

NS_ASSUME_NONNULL_BEGIN
@interface PDWebhookIntegration : NSObject <PDIntegration>

@property (nonatomic, strong) PDHTTPClient *client;
@property (nonatomic, strong) NSString *webhookUrl;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) PDAnalytics *analytics;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

- (instancetype)initWithAnalytics:(PDAnalytics *)analytics httpClient:(PDHTTPClient *)client webhookUrl:(NSString *)webhookUrl name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

@implementation PDWebhookIntegration

- (instancetype)initWithAnalytics:(PDAnalytics *)analytics httpClient:(PDHTTPClient *)client webhookUrl:(NSString *)webhookUrl name:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        _analytics = analytics;
        _client = client;
        _webhookUrl = webhookUrl;
        _serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics.webhook", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)sendPayloadToWebhook:(NSDictionary *)data {
    NSURLSession *session = self.client.genericSession;

    NSURL *url = [NSURL URLWithString:self.webhookUrl];
    NSMutableURLRequest *request = self.client.requestFactory(url);

    // This is a workaround for an IOS 8.3 bug that causes Content-Type to be incorrectly set
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [request setHTTPMethod:@"POST"];

    NSError *error = nil;
    NSException *exception = nil;
    NSData *payload = nil;
    @try {
        payload = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    }
    @catch (NSException *exc) {
        exception = exc;
    }
    if (error || exception) {
        PDLog(@"Error serializing JSON for upload to webhook %@", error);
        return;
    }

    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:payload completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            // Network error. Retry.
            PDLog(@"Error uploading request %@.", error);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code < 300) {
            // 2xx response codes. Don't retry.
            return;
        }
        if (code < 400) {
            // 3xx response codes. Retry.
            PDLog(@"Server responded with unexpected HTTP code %zd.", code);
            return;
        }
        if (code == 429) {
            // 429 response codes. Retry.
            PDLog(@"Server limited client with response code %zd.", code);
            return;
        }
        if (code < 500) {
            // non-429 4xx response codes. Don't retry.
            PDLog(@"Server rejected payload with HTTP code %zd.", code);
            return;
        }

        // 5xx response codes. Retry.
        PDLog(@"Server error with HTTP code %zd.", code);
    }];
    [task resume];
}

// Merges user provided integration options with bundled integrations.
- (NSDictionary *)integrationsDictionary:(NSDictionary *)integrations
{
    NSMutableDictionary *dict = [integrations ?: @{} mutableCopy];
    for (NSString *integration in self.analytics.bundledIntegrations) {
        // Don't record PrimeData.io in the dictionary. It is always enabled.
        if ([integration isEqualToString:@"PrimeData.io"]) {
            continue;
        }
        dict[integration] = @NO;
    }
    return [dict copy];
}

// Code borrowed from PDPrimeDataIntegration.enqueueAction
- (void)enqueue:(NSString *) type dictionary:(NSMutableDictionary *) payload context:(NSDictionary *)context integrations:(NSDictionary *)integrations
{
    payload[@"type"] = type;
    if (![type isEqualToString:@"alias"]) {
        [payload setValue:[PDState sharedInstance].userInfo.userId forKey:@"userId"];
    }
    [payload setValue:[self.analytics getAnonymousId] forKey:@"anonymousId"];
    [payload setValue:[self integrationsDictionary:integrations] forKey:@"integrations"];
    [payload setValue:[context copy] forKey:@"context"];

    [self dispatchBackground:^{
        PDLog(@"%@ Enqueueing payload %@ through %@", self, type, self.name);
        NSDictionary *queuePayload = [payload copy];
        [self sendPayloadToWebhook:queuePayload];
    }];
}

- (void)dispatchBackground:(void (^)(void))block
{
    seg_dispatch_specific_async(_serialQueue, block);
}

- (NSString *)userId
{
    return [PDState sharedInstance].userInfo.userId;
}

- (void)identify:(PDIdentifyPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.traits forKey:@"traits"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueue:@"identify" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)track:(PDTrackPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.event forKey:@"event"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueue:@"track" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)screen:(PDScreenPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.name forKey:@"name"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueue:@"screen" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)group:(PDGroupPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.groupId forKey:@"groupId"];
    [dictionary setValue:payload.traits forKey:@"traits"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueue:@"group" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)alias:(PDAliasPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.theNewId forKey:@"userId"];
    [dictionary setValue:self.userId ?: [self.analytics getAnonymousId] forKey:@"previousId"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueue:@"alias" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

@end

@implementation PDWebhookIntegrationFactory
- (instancetype)initWithName:(NSString *)name webhookUrl:(NSString *)webhookUrl {
    if (self = [super init]) {
        _name = name;
        _webhookUrl = webhookUrl;
    }
    return self;
}

- (id <PDIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(PDAnalytics *)analytics {
    PDHTTPClient *httpClient = [[PDHTTPClient alloc] initWithRequestFactory:nil];
    return [[PDWebhookIntegration alloc] initWithAnalytics:analytics httpClient:httpClient webhookUrl:self.webhookUrl name:self.name];
}

- (NSString *)key {
    return [NSString stringWithFormat:@"webhook_%@", _name];
}


@end
