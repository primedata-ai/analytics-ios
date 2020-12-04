//
//  NSData+PDGUNZIPP.h
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//
// https://github.com/nicklockwood/GZIP/blob/master/GZIP/NSData%2BGZIP.m

#import <Foundation/Foundation.h>


@interface NSData (PDGUNZIPP)

- (NSData *_Nullable)seg_gunzippedData;

@end
