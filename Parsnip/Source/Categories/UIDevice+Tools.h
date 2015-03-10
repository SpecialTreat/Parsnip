#import <UIKit/UIKit.h>


@interface UIDevice (Tools)

+ (BOOL)isIOS7;
+ (BOOL)isIOS8;
+ (BOOL)isIpad;
+ (BOOL)isGoogleMapsInstalled;
+ (BOOL)isChromeInstalled;
+ (BOOL)openInMaps:(NSString *)address;
+ (BOOL)openInGoogleMaps:(NSString *)address;
+ (BOOL)openInChrome:(NSURL *)url;
+ (BOOL)openInChrome:(NSURL *)url createNewTab:(BOOL)createNewTab;
+ (BOOL)reviewInAppStore:(NSString *)appID;

@end
