#import "BEBaseController.h"

#import "BEAppDelegate.h"
#import "BENavigationController.h"
#import "BEUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIDevice+Tools.h"
#import "UIImage+Drawing.h"
#import "UIView+Tools.h"


const CGFloat FLASH_ANIMATION_DURATION = 1.0f;


@implementation BEBaseController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        flashAnimationDuration = FLASH_ANIMATION_DURATION;

        if (!UIDevice.isIOS7 && self.preferredStatusBarStyle == UIStatusBarStyleBlackTranslucent) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onStatusBarFrameChanged:)
                                                         name:UIApplicationWillChangeStatusBarFrameNotification
                                                       object:nil];
        }
    }
    return self;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch(orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            return [UIApplication sharedApplication].statusBarOrientation;
            break;

        case UIDeviceOrientationLandscapeLeft:
            return UIInterfaceOrientationLandscapeRight;
            break;

        case UIDeviceOrientationLandscapeRight:
            return UIInterfaceOrientationLandscapeLeft;
            break;

        default:
            return UIInterfaceOrientationPortrait;
            break;
    }
}

- (void)onStatusBarFrameChanged:(NSNotification *)note
{
    if (!self.navigationController || (self.navigationController && self.navigationController.topViewController == self)) {
        [self viewWillLayoutSubviews];
        [self viewDidLayoutSubviews];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return BEUI.preferredStatusBarStyle;
}

- (BOOL)wantsFullScreenLayout
{
    BOOL statusBarHidden = NO;
    BOOL statusBarTranslucent = NO;
    BOOL navigationBarHidden = YES;
    BOOL navigationBarTranslucent = NO;

    if ([self respondsToSelector:@selector(prefersStatusBarHidden)]) {
        statusBarHidden = [self prefersStatusBarHidden];
    } else {
        statusBarHidden = NO;
    }

    if (UIDevice.isIOS7 || [UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleBlackTranslucent) {
        statusBarTranslucent = YES;
    }

    if (self.navigationController) {
        navigationBarHidden = self.navigationController.isNavigationBarHidden;
        navigationBarTranslucent = !self.navigationController.navigationBar.opaque;
    }

    BOOL fullscreen = (navigationBarHidden || navigationBarTranslucent) && (!statusBarHidden && statusBarTranslucent);
    return fullscreen;
}

- (UIView *)containerView
{
    if(self.navigationController) {
        return self.navigationController.view;
    } else {
        return self.view;
    }
}

- (void)hideFlash
{
    [self hideFlash:NO completion:nil];
}

- (void)hideFlash:(BOOL)animate completion:(void(^)(BOOL finished))completion
{
    if(animate) {
        [self hideView:flash animate:flashAnimationDuration completion:completion];
    } else {
        [self hideView:flash animate:0.0f completion:completion];
    }
    flash = nil;
}

- (void)showFlash
{
    [self showFlash:NO completion:nil];
}

- (void)showFlash:(BOOL)animate completion:(void(^)(BOOL finished))completion
{
    flash = [[UIView alloc] initWithFrame:self.containerView.bounds];
    flash.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    flash.backgroundColor = [UIColor whiteColor];
    flash.hidden = YES;
    [self.containerView addSubview:flash];
    if(animate) {
        [self showView:flash animate:flashAnimationDuration completion:completion];
    } else {
        [self showView:flash animate:0.0f completion:completion];
    }
}

- (void)hideView:(UIView *)view
{
    [self hideView:view animate:0.0f completion:nil];
}

- (void)hideView:(UIView *)view animate:(CGFloat)duration completion:(void(^)(BOOL finished))completion
{
    if(!view) {
        if(completion) {
            completion(YES);
        }
    } else if(duration > 0.0f) {
        [UIView animateWithDuration:duration animations:^{
            view.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
            if(completion) {
                completion(finished);
            }
        }];
    } else {
        [view removeFromSuperview];
        if(completion) {
            completion(YES);
        }
    }
}

- (void)showView:(UIView *)view
{
    [self showView:view animate:0.0f completion:nil];
}

- (void)showView:(UIView *)view animate:(CGFloat)duration completion:(void(^)(BOOL finished))completion
{
    if(duration > 0.0f) {
        view.alpha = 0.0f;
        view.hidden = NO;
        [UIView animateWithDuration:duration animations:^{
            view.alpha = 1.0f;
        } completion:^(BOOL finished) {
            if(completion) {
                completion(finished);
            }
        }];
    } else {
        view.hidden = NO;
        if(completion) {
            completion(YES);
        }
    }
}

- (void)popToRoot
{
    BEAppDelegate *appDelegate = (BEAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.sidePanelController showCenterPanelAnimated:NO];
    if (appDelegate.window.rootViewController == self.navigationController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)presentNavigableViewController:(UIViewController *)viewController
{
    return [self presentNavigableViewController:viewController animated:NO completion:nil];
}

- (void)presentNavigableViewController:(UIViewController *)viewController
                              animated:(BOOL)flag
                            completion:(void (^)())completion
{
    return [self presentNavigableViewController:viewController navigationBarClipsToBounds:YES animated:flag completion:completion];
}

- (void)presentNavigableViewController:(UIViewController *)viewController
            navigationBarClipsToBounds:(BOOL)navigationBarClipsToBounds
                              animated:(BOOL)flag
                            completion:(void (^)())completion
{
    BENavigationController *navigationController = [[BENavigationController alloc] initWithRootViewController:viewController];
    [BEUI styleNavigationBar:navigationController.navigationBar];
    [self presentViewController:navigationController animated:flag completion:completion];
}

@end
