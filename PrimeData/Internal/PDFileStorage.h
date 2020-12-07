//
//  PDFileStorage.h
//  Analytics
//
//  Copyright © 2016 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDStorage.h"


NS_SWIFT_NAME(FileStorage)
@interface PDFileStorage : NSObject <PDStorage>

@property (nonatomic, strong, nullable) id<PDCrypto> crypto;

- (instancetype _Nonnull)initWithFolder:(NSURL *_Nonnull)folderURL crypto:(id<PDCrypto> _Nullable)crypto;

- (NSURL *_Nonnull)urlForKey:(NSString *_Nonnull)key;

+ (NSURL *_Nullable)applicationSupportDirectoryURL;
+ (NSURL *_Nullable)cachesDirectoryURL;

@end
