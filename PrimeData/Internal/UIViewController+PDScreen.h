#import "PDSerializableValue.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@interface UIViewController (PDScreen)

+ (void)seg_swizzleViewDidAppear;
+ (UIViewController *)seg_rootViewControllerFromView:(UIView *)view;

@end

#endif
