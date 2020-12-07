#import <Foundation/Foundation.h>
#import "PDIntegration.h"
#import "PDHTTPClient.h"
#import "PDStorage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PDPrimeDataDidSendRequestNotification;
extern NSString *const PDPrimeDataRequestDidSucceedNotification;
extern NSString *const PDPrimeDataRequestDidFailNotification;

/**
 * Filenames of "Application Support" files where essential data is stored.
 */
extern NSString *const kPDUserIdFilename;
extern NSString *const kPDQueueFilename;
extern NSString *const kPDTraitsFilename;


NS_SWIFT_NAME(PrimeDataIntegration)
@interface PDPrimeDataIntegration : NSObject <PDIntegration>

- (id)initWithAnalytics:(PDAnalytics *)analytics httpClient:(PDHTTPClient *)httpClient fileStorage:(id<PDStorage>)fileStorage userDefaultsStorage:(id<PDStorage>)userDefaultsStorage;

@end

NS_ASSUME_NONNULL_END
