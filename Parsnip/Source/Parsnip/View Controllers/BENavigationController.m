#import "BENavigationController.h"


@implementation BENavigationController

- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([self.topViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.topViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    } else {
        return [self shouldAutorotate];
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

@end
