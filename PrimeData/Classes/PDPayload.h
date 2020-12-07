#import <Foundation/Foundation.h>
#import "PDSerializableValue.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Payload)
@interface PDPayload : NSObject

@property (nonatomic, readonly) JSON_DICT context;
@property (nonatomic, readonly) JSON_DICT integrations;
@property (nonatomic, strong) NSString *timestamp;
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *anonymousId;
@property (nonatomic, strong) NSString *userId;

@property (nonatomic, readonly) JSON_DICT pd_properties;
@property (nonatomic, readonly) JSON_DICT pd_source;
@property (nonatomic, readonly) JSON_DICT pd_target;


- (instancetype)initWithContext:(JSON_DICT)context integrations:(JSON_DICT)integrations;
- (instancetype)initWithProperties:(JSON_DICT)properties source:(JSON_DICT)source target:(JSON_DICT)target context:(JSON_DICT)context integrations:(JSON_DICT)integrations;

@end


NS_SWIFT_NAME(ApplicationLifecyclePayload)
@interface PDApplicationLifecyclePayload : PDPayload

@property (nonatomic, strong) NSString *notificationName;

// ApplicationDidFinishLaunching only
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;

@end


NS_SWIFT_NAME(ContinueUserActivityPayload)
@interface PDContinueUserActivityPayload : PDPayload

@property (nonatomic, strong) NSUserActivity *activity;

@end

NS_SWIFT_NAME(OpenURLPayload)
@interface PDOpenURLPayload : PDPayload

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDictionary *options;

@end

NS_ASSUME_NONNULL_END


NS_SWIFT_NAME(RemoteNotificationPayload)
@interface PDRemoteNotificationPayload : PDPayload

// PDEventTypeHandleActionWithForRemoteNotification
@property (nonatomic, strong, nullable) NSString *actionIdentifier;

// PDEventTypeHandleActionWithForRemoteNotification
// PDEventTypeReceivedRemoteNotification
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

// PDEventTypeFailedToRegisterForRemoteNotifications
@property (nonatomic, strong, nullable) NSError *error;

// PDEventTypeRegisteredForRemoteNotifications
@property (nonatomic, strong, nullable) NSData *deviceToken;

@end

NS_SWIFT_NAME(InitializePayload)
@interface PDInitializePayload : PDPayload

@property (nonatomic, readonly, nullable) NSDictionary *internal_source;
@property (nonatomic, readonly, nonnull) NSString *event;

- (instancetype)initWithEvent:(NSString* )event properties:(JSON_DICT)properties source:(JSON_DICT)source target:(JSON_DICT)target context:(JSON_DICT)context integrations:(JSON_DICT)integrations;

@end
