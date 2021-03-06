//
//  PDCrypto.h
//  Analytics
//
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PDCrypto <NSObject>

- (NSData *_Nullable)encrypt:(NSData *_Nonnull)data;
- (NSData *_Nullable)decrypt:(NSData *_Nonnull)data;

@end
