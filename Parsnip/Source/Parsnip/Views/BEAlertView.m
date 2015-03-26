//
//  BEAlertView.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEAlertView.h"

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import "UIBezierPath+Tools.h"
#import "UIView+Tools.h"
#import "BEUI.h"
#import "BEAppDelegate.h"


@implementation BEAlertView
{
    UIView *backgroundView;
    BETouchableView *maskView;
    UIButton *cancelButton;
    NSMutableArray *_buttons;
    NSString *_cancelButtonTitle;
}

static CGFloat _buttonHeight;
static CGFloat _buttonMargin;

+ (void)initialize
{
    _buttonHeight = 48.0f;
    _buttonMargin = 10.0f;
}

+ (CGFloat)buttonHeight
{
    return _buttonHeight;
}

+ (void)setButtonHeight:(CGFloat)buttonHeight
{
    _buttonHeight = buttonHeight;
}

+ (CGFloat)buttonMargin
{
    return _buttonMargin;
}

+ (void)setButtonMargin:(CGFloat)buttonMargin
{
    _buttonMargin = buttonMargin;
}

@synthesize buttons = _buttons;
@synthesize maskAlpha = _maskAlpha;
@synthesize cancelButtonTitle = _cancelButtonTitle;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [NSMutableArray array];
        _maskAlpha = 0.0f;

        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.userInteractionEnabled = YES;

        CGRect bounds = frame;
        bounds.origin.x = 0.0f;
        bounds.origin.y = 0.0f;
        maskView = [[BETouchableView alloc] initWithFrame:bounds];
        maskView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        maskView.backgroundColor = [UIColor blackColor];
        maskView.delegate = self;

        CGFloat buttonWidth = frame.size.width - (_buttonMargin * 2.0f);

        backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, buttonWidth, 0.0f)];
        backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                           UIViewAutoresizingFlexibleBottomMargin |
                                           UIViewAutoresizingFlexibleWidth);

        cancelButton = [BEUI buttonWithKey:@[@"AlertCancelButton", @"AlertButton"] target:self action:@selector(onCancelButtonTouch:event:)];
        _cancelButtonTitle = [cancelButton titleForState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(0.0f, _buttonMargin, buttonWidth, _buttonHeight);
        cancelButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        cancelButton.contentMode = UIViewContentModeRedraw;

        [self addSubview:maskView];
        [backgroundView addSubview:cancelButton];
        [self addSubview:backgroundView];

        self.maskAlpha = _maskAlpha;
    }
    return self;
}

- (void)dealloc
{
    maskView.delegate = nil;
    self.delegate = nil;
}

- (NSInteger)cancelButtonIndex
{
    return _buttons.count;
}

- (void)touchableViewOnTouch:(BETouchableView *)view
{
    [self dismissButtonIndex:self.cancelButtonIndex animated:YES];
}

- (void)onCancelButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [self dismissButtonIndex:self.cancelButtonIndex animated:YES];
}

- (void)onButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [self.delegate alertView:(UIAlertView *)self clickedButtonAtIndex:sender.tag];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissButtonIndex:-1 animated:animated];
}

- (void)dismissButtonIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index == self.cancelButtonIndex) {
        [self.delegate alertViewCancel:(UIAlertView *)self];
    }

    void (^dismissCompleted)() = ^()
    {
        [self removeFromSuperview];
        [self.delegate alertView:(UIAlertView *)self didDismissWithButtonIndex:index];

        UINavigationController *navigationController = BEAppDelegate.topNavigationController;
        if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
    };

    [self.delegate alertView:(UIAlertView *)self willDismissWithButtonIndex:index];
    if (animated) {
        [self hide:nil completion:^(BOOL finished) {
            dismissCompleted();
        }];
    } else {
        dismissCompleted();
    }
}

- (void)setCancelButtonTitle:(NSString *)cancelButtonTitle
{
    _cancelButtonTitle = cancelButtonTitle;
    [cancelButton setTitle:_cancelButtonTitle forState:UIControlStateNormal];
}

- (void)setButtons:(NSArray *)buttons
{
    for (UIButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];

    CGFloat buttonWidth = self.frame.size.width - (_buttonMargin * 2.0f);
    backgroundView.frame = CGRectMake(0.0f, 0.0f, buttonWidth, (_buttonHeight * (buttons.count + 1)) + _buttonMargin);
    backgroundView.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));

    cancelButton.frame = CGRectMake(0.0f, (_buttonHeight * buttons.count) + _buttonMargin, buttonWidth, _buttonHeight);

    NSUInteger count = 0;
    for (NSString *title in buttons) {
        NSArray *buttonKey;
        if (buttons.count == 1) {
            buttonKey = @[@"AlertOnlyButton", @"AlertButton"];
        } else if (count == 0) {
            buttonKey = @[@"AlertFirstButton", @"AlertButton"];
        } else if ((count + 1) < buttons.count) {
            buttonKey = @[@"AlertMiddleButton", @"AlertButton"];
        } else {
            buttonKey = @[@"AlertLastButton", @"AlertButton"];
        }
        UIButton *button = [BEUI buttonWithKey:buttonKey target:self action:@selector(onButtonTouch:event:)];
        button.tag = count;
        button.frame = CGRectMake(0, _buttonHeight * count, buttonWidth, _buttonHeight);
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [button setTitle:title forState:UIControlStateNormal];
        [_buttons addObject:button];
        [backgroundView addSubview:button];
        count += 1;
    }
}

- (void)setMaskAlpha:(CGFloat)maskAlpha
{
    _maskAlpha = maskAlpha;
}

- (void)show:(void(^)())animations completion:(void(^)(BOOL finished))completion
{
    UINavigationController *navigationController = BEAppDelegate.topNavigationController;
    if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        navigationController.interactivePopGestureRecognizer.enabled = NO;
    }

    [self.delegate willPresentAlertView:(UIAlertView *)self];

    CGRect backgroundViewFrame = backgroundView.frame;
    backgroundViewFrame.origin.y = self.frame.size.height;
    backgroundView.frame = backgroundViewFrame;
    maskView.alpha = 0.0f;
    self.hidden = NO;

    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        if (animations) {
            animations();
        }
        CGRect backgroundViewFrame = backgroundView.frame;
        backgroundViewFrame.origin.y = self.frame.size.height - backgroundView.frame.size.height - _buttonMargin;
        backgroundView.frame = backgroundViewFrame;
        maskView.alpha = _maskAlpha;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
        [self.delegate didPresentAlertView:(UIAlertView *)self];
    }];
}

- (void)hide:(void(^)())animations completion:(void(^)(BOOL finished))completion
{
    for (UIButton *button in _buttons) {
        button.highlighted = NO;
    }

    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        if (animations) {
            animations();
        }
        CGRect backgroundViewFrame = backgroundView.frame;
        backgroundViewFrame.origin.y = self.frame.size.height;
        backgroundView.frame = backgroundViewFrame;
        maskView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        if (completion) {
            completion(finished);
        }
    }];
}

@end
