#import <UIKit/UIKit.h>

#import "PreenBaseController.h"
#import "PreenPopoverController.h"


@interface PreenCaptureController: PreenBaseController<UINavigationControllerDelegate,
                                                       UIImagePickerControllerDelegate,
                                                       UIPopoverControllerDelegate>

@property (nonatomic, strong) UIPopoverController *popover;

- (void)popoverControllerDidDismissPopover:(PreenPopoverController *)popoverController;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;

@end
