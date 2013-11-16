#import <UIKit/UIKit.h>


@interface PreenBaseController : UIViewController
{
    @protected
    UIView *flash;
    CGFloat flashAnimationDuration;
}

@property (nonatomic, readonly) UIView *containerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (void)hideFlash;
- (void)hideFlash:(BOOL)animate completion:(void(^)(BOOL finished))completion;
- (void)showFlash;
- (void)showFlash:(BOOL)animate completion:(void(^)(BOOL finished))completion;

- (void)hideView:(UIView *)view;
- (void)hideView:(UIView *)view animate:(CGFloat)duration completion:(void(^)(BOOL finished))completion;
- (void)showView:(UIView *)view;
- (void)showView:(UIView *)view animate:(CGFloat)duration completion:(void(^)(BOOL finished))completion;

- (void)popToRoot;

- (void)presentNavigableViewController:(UIViewController *)viewController;
- (void)presentNavigableViewController:(UIViewController *)viewController
                              animated:(BOOL)flag
                            completion:(void (^)())completion;
- (void)presentNavigableViewController:(UIViewController *)viewController
            navigationBarClipsToBounds:(BOOL)navigationBarClipsToBounds
                              animated:(BOOL)flag
                            completion:(void (^)())completion;

@end
