#import "BESidePanel.h"

#import "JASidePanelController.h"
#import "UIViewController+JASidePanel.h"


@interface BESidePanel ()

@end


@implementation BESidePanel

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        statusBarHidden = YES;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return statusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    statusBarHidden = ([UIApplication sharedApplication].statusBarHidden ||
                       (self.sidePanelController.visiblePanel != self.navigationController));
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    statusBarHidden = YES;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    statusBarHidden = ([UIApplication sharedApplication].statusBarHidden ||
                       (self.sidePanelController.visiblePanel != self.navigationController));
}

@end
