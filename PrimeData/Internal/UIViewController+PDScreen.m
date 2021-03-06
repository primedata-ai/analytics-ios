#import "UIViewController+PDScreen.h"
#import <objc/runtime.h>
#import "PDAnalytics.h"
#import "PDAnalyticsUtils.h"
#import "PDScreenReporting.h"


#if TARGET_OS_IPHONE
@implementation UIViewController (PDScreen)

+ (void)seg_swizzleViewDidAppear
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(seg_viewDidAppear:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


+ (UIViewController *)seg_rootViewControllerFromView:(UIView *)view
{
    UIViewController *root = view.window.rootViewController;
    return [self seg_topViewController:root];
}

+ (UIViewController *)seg_topViewController:(UIViewController *)rootViewController
{
    UIViewController *nextRootViewController = [self seg_nextRootViewController:rootViewController];
    if (nextRootViewController) {
        return [self seg_topViewController:nextRootViewController];
    }

    return rootViewController;
}

+ (UIViewController *)seg_nextRootViewController:(UIViewController *)rootViewController
{
    UIViewController *presentedViewController = rootViewController.presentedViewController;
    if (presentedViewController != nil) {
        return presentedViewController;
    }

    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *lastViewController = ((UINavigationController *)rootViewController).viewControllers.lastObject;
        return lastViewController;
    }

    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        __auto_type *currentTabViewController = ((UITabBarController*)rootViewController).selectedViewController;
        if (currentTabViewController != nil) {
            return currentTabViewController;
        }
    }

    if (rootViewController.childViewControllers.count > 0) {
        if ([rootViewController conformsToProtocol:@protocol(PDScreenReporting)] && [rootViewController respondsToSelector:@selector(seg_mainViewController)]) {
            __auto_type screenReporting = (UIViewController<PDScreenReporting>*)rootViewController;
            return screenReporting.seg_mainViewController;
        }

        // fall back on first child UIViewController as a "best guess" assumption
        __auto_type *firstChildViewController = rootViewController.childViewControllers.firstObject;
        if (firstChildViewController != nil) {
            return firstChildViewController;
        }
    }

    return nil;
}

- (void)seg_viewDidAppear:(BOOL)animated
{
    UIViewController *top = [[self class] seg_rootViewControllerFromView:self.view];
    if (!top) {
        PDLog(@"Could not infer screen.");
        return;
    }

    NSString *name = [[[top class] description] stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
    
    if (!name || name.length == 0) {
        // if no class description found, try view controller's title.
        name = [top title];
        // Class name could be just "ViewController".
        if (name.length == 0) {
            PDLog(@"Could not infer screen name.");
            name = @"Unknown";
        }
    }

    if ([top conformsToProtocol:@protocol(PDScreenReporting)] && [top respondsToSelector:@selector(seg_trackScreen:name:)]) {
        __auto_type screenReporting = (UIViewController<PDScreenReporting>*)top;
        [screenReporting seg_trackScreen:top name:name];
        return;
    }

    [[PDAnalytics sharedAnalytics] screen:name properties:nil options:nil];

    [self seg_viewDidAppear:animated];
}

@end
#endif
