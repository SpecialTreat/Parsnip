#import <UIKit/UIKit.h>


@interface UIBarButtonItem (Tools)

+ (UIBarButtonItem *)spacer;
+ (UIBarButtonItem *)spacer:(CGFloat)margin;

@property (nonatomic, readonly) UIView *internalView;
@property (nonatomic, readonly) UIBarButtonItem *visualClone;

@end
