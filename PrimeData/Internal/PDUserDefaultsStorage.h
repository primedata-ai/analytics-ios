//
//  PDUserDefaultsStorage.h
//  Analytics
//
//  Created by Tony Xiao on 8/24/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDStorage.h"


NS_SWIFT_NAME(UserDefaultsStorage)
@interface PDUserDefaultsStorage : NSObject <PDStorage>

@property (nonatomic, strong, nullable) id<PDCrypto> crypto;
@property (nonnull, nonatomic, readonly) NSUserDefaults *defaults;
@property (nullable, nonatomic, readonly) NSString *namespacePrefix;

- (instancetype _Nonnull)initWithDefaults:(NSUserDefaults *_Nonnull)defaults namespacePrefix:(NSString *_Nullable)namespacePrefix crypto:(id<PDCrypto> _Nullable)crypto;

@end
