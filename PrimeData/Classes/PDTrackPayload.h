#import <Foundation/Foundation.h>
#import "PDPayload.h"

NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(TrackPayload)
@interface PDTrackPayload : PDPayload

@property (nonatomic, readonly) NSString *event;

@property (nonatomic, readonly, nullable) NSDictionary *properties;

- (instancetype)initWithEvent:(NSString *)event
                   properties:(JSON_DICT)properties
                       source:(JSON_DICT)source
                       target:(JSON_DICT)target
                      context:(JSON_DICT)context
                 integrations:(JSON_DICT)integrations;

@end

NS_ASSUME_NONNULL_END
