//
//  BEAppDelegate.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>
#import "JASidePanelController.h"


@interface BEAppDelegate : UIResponder <UIApplicationDelegate>

+ (UIViewController *)topController;
+ (UINavigationController *)topNavigationController;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) JASidePanelController *sidePanelController;

@end
