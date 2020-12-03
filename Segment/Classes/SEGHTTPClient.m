#import "SEGHTTPClient.h"
#import "NSData+SEGGZIP.h"
#import "SEGAnalyticsUtils.h"

static const NSUInteger kMaxBatchSize = 475000; // 475KB

@implementation SEGHTTPClient

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


- (instancetype)initWithRequestFactory:(SEGRequestFactory)requestFactory
{
    if (self = [self init]) {
        if (requestFactory == nil) {
            self.requestFactory = [SEGHTTPClient defaultRequestFactory];
        } else {
            self.requestFactory = requestFactory;
        }
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

- (nullable NSURLSessionUploadTask *)upload:(NSDictionary *)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler
{
    NSDictionary *body_init =
    @{
      @"source": @{
          @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
          @"itemId": @"home",
          @"itemType": @"screen",
          @"properties": @{
              @"screen_width": @"1024",
              @"screen_height": @"2048",
              @"connection_type": @"iOS-Intel",
              @"device_id": @"0000.0000.0000.0000",
          }
      },
      @"sendAt": [batch objectForKey:@"sentAt"],
      @"events": @[@{
              @"eventType": @"search_by_cscid",
              @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
              @"timeStamp": [batch objectForKey:@"sentAt"],
              @"target": @{
                  @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
                  @"itemId": @"home",
                  @"itemType": @"screen"
              },
              @"source": @{
                  @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
                  @"itemId": @"home",
                  @"itemType": @"screen"
              }
          },
      ],
      
      @"sessionId": @"257eb9a0-352b-11eb-8ae6-53f6a0677ce9"
    };
    
    NSDictionary *body_track =
    @{
      @"events": @[
          @{
              @"eventType": @"ccccccc",
              @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
              @"timeStamp": [batch objectForKey:@"sentAt"],
              @"target": @{
                  @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
                  @"itemId": @"cscid",
                  @"itemType": @"search_by_cscid",
                  @"properties": @{
                      @"value": @"aaa",
                  }
              },
              @"source": @{
                  @"scope": @"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD",
                  @"itemId": @"home",
                  @"itemType": @"screen",
                  @"properties": @{
                      @"screenInfo": @{
                          @"screenName": @"Home",
                          @"screenPath": @"Home"
                      },
                      @"attributes": @[],
                      @"consentTypes": @[],
                      @"interests": @{}
                  }
              },
              @"properties": @{}
          }
      ],
      
      @"sessionId": @"257eb9a0-352b-11eb-8ae6-53f6a0677ce9"
    };
    
    batch = body_track;
    //    batch = SEGCoerceDictionary(batch);
    NSURLSession *session = [self sessionForWriteKey:writeKey];

    NSURL *url = [SEGMENT_API_BASE URLByAppendingPathComponent:@"smile"];
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
    
//    if (error || exception) {
//        SEGLog(@"Error serializing JSON for batch upload %@", error);
//        completionHandler(NO); // Don't retry this batch.
//        return nil;
//    }
//    if (payload.length >= kMaxBatchSize) {
//        SEGLog(@"Payload exceeded the limit of %luKB per batch", kMaxBatchSize / 1000);
//        completionHandler(NO);
//        return nil;
//    }
    
    NSData *gzippedPayload = payload;

    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:gzippedPayload completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            // Network error. Retry.
            SEGLog(@"Error uploading request %@.", error);
            completionHandler(YES);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code < 300) {
            // 2xx response codes. Don't retry.
            completionHandler(NO);
            return;
        }
        if (code < 400) {
            // 3xx response codes. Retry.
            SEGLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(YES);
            return;
        }
        if (code == 429) {
          // 429 response codes. Retry.
          SEGLog(@"Server limited client with response code %d.", code);
          completionHandler(YES);
          return;
        }
        if (code < 500) {
            // non-429 4xx response codes. Don't retry.
            SEGLog(@"Server rejected payload with HTTP code %d.", code);
            completionHandler(NO);
            return;
        }

        // 5xx response codes. Retry.
        SEGLog(@"Server error with HTTP code %d.", code);
        completionHandler(YES);
    }];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)settingsForWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL success, JSON_DICT _Nullable settings))completionHandler
{
    NSURLSession *session = self.genericSession;

    NSURL *url = [SEGMENT_API_BASE URLByAppendingPathComponent:[NSString stringWithFormat:@"/projects/%@/settings", writeKey]];
    NSMutableURLRequest *request = self.requestFactory(url);
    [request setHTTPMethod:@"GET"];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error != nil) {
            SEGLog(@"Error fetching settings %@.", error);
            completionHandler(NO, nil);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code > 300) {
            SEGLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(NO, nil);
            return;
        }

        NSError *jsonError = nil;
        id responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            SEGLog(@"Error deserializing response body %@.", jsonError);
            completionHandler(NO, nil);
            return;
        }

        completionHandler(YES, nil);
    }];
    [task resume];
    return task;
}

@end
