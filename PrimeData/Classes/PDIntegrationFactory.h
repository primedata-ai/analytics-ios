#import <Foundation/Foundation.h>
#import "PDIntegration.h"
#import "PDAnalytics.h"

NS_ASSUME_NONNULL_BEGIN

@class PDAnalytics;

@protocol PDIntegrationFactory

/**
 * Attempts to create an adapter with the given settings. Returns the adapter if one was created, or null
 * if this factory isn't capable of creating such an adapter.
 */
- (id<PDIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(PDAnalytics *)analytics;

/** The key for which this factory can create an Integration. */
- (NSString *)key;

@end

NS_ASSUME_NONNULL_END
