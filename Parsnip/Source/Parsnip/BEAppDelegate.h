#import <UIKit/UIKit.h>
#import "JASidePanelController.h"


@interface BEAppDelegate : UIResponder <UIApplicationDelegate>

+ (UIViewController *)topController;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) JASidePanelController *sidePanelController;

@end
