#import "UIViewController+Tools.h"

#import "BEDevice.h"
#import "BEUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIDevice+Tools.h"


@implementation UIViewController (Tools)

- (void)setRightBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UIBarButtonItem* spacer = [UIBarButtonItem spacer:[BEUI.theme floatForKey:@"NavigationBarButton.RightSpacer"]];
    self.navigationItem.rightBarButtonItems = @[spacer, barButtonItem];
}

- (BOOL)manuallyAdjustsViewInsets
{
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        return !self.automaticallyAdjustsScrollViewInsets;
    } else {
        return YES;
    }
}

- (void)setManuallyAdjustsViewInsets:(BOOL)manual
{
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = !manual;
    }
}

- (CGFloat)statusBarHeight
{
    CGFloat statusBarWidth = [UIApplication sharedApplication].statusBarFrame.size.width;
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (statusBarWidth < statusBarHeight) {
        statusBarHeight = statusBarWidth;
    }
    if (!statusBarHeight) {
        statusBarHeight = 20.0f;
    }
    return statusBarHeight;
}

- (CGRect)boundsForView
{
    CGRect bounds = self.frameForView;
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    return bounds;
}

- (CGRect)boundsForViewStatusBarHidden:(BOOL)statusBarHidden
{
    CGRect bounds = [self frameForViewStatusBarHidden:statusBarHidden];
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    return bounds;
}

- (CGRect)boundsForViewNavigationBarHidden:(BOOL)navigationBarHidden statusBarHidden:(BOOL)statusBarHidden
{
    CGRect bounds = [self frameForViewNavigationBarHidden:navigationBarHidden statusBarHidden:statusBarHidden];
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    return bounds;
}

- (CGRect)frameForView
{
    BOOL statusBarHidden = NO;
    if ([self respondsToSelector:@selector(prefersStatusBarHidden)]) {
        statusBarHidden = [self prefersStatusBarHidden];
    } else {
        statusBarHidden = NO;
    }
    return [self frameForViewStatusBarHidden:statusBarHidden];
}

- (CGRect)frameForViewStatusBarHidden:(BOOL)statusBarHidden
{
    BOOL navigationBarHidden = YES;
    if (self.navigationController) {
        navigationBarHidden = self.navigationController.isNavigationBarHidden;
    }
    return [self frameForViewNavigationBarHidden:navigationBarHidden statusBarHidden:statusBarHidden];
}

- (CGRect)frameForViewNavigationBarHidden:(BOOL)navigationBarHidden statusBarHidden:(BOOL)statusBarHidden
{
    BOOL statusBarTranslucent = NO;
    BOOL navigationBarTranslucent = NO;
    BOOL toolBarHidden = YES;
    BOOL toolBarTranslucent = NO;
    BOOL tabBarHidden = YES;
    BOOL tabBarTranslucent = NO;

    CGFloat statusBarHeight = self.statusBarHeight;

    if (UIDevice.isIOS7) {
        statusBarTranslucent = YES;
    } else {
        statusBarTranslucent = [UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleBlackTranslucent;
    }

    if (self.navigationController) {
        navigationBarTranslucent = !self.navigationController.navigationBar.opaque;
        toolBarHidden = self.navigationController.isToolbarHidden;
        toolBarTranslucent = !self.navigationController.toolbar.opaque;
    }

    if (self.tabBarController) {
        tabBarHidden = self.tabBarController.tabBar.isHidden;
        tabBarTranslucent = !self.tabBarController.tabBar.opaque;
    }

    CGRect screenFrame = [UIScreen mainScreen].bounds;
    BOOL rotate = NO;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        if (screenFrame.size.width < screenFrame.size.height) {
            rotate = YES;
        }
    }
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        if (screenFrame.size.width > screenFrame.size.height) {
            rotate = YES;
        }
    }

    if (rotate) {
        CGFloat tmp = screenFrame.size.height;
        screenFrame.size.height = screenFrame.size.width;
        screenFrame.size.width = tmp;
    }

    CGRect frame = screenFrame;
    if (!statusBarHidden) {
        CGFloat statusBarInset = (UIDevice.isIOS7)? MIN(20.0f, statusBarHeight): statusBarHeight;
        frame.origin.y += statusBarInset;
        if (!statusBarTranslucent) {
            frame.size.height -= statusBarHeight;
        }
    }
    if (!navigationBarHidden) {
        frame.origin.y += self.navigationController.navigationBar.frame.size.height;
        if (!navigationBarTranslucent) {
            frame.size.height -= self.navigationController.navigationBar.frame.size.height;
        }
    }
    if (!tabBarHidden && !tabBarTranslucent) {
        frame.size.height -= self.tabBarController.tabBar.frame.size.height;
    }
    if (!toolBarHidden && !toolBarTranslucent) {
        frame.size.height -= self.navigationController.toolbar.frame.size.height;
    }
    
    return frame;
}

- (UIEdgeInsets)insetsForView
{
    BOOL statusBarHidden = NO;
    if ([self respondsToSelector:@selector(prefersStatusBarHidden)]) {
        statusBarHidden = [self prefersStatusBarHidden];
    } else {
        statusBarHidden = NO;
    }
    return [self insetsForViewStatusBarHidden:statusBarHidden];
}

- (UIEdgeInsets)insetsForViewStatusBarHidden:(BOOL)statusBarHidden
{
    BOOL navigationBarHidden = YES;
    if (self.navigationController) {
        navigationBarHidden = self.navigationController.isNavigationBarHidden;
    }
    return [self insetsForViewNavigationBarHidden:navigationBarHidden statusBarHidden:statusBarHidden];
}

- (UIEdgeInsets)insetsForViewNavigationBarHidden:(BOOL)navigationBarHidden statusBarHidden:(BOOL)statusBarHidden
{
    BOOL statusBarTranslucent = NO;
    BOOL navigationBarTranslucent = NO;
    BOOL toolBarHidden = YES;
    BOOL toolBarTranslucent = NO;
    BOOL tabBarHidden = YES;
    BOOL tabBarTranslucent = NO;

    CGFloat statusBarHeight = self.statusBarHeight;

    if (UIDevice.isIOS7) {
        statusBarTranslucent = YES;
    } else {
        statusBarTranslucent = [UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleBlackTranslucent;
    }

    if (self.navigationController) {
        navigationBarTranslucent = !self.navigationController.navigationBar.opaque;
        toolBarHidden = self.navigationController.isToolbarHidden;
        toolBarTranslucent = !self.navigationController.toolbar.opaque;
    }

    if (self.tabBarController) {
        tabBarHidden = self.tabBarController.tabBar.isHidden;
        tabBarTranslucent = !self.tabBarController.tabBar.opaque;
    }

    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);

    if (!navigationBarHidden && navigationBarTranslucent) {
        insets.top += self.navigationController.navigationBar.frame.size.height;
    }

    if (navigationBarHidden || navigationBarTranslucent) {
        if (!statusBarHidden && statusBarTranslucent) {
            insets.top += (UIDevice.isIOS7)? MIN(20.0f, statusBarHeight): statusBarHeight;
        }
    }

    if (!tabBarHidden && tabBarTranslucent) {
        insets.bottom += self.tabBarController.tabBar.frame.size.height;
    }
    
    if (!toolBarHidden && toolBarTranslucent) {
        insets.bottom += self.navigationController.toolbar.frame.size.height;
    }

    return insets;
}

- (UIScrollView *)topScrollView
{
    return [self findScrollView:self.view depth:0];
}

- (UIScrollView *)findScrollView:(UIView *)view depth:(NSUInteger)depth
{
    NSUInteger MAX_DEPTH = 2;
    if ([view isKindOfClass:UIScrollView.class]) {
        return (UIScrollView *)view;
    }
    if (depth <= MAX_DEPTH && view.subviews.count == 1) {
        return [self findScrollView:view.subviews[0] depth:depth + 1];
    }
    return nil;
}

@end
