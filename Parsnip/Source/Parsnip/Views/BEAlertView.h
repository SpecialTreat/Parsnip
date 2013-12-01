#import <UIKit/UIKit.h>

@interface BEAlertView : UIView

+ (CGFloat)showAnimationScale;
+ (void)setShowAnimationScale:(CGFloat)showAnimationScale;
+ (CGFloat)hideAnimationScale;
+ (void)setHideAnimationScale:(CGFloat)hideAnimationScale;
+ (NSArray *)cornerRadii;
+ (void)setCornerRadii:(NSArray *)cornerRadii;

@property (nonatomic) NSArray *buttons;
@property (nonatomic) CGSize size;
@property (nonatomic) CGFloat maskAlpha;
@property (nonatomic) UIColor *shadowColor;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat shadowOpacity;
@property (nonatomic) CGFloat shadowRadius;

- (void)show:(void(^)())animations completion:(void(^)(BOOL finished))completion;
- (void)hide:(void(^)())animations completion:(void(^)(BOOL finished))completion;

@end
