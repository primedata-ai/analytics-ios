//
//  PDUtils.h
//
//

#import <Foundation/Foundation.h>
#import "PDAnalyticsUtils.h"
#import "PDSerializableValue.h"

NS_ASSUME_NONNULL_BEGIN

@class PDAnalyticsConfiguration;
@class PDReachability;

NS_SWIFT_NAME(Utilities)
@interface PDUtils : NSObject

+ (NSData *_Nullable)dataFromPlist:(nonnull id)plist;
+ (id _Nullable)plistFromData:(NSData *)data;

+ (id _Nullable)traverseJSON:(id _Nullable)object andReplaceWithFilters:(NSDictionary<NSString*, NSString*>*)patterns;

@end

BOOL isUnitTesting(void);

NSString * _Nullable deviceTokenToString(NSData * _Nullable deviceToken);
NSString *getDeviceModel(void);
BOOL getAdTrackingEnabled(PDAnalyticsConfiguration *configuration);
NSDictionary *getStaticContext(PDAnalyticsConfiguration *configuration, NSString * _Nullable deviceToken);
NSDictionary *getLiveContext(PDReachability *reachability, NSDictionary * _Nullable referrer, NSDictionary * _Nullable traits);

NSString *GenerateUUIDString(void);

#if TARGET_OS_IPHONE
NSDictionary *mobileSpecifications(PDAnalyticsConfiguration *configuration, NSString * _Nullable deviceToken);
#elif TARGET_OS_OSX
NSDictionary *desktopSpecifications(PDAnalyticsConfiguration *configuration, NSString * _Nullable deviceToken);
#endif

// Date Utils
NSString *iso8601FormattedString(NSDate *date);
NSString *iso8601NanoFormattedString(NSDate *date);

void trimQueue(NSMutableArray *array, NSUInteger size);

// Async Utils
dispatch_queue_t seg_dispatch_queue_create_specific(const char *label,
                                                    dispatch_queue_attr_t _Nullable attr);
BOOL seg_dispatch_is_on_specific_queue(dispatch_queue_t queue);
void seg_dispatch_specific(dispatch_queue_t queue, dispatch_block_t block,
                           BOOL waitForCompletion);
void seg_dispatch_specific_async(dispatch_queue_t queue,
                                 dispatch_block_t block);
void seg_dispatch_specific_sync(dispatch_queue_t queue, dispatch_block_t block);

// JSON Utils

JSON_DICT PDCoerceDictionary(NSDictionary *_Nullable dict);

NSString *_Nullable PDIDFA(void);

NSString *PDEventNameForScreenTitle(NSString *title);

@interface NSJSONSerialization (Serializable)
+ (BOOL)isOfSerializableType:(id)obj;
@end

// Deep copy and check NSCoding conformance
@protocol PDSerializableDeepCopy <NSObject>
-(id _Nullable) serializableMutableDeepCopy;
-(id _Nullable) serializableDeepCopy;
@end

@interface NSDictionary(SerializableDeepCopy) <PDSerializableDeepCopy>
@end

@interface NSArray(SerializableDeepCopy) <PDSerializableDeepCopy>
@end


NS_ASSUME_NONNULL_END
