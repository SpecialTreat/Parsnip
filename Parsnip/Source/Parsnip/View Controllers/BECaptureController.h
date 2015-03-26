//
//  BECaptureController.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>

#import "BEBaseController.h"
#import "BEPopoverController.h"


@interface BECaptureController: BEBaseController<UINavigationControllerDelegate,
                                                       UIImagePickerControllerDelegate,
                                                       UIPopoverControllerDelegate>

@property (nonatomic, strong) UIPopoverController *popover;

- (void)popoverControllerDidDismissPopover:(BEPopoverController *)popoverController;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;

@end
