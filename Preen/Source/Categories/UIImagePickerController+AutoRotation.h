#import <UIKit/UIKit.h>


@interface UIImagePickerController (AutoRotation)

- (BOOL)shouldAutorotate;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (NSUInteger)supportedInterfaceOrientations;
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;

@end
