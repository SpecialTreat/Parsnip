//
//  BEPopoverBackgroundView.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface BEPopoverBackgroundView : UIPopoverBackgroundView

+ (CGFloat)arrowBase;
+ (void)setArrowBase:(CGFloat)arrowBase;

+ (CGFloat)arrowHeight;
+ (void)setArrowHeight:(CGFloat)arrowHeight;

+ (UIEdgeInsets)contentViewInsets;
+ (void)setContentViewInsets:(UIEdgeInsets)contentViewInsets;
+ (BOOL)wantsDefaultContentAppearance;

+ (CGFloat)cornerRadius;
+ (void)setCornerRadius:(CGFloat)cornerRadius;

+ (UIColor *)backgroundColor;
+ (void)setBackgroundColor:(UIColor *)color;
+ (UIColor *)gradientTopColor;
+ (void)setGradientTopColor:(UIColor *)gradientTopColor;
+ (UIColor *)gradientBottomColor;
+ (void)setGradientBottomColor:(UIColor *)gradientBottomColor;
+ (CGFloat)gradientHeight;
+ (void)setGradientHeight:(CGFloat)gradientHeight;
+ (UIColor *)upArrowGradientTopColor;
+ (void)setUpArrowGradientTopColor:(UIColor *)upArrowGradientTopColor;
+ (UIColor *)upArrowGradientBottomColor;
+ (void)setUpArrowGradientBottomColor:(UIColor *)upArrowGradientBottomColor;

@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, readwrite) CGFloat arrowOffset;

- (CGGradientRef)createGradient:(CGColorSpaceRef)colorSpace CF_RETURNS_RETAINED;
- (CGGradientRef)createArrowGradient:(CGColorSpaceRef)colorSpace CF_RETURNS_RETAINED;

@end


@interface BEPopoverBackgroundViewDefaultContentAppearance : BEPopoverBackgroundView

@end
