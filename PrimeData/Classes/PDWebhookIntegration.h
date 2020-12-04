#import "PDIntegration.h"
#import "PDIntegrationFactory.h"
#import "PDHTTPClient.h"

NS_ASSUME_NONNULL_BEGIN
NS_SWIFT_NAME(WebhookIntegrationFactory)
@interface PDWebhookIntegrationFactory : NSObject <PDIntegrationFactory>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *webhookUrl;

- (instancetype)initWithName:(NSString *)name webhookUrl:(NSString *)webhookUrl;

@end

NS_ASSUME_NONNULL_END