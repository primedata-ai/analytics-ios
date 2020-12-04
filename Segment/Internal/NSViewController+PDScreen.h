//
//  NSViewController+PDScreen.h
//  Analytics
//
//  Created by Cody Garvin on 7/8/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import "PDSerializableValue.h"

#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>

@interface NSViewController (PDScreen)

+ (void)seg_swizzleViewDidAppear;
+ (NSViewController *)seg_rootViewControllerFromView:(NSView *)view;

@end

#endif
