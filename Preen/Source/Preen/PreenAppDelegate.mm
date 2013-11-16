#import "PreenAppDelegate.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "PreenCaptureController.h"
#import "PreenDB.h"
#import "PreenInfoController.h"
#import "PreenNavigationController.h"
#import "PreenNote.h"
#import "PreenPopoverBackgroundView.h"
#import "PreenUI.h"
#import "UIColor+Tools.h"
#import "UIImage+Drawing.h"
#import <Foundation/Foundation.h>


@implementation PreenAppDelegate

@synthesize window = _window;
@synthesize sidePanelController = _sidePanelController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [PreenUI frontload];

    [PreenDB setDebug:PreenUI.debug];
    [PreenDB register:PreenNote.class];
    if ([PreenDB needsInitialData]) {
        [PreenDB loadInitialData];
    }

    [PreenUI styleApp:self];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.sidePanelController = [self styleSidePanelController:[[JASidePanelController alloc] init]];

    PreenCaptureController *captureViewController = [[PreenCaptureController alloc] init];
    self.sidePanelController.centerPanel = captureViewController;

    PreenInfoController *infoViewController = [[PreenInfoController alloc] init];
    PreenNavigationController *leftPanel = [[PreenNavigationController alloc] initWithRootViewController:infoViewController];
    [PreenUI styleNavigationBar:leftPanel.navigationBar];
    self.sidePanelController.leftPanel = leftPanel;

    PreenNavigationController *rootViewController = [[PreenNavigationController alloc] initWithRootViewController:self.sidePanelController];
    [PreenUI styleNavigationBar:rootViewController.navigationBar];
    self.window.rootViewController = rootViewController;

    [self.window makeKeyAndVisible];
    return YES;
}

- (JASidePanelController *)styleSidePanelController:(JASidePanelController *)sidePanelController
{
    sidePanelController.shouldDelegateAutorotateToVisiblePanel = YES;
    sidePanelController.allowLeftOverpan = NO;
    sidePanelController.allowRightOverpan = NO;
    sidePanelController.bounceOnSidePanelClose = NO;
    sidePanelController.bounceOnSidePanelOpen = NO;
    sidePanelController.bounceOnCenterPanelChange = NO;
    sidePanelController.pushesSidePanels = YES;
    sidePanelController.leftFixedWidth = [PreenUI.theme floatForKey:@"InfoTable.Width"];
    sidePanelController.pushesSidePanelPercentage = [PreenUI.theme floatForKey:@"InfoTable.PushPercentage"];
    sidePanelController.sidePanelVerticalMargin = [PreenUI.theme edgeInsetsForKey:@"InfoTable.Margin"].top;
    sidePanelController.maximumAnimationDuration = UINavigationControllerHideShowBarDuration;
    sidePanelController.maskAlpha = [PreenUI.theme floatForKey:@"InfoTable.MaskAlpha"];
    return sidePanelController;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of
    // temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state. Use this method to pause ongoing tasks, disable timers,
    // and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application
    // state information to restore your application to its current state in case it is terminated later. If your
    // application supports background execution, this method is called instead of applicationWillTerminate: when the
    // user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the
    // changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application
    // was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
}

@end