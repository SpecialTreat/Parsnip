//
//  BEAlertView.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>
#import "BETouchableView.h"


@interface BEAlertView : UIView<BETouchableViewDelegate>

+ (CGFloat)buttonHeight;
+ (void)setButtonHeight:(CGFloat)buttonHeight;
+ (CGFloat)buttonMargin;
+ (void)setButtonMargin:(CGFloat)buttonMargin;

@property (nonatomic) NSArray *buttons;
@property (nonatomic) CGFloat maskAlpha;
@property (nonatomic) NSString *cancelButtonTitle;
@property (nonatomic, readonly) NSInteger cancelButtonIndex;
@property (unsafe_unretained, nonatomic) id<UIAlertViewDelegate> delegate;

- (void)show:(void(^)())animations completion:(void(^)(BOOL finished))completion;
- (void)hide:(void(^)())animations completion:(void(^)(BOOL finished))completion;
- (void)dismissAnimated:(BOOL)animated;

@end
