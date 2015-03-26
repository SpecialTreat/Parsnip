//
//  UIImagePickerController+AutoRotation.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface UIImagePickerController (AutoRotation)

- (BOOL)shouldAutorotate;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (NSUInteger)supportedInterfaceOrientations;
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;

@end
