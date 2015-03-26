//
//  UIViewController+Dialog.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "UIViewController+Dialog.h"

#import "BeUI.h"


@implementation UIViewController (Dialog)

- (void)updateLeftBarButtonItemWithCancel:(BOOL)animated
{
    if(!self.navigationController || [self isEqual:self.navigationController.viewControllers[0]]) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onLeftBarButtonItemTouch)];
        [self.navigationItem setLeftBarButtonItem:button animated:animated];
    }
}

- (void)onLeftBarButtonItemTouch
{
    if(!self.navigationController || [self isEqual:self.navigationController.viewControllers[0]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
