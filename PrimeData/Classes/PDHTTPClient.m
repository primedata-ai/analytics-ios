#import "PDHTTPClient.h"
#import "NSData+PDGZIP.h"
#import "PDAnalyticsUtils.h"

static const NSUInteger kMaxBatchSize = 475000; // 475KB

@implementation PDHTTPClient

+ (NSMutableURLRequest * (^)(NSURL *))defaultRequestFactory
{
    return ^(NSURL *url) {
        return [NSMutableURLRequest requestWithURL:url];
    };
}

+ (NSString *)authorizationHeader:(NSString *)writeKey
{
    NSString *rawHeader = [writeKey stringByAppendingString:@":"];
    NSData *userPasswordData = [rawHeader dataUsingEncoding:NSUTF8StringEncoding];
    return [userPasswordData base64EncodedStringWithOptions:0];
}


- (instancetype)initWithRequestFactory:(PDRequestFactory)requestFactory url:(NSString*)url
{
    if (self = [self init]) {
        if (requestFactory == nil) {
            self.requestFactory = [PDHTTPClient defaultRequestFactory];
        } else {
            self.requestFactory = requestFactory;
        }
        self.url = url;
        _sessionsByWriteKey = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPAdditionalHeaders = @{
        };
        _genericSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (NSURLSession *)sessionForWriteKey:(NSString *)writeKey
{
    NSURLSession *session = self.sessionsByWriteKey[writeKey];
    if (!session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPAdditionalHeaders = @{
            @"x-client-access-token": @"1klTIBeF4McXUFp2WySSjYtJroA",
            @"x-client-id": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
            @"Content-Type": @"text/plain;charset=UTF-8"
        };
        session = [NSURLSession sessionWithConfiguration:config delegate:self.httpSessionDelegate delegateQueue:NULL];
        self.sessionsByWriteKey[writeKey] = session;
    }
    
    return session;
}

- (void)dealloc
{
    for (NSURLSession *session in self.sessionsByWriteKey.allValues) {
        [session finishTasksAndInvalidate];
    }
    [self.genericSession finishTasksAndInvalidate];
}

- (nullable NSURLSessionUploadTask *)uploadContextEvents:(NSDictionary *)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler
{
    NSString *api = @"context";
    NSURLSession *session = [self sessionForWriteKey:writeKey];

    NSURL *url = [[NSURL URLWithString:self.url] URLByAppendingPathComponent:api];
    NSMutableURLRequest *request = self.requestFactory(url);

    [request setHTTPMethod:@"POST"];

    NSError *error = nil;
    NSException *exception = nil;
    NSData *payload = nil;
    @try {
        payload = [NSJSONSerialization dataWithJSONObject:batch options:0 error:&error];
    }
    @catch (NSException *exc) {
        exception = exc;
    }

    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:payload completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error)
        {
            // Network error. Retry.
            PDLog(@"Error uploading request %@.", error);
            completionHandler(YES);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code < 300) {
            NSError *jsonError = nil;

            NSDictionary * parsedData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSString *profileId = [parsedData objectForKey:@"profileId"];
            NSLog(@"___profileID___: %@", profileId);
            if (profileId != nil)
            {
                [[NSUserDefaults standardUserDefaults] setValue:profileId forKey:PROFILE_ID_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }

            // 2xx response codes. Don't retry.
            completionHandler(NO);
            return;
        }
        if (code < 400) {
            // 3xx response codes. Retry.
            PDLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(YES);
            return;
        }
        if (code == 429) {
          // 429 response codes. Retry.
          PDLog(@"Server limited client with response code %d.", code);
          completionHandler(YES);
          return;
        }
        if (code < 500) {
            // non-429 4xx response codes. Don't retry.
            PDLog(@"Server rejected payload with HTTP code %d.", code);
            completionHandler(NO);
            return;
        }

        // 5xx response codes. Retry.
        PDLog(@"Server error with HTTP code %d.", code);
        completionHandler(YES);
    }];
    [task resume];
    return task;
}

- (NSDictionary *)batchForContextEndpoint:(NSDictionary *)batch
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:batch];
    if (batch) {
        NSArray *events = [batch objectForKey:@"events"];
        NSMutableArray *contextEvents = [NSMutableArray array];
        for (NSDictionary *obj in events)
        {
            if ([[obj objectForKey:@"eventType"] isEqualToString:@"open_app"] || [[obj objectForKey:@"eventType"] isEqualToString:@"identify"])
            {
                NSMutableDictionary *newObj = [NSMutableDictionary dictionary];
                [newObj addEntriesFromDictionary:obj];
                if([newObj objectForKey:@"outside_source"] != nil)
                {
                    [dic setObject:[newObj objectForKey:@"outside_source"] forKey:@"source"];
                }
                [contextEvents addObject:newObj];
                [newObj removeObjectForKey:@"outside_source"];
            }
        }
        [dic setObject:contextEvents forKey:@"events"];
    }
    return dic;
}

- (NSDictionary *)batchForSmileEndpoint:(NSDictionary *)batch
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:batch];
    if (batch) {
        NSArray *events = [batch objectForKey:@"events"];
        NSMutableArray *contextEvents = [NSMutableArray array];
        for (NSDictionary *obj in events)
        {
            if ((![[obj objectForKey:@"eventType"] isEqualToString:@"open_app"]) && (![[obj objectForKey:@"eventType"] isEqualToString:@"identify"]))
            {
                [contextEvents addObject:obj];
            }
        }
        [dic setObject:contextEvents forKey:@"events"];
    }
    return dic;
}

- (nullable NSURLSessionUploadTask *)uploadEvents:(NSDictionary *)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler
{
    __block NSDictionary *contextBatch = [self batchForContextEndpoint:batch];
    __block NSDictionary *trackBatch = [self batchForSmileEndpoint:batch];
    if ([[contextBatch objectForKey:@"events"] count] != 0)
    {
        NSURLSessionUploadTask *contextTask = [self uploadContextEvents:contextBatch forWriteKey:writeKey completionHandler:^(BOOL retry) {
            if (retry)
            {
                completionHandler(retry);
                return;
            }else
            {
               if([[trackBatch objectForKey:@"events"] count] != 0)
               {
                   [self uploadTrackEvents:trackBatch forWriteKey:writeKey completionHandler:completionHandler];
               }else
               {
                   completionHandler(retry);
               }
            }
        }];
        return contextTask;
    }else
        {
            return [self uploadTrackEvents:trackBatch forWriteKey:writeKey completionHandler:completionHandler];
        }
}

- (nullable NSURLSessionUploadTask *)uploadTrackEvents:(NSDictionary *)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler
{
    NSString *api = @"smile";
    
    NSURLSession *session = [self sessionForWriteKey:writeKey];

    NSURL *url = [[NSURL URLWithString:self.url] URLByAppendingPathComponent:api];
    NSMutableURLRequest *request = self.requestFactory(url);

    [request setHTTPMethod:@"POST"];

    NSError *error = nil;
    NSException *exception = nil;
    NSData *payload = nil;
    @try {
        payload = [NSJSONSerialization dataWithJSONObject:batch options:0 error:&error];
    }
    @catch (NSException *exc) {
        exception = exc;
    }
    
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:payload completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error)
        {
            // Network error. Retry.
            PDLog(@"Error uploading request %@.", error);
            completionHandler(YES);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code < 300) {
            NSError *jsonError = nil;
            // 2xx response codes. Don't retry.
            completionHandler(NO);
            return;
        }
        if (code < 400) {
            // 3xx response codes. Retry.
            PDLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(YES);
            return;
        }
        if (code == 429) {
          // 429 response codes. Retry.
          PDLog(@"Server limited client with response code %d.", code);
          completionHandler(YES);
          return;
        }
        if (code < 500) {
            // non-429 4xx response codes. Don't retry.
            PDLog(@"Server rejected payload with HTTP code %d.", code);
            completionHandler(NO);
            return;
        }

        // 5xx response codes. Retry.
        PDLog(@"Server error with HTTP code %d.", code);
        completionHandler(YES);
    }];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)settingsForWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL success, JSON_DICT _Nullable settings))completionHandler
{
    NSURLSession *session = self.genericSession;

    NSURL *url = [[NSURL URLWithString:self.url] URLByAppendingPathComponent:[NSString stringWithFormat:@"/projects/%@/settings", writeKey]];
    NSMutableURLRequest *request = self.requestFactory(url);
    [request setHTTPMethod:@"GET"];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error != nil) {
            PDLog(@"Error fetching settings %@.", error);
            completionHandler(NO, nil);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code > 300) {
            PDLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(NO, nil);
            return;
        }

        NSError *jsonError = nil;
        id responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            PDLog(@"Error deserializing response body %@.", jsonError);
            completionHandler(NO, nil);
            return;
        }

        completionHandler(YES, nil);
    }];
    [task resume];
    return task;
}

@end
