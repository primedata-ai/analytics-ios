//
//  PDAES256Crypto.h
//  Analytics
//
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDCrypto.h"


NS_SWIFT_NAME(AES256Crypto)
@interface PDAES256Crypto : NSObject <PDCrypto>

@property (nonatomic, readonly, nonnull) NSString *password;
@property (nonatomic, readonly, nonnull) NSData *salt;
@property (nonatomic, readonly, nonnull) NSData *iv;

- (instancetype _Nonnull)initWithPassword:(NSString *_Nonnull)password salt:(NSData *_Nonnull)salt iv:(NSData *_Nonnull)iv;
// Convenient shorthand. Will randomly generate salt and iv.
- (instancetype _Nonnull)initWithPassword:(NSString *_Nonnull)password;

+ (NSData *_Nonnull)randomDataOfLength:(size_t)length;

@end
