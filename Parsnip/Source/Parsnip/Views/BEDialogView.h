#import <UIKit/UIKit.h>


@interface BEDialogView : UIView

+ (CGFloat)buttonHeight;
+ (void)setButtonHeight:(CGFloat)buttonHeight;
+ (UIColor *)titleColor;
+ (void)setTitleColor:(UIColor *)titleColor;
+ (UIFont *)titleFont;
+ (void)setTitleFont:(UIFont *)titleFont;
+ (UIEdgeInsets)titleMargin;
+ (void)setTitleMargin:(UIEdgeInsets)titleMargin;
+ (UIColor *)descriptionColor;
+ (void)setDescriptionColor:(UIColor *)descriptionColor;
+ (UIFont *)descriptionFont;
+ (void)setDescriptionFont:(UIFont *)descriptionFont;
+ (UIEdgeInsets)descriptionMargin;
+ (void)setDescriptionMargin:(UIEdgeInsets)descriptionMargin;
+ (CGFloat)showAnimationScale;
+ (void)setShowAnimationScale:(CGFloat)showAnimationScale;
+ (CGFloat)hideAnimationScale;
+ (void)setHideAnimationScale:(CGFloat)hideAnimationScale;
+ (NSArray *)cornerRadii;
+ (void)setCornerRadii:(NSArray *)cornerRadii;

@property (nonatomic) NSArray *buttons;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *description;
@property (nonatomic) CGSize size;
@property (nonatomic) CGFloat maskAlpha;
@property (nonatomic) UIColor *shadowColor;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat shadowOpacity;
@property (nonatomic) CGFloat shadowRadius;

- (void)show:(void(^)())animations completion:(void(^)(BOOL finished))completion;
- (void)hide:(void(^)())animations completion:(void(^)(BOOL finished))completion;
- (void)fadeOutDialog:(void(^)(BOOL finished))completion;
- (void)fadeInDialog:(void(^)(BOOL finished))completion;
- (void)startActivityIndicator;
- (void)stopActivityIndicator;

@end
