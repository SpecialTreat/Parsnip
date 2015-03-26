//
//  BENotificationView.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BENotificationView.h"

#import "UIView+Tools.h"
#import "BEAppDelegate.h"


@implementation BENotificationView
{
    UILabel *descriptionLabel;
}

static CGFloat _animationScale = 1.5f;
static CGFloat _animationDuration = 0.75f;
static UIColor *_backgroundColor;
static NSArray *_cornerRadii;
static UIColor *_descriptionTextColor;
static UIFont *_descriptionFont;
static UIEdgeInsets _descriptionMargin;

+ (void)initialize
{
    _animationScale = 1.5f;
    _animationDuration = 0.75f;
    _backgroundColor = [UIColor lightGrayColor];
    _cornerRadii = @[@4.0f, @4.0f, @4.0f, @4.0f];
    _descriptionTextColor = [UIColor blackColor];
    _descriptionFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    _descriptionMargin = UIEdgeInsetsMake(10.0f, 20.0f, 10.0f, 20.0f);
}

+ (CGFloat)animationScale
{
    return _animationScale;
}

+ (void)setAnimationScale:(CGFloat)animationScale
{
    _animationScale = animationScale;
}

+ (CGFloat)animationDuration
{
    return _animationDuration;
}

+ (void)setAnimationDuration:(CGFloat)animationDuration
{
    _animationDuration = animationDuration;
}

+ (UIColor *)backgroundColor
{
    return _backgroundColor;
}

+ (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
}

+ (NSArray *)cornerRadii
{
    return _cornerRadii;
}

+ (void)setCornerRadii:(NSArray *)cornerRadii
{
    _cornerRadii = cornerRadii;
}

+ (UIColor *)descriptionTextColor
{
    return _descriptionTextColor;
}

+ (void)setDescriptionTextColor:(UIColor *)descriptionTextColor
{
    _descriptionTextColor = descriptionTextColor;
}

+ (UIFont *)descriptionFont
{
    return _descriptionFont;
}

+ (void)setDescriptionFont:(UIFont *)descriptionFont
{
    _descriptionFont = descriptionFont;
}

+ (UIEdgeInsets)descriptionMargin
{
    return _descriptionMargin;
}

+ (void)setDescriptionMargin:(UIEdgeInsets)descriptionMargin
{
    _descriptionMargin = descriptionMargin;
}

+ (void)notify:(NSString *)description
{
    UIView *view = BEAppDelegate.topController.view;
    BENotificationView *notification = [[BENotificationView alloc] initWithDescription:description];
    notification.center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));

    UIView *clone = notification.visualClone;
    clone.frame = notification.frame;
    [view addSubview:clone];

    CGSize finalSize = CGSizeMake(clone.frame.size.width * _animationScale, clone.frame.size.height * _animationScale);
    [UIView animateWithDuration:_animationDuration animations:^{
        clone.alpha = 0.0f;
        clone.frame = CGRectMake((view.bounds.size.width / 2.0f) - (finalSize.width / 2.0f),
                                 (view.bounds.size.height / 2.0f) - (finalSize.height / 2.0f),
                                 finalSize.width,
                                 finalSize.height);
    } completion:^(BOOL finished) {
        [clone removeFromSuperview];
    }];
}

- (id)initWithDescription:(NSString *)description
{
    CGSize size = [description sizeWithFont:_descriptionFont forWidth:260.0f lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = CGRectMake(0.0f,
                              0.0f,
                              size.width + _descriptionMargin.left + _descriptionMargin.right,
                              size.height + _descriptionMargin.top + _descriptionMargin.bottom);

    self = [super initWithFrame:frame];
    if (self) {
        descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(_descriptionMargin.left, _descriptionMargin.top, size.width, size.height)];
        descriptionLabel.font = _descriptionFont;
        descriptionLabel.textColor = _descriptionTextColor;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        descriptionLabel.textAlignment = NSTextAlignmentCenter;
        descriptionLabel.text = description;
        [self addSubview:descriptionLabel];

        self.backgroundColor = _backgroundColor;
        [self roundCorners:_cornerRadii];
    }
    return self;
}

@end
