#import <UIKit/UIKit.h>


@interface UIBezierPath (Tools)

+ (UIBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadii:(NSArray *)cornerRadii;

@end
