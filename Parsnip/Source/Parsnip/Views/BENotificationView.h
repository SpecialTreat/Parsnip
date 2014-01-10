#import <UIKit/UIKit.h>


@interface BENotificationView : UIView

+ (void)notify:(NSString *)description;

+ (CGFloat)animationScale;
+ (void)setAnimationScale:(CGFloat)animationScale;
+ (CGFloat)animationDuration;
+ (void)setAnimationDuration:(CGFloat)animationDuration;
+ (UIColor *)backgroundColor;
+ (void)setBackgroundColor:(UIColor *)backgroundColor;
+ (NSArray *)cornerRadii;
+ (void)setCornerRadii:(NSArray *)cornerRadii;
+ (UIColor *)descriptionTextColor;
+ (void)setDescriptionTextColor:(UIColor *)descriptionTextColor;
+ (UIFont *)descriptionFont;
+ (void)setDescriptionFont:(UIFont *)descriptionFont;
+ (UIEdgeInsets)descriptionMargin;
+ (void)setDescriptionMargin:(UIEdgeInsets)descriptionMargin;

- (id)initWithDescription:(NSString *)description;

@end
