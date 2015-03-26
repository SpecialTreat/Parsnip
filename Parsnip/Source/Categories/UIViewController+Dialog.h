//
//  UIViewController+Dialog.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface UIViewController (Dialog)

- (void)updateLeftBarButtonItemWithCancel:(BOOL)animated;
- (void)onLeftBarButtonItemTouch;

@end
