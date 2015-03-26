//
//  BEUI.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>

#import "JASidePanelController.h"
#import "BEAppDelegate.h"
#import "VSTheme.h"


@interface BEUI : NSObject

+ (BOOL)debug;
+ (VSTheme *)theme;
+ (BOOL)isStatusBarTranslucent;
+ (UIStatusBarStyle)preferredStatusBarStyle;

+ (void)styleApp:(BEAppDelegate *)app;
+ (void)styleStatusBar;
+ (UIButton *)styleButton:(UIButton *)button withKey:(id)key;
+ (UILabel *)styleLabel:(UILabel *)label withKey:(id)key;
+ (UINavigationBar *)styleNavigationBar:(UINavigationBar *)navigationBar;
+ (UILabel *)styleNavigationBarTitleView:(UILabel *)titleView;

+ (UILabel *)labelWithKey:(id)key;
+ (UIButton *)buttonWithKey:(id)key target:(id)target action:(SEL)selector;
+ (UIBarButtonItem *)barButtonItemWithKey:(id)key target:(id)target action:(SEL)selector;

+ (void)frontload;

@end
