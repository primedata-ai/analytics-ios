#import <Foundation/Foundation.h>
#import "PDIntegration.h"
#import "PDHTTPClient.h"
#import "PDStorage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PDSegmentDidSendRequestNotification;
extern NSString *const PDSegmentRequestDidSucceedNotification;
extern NSString *const PDSegmentRequestDidFailNotification;

/**
 * Filenames of "Application Support" files where essential data is stored.
 */
extern NSString *const kPDUserIdFilename;
extern NSString *const kPDQueueFilename;
extern NSString *const kPDTraitsFilename;


NS_SWIFT_NAME(SegmentIntegration)
@interface PDSegmentIntegration : NSObject <PDIntegration>

- (id)initWithAnalytics:(PDAnalytics *)analytics httpClient:(PDHTTPClient *)httpClient fileStorage:(id<PDStorage>)fileStorage userDefaultsStorage:(id<PDStorage>)userDefaultsStorage;

@end

NS_ASSUME_NONNULL_END
