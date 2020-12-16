#import <Foundation/Foundation.h>
#import "PDAnalytics.h"

#define PROFILE_ID_KEY @"RIME_DATA___profileId___"
// TODO: Make this configurable via PDAnalyticsConfiguration
// NOTE: `/` at the end kind of screws things up. So don't use it
NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(HTTPClient)
@interface PDHTTPClient : NSObject

@property (nonatomic, strong) PDRequestFactory requestFactory;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, NSURLSession *> *sessionsByWriteKey;
@property (nonatomic, readonly) NSURLSession *genericSession;
@property (nonatomic, weak)  id<NSURLSessionDelegate> httpSessionDelegate;
@property (nonatomic, copy, readwrite) NSString *url;

+ (PDRequestFactory)defaultRequestFactory;
+ (NSString *)authorizationHeader:(NSString *)writeKey;

- (instancetype)initWithRequestFactory:(PDRequestFactory _Nullable)requestFactory url:(NSString*)url;

/**
 * Upload dictionary formatted as per https://segment.com/docs/sources/server/http/#batch.
 * This method will convert the dictionary to json, gzip it and upload the data.
 * It will respond with retry = YES if the batch should be reuploaded at a later time.
 * It will ask to retry for json errors and 3xx/5xx codes, and not retry for 2xx/4xx response codes.
 * NOTE: You need to re-dispatch within the completionHandler onto a desired queue to avoid threading issues.
 * Completion handlers are called on a dispatch queue internal to PDHTTPClient. 
 */

- (nullable NSURLSessionUploadTask *)uploadEvents:(JSON_DICT)batch forWriteKey:(NSString *)writeKey scopeKey:(NSString *)scopeKey completionHandler:(void (^)(BOOL retry))completionHandler;

- (NSURLSessionDataTask *)settingsForWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL success, JSON_DICT _Nullable settings))completionHandler;

@end

NS_ASSUME_NONNULL_END
