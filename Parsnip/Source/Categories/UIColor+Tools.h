#import <UIKit/UIKit.h>


@interface UIColor (Tools)

+ (UIColor *)hex:(NSString *)hex;
+ (UIColor *)hex:(NSString *)hex normalize:(BOOL)normalize;
+ (NSString *)normalizeHex:(NSString *)hex;

@end
