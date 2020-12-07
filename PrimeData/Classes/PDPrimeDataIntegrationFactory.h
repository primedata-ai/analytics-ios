#import <Foundation/Foundation.h>
#import "PDIntegrationFactory.h"
#import "PDHTTPClient.h"
#import "PDStorage.h"

NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(PrimeDataIntegrationFactory)
@interface PDPrimeDataIntegrationFactory : NSObject <PDIntegrationFactory>

@property (nonatomic, strong) PDHTTPClient *client;
@property (nonatomic, strong) id<PDStorage> userDefaultsStorage;
@property (nonatomic, strong) id<PDStorage> fileStorage;

- (instancetype)initWithHTTPClient:(PDHTTPClient *)client fileStorage:(id<PDStorage>)fileStorage userDefaultsStorage:(id<PDStorage>)userDefaultsStorage;

@end

NS_ASSUME_NONNULL_END
