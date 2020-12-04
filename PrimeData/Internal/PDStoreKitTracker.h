#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "PDAnalytics.h"

NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(StoreKitTracker)
@interface PDStoreKitTracker : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

+ (instancetype)trackTransactionsForAnalytics:(PDAnalytics *)analytics;

@end

NS_ASSUME_NONNULL_END
