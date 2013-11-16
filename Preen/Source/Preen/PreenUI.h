#import <UIKit/UIKit.h>

#import "JASidePanelController.h"
#import "PreenAppDelegate.h"
#import "VSTheme.h"


@interface PreenUI : NSObject

+ (BOOL)debug;
+ (VSTheme *)theme;
+ (BOOL)isStatusBarTranslucent;
+ (UIStatusBarStyle)preferredStatusBarStyle;

+ (void)styleApp:(PreenAppDelegate *)app;
+ (void)styleStatusBar;
+ (UIButton *)styleButton:(UIButton *)button withKey:(id)key;
+ (UINavigationBar *)styleNavigationBar:(UINavigationBar *)navigationBar;
+ (UILabel *)styleNavigationBarTitleView:(UILabel *)titleView;

+ (UIButton *)buttonWithKey:(id)key target:(id)target action:(SEL)selector;
+ (UIBarButtonItem *)barButtonItemWithKey:(id)key target:(id)target action:(SEL)selector;

+ (void)frontload;

@end
