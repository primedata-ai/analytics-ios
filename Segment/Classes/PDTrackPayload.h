#import <Foundation/Foundation.h>
#import "PDPayload.h"

NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(TrackPayload)
@interface PDTrackPayload : PDPayload

@property (nonatomic, readonly) NSString *event;

@property (nonatomic, readonly, nullable) NSDictionary *properties;

- (instancetype)initWithEvent:(NSString *)event
                   properties:(NSDictionary *_Nullable)properties
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations;

@end

NS_ASSUME_NONNULL_END
