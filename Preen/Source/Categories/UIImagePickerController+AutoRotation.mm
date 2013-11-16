#import "UIImagePickerController+AutoRotation.h"


@implementation UIImagePickerController (AutoRotation)

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
    if (self.topViewController && [self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.topViewController supportedInterfaceOrientations];
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (self.topViewController && [self.topViewController respondsToSelector:@selector(preferredInterfaceOrientationForPresentation)]) {
        return [self.topViewController preferredInterfaceOrientationForPresentation];
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

@end
