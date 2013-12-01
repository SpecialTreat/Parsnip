#import "BEAlertView.h"

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import "UIBezierPath+Tools.h"
#import "UIView+Tools.h"


static CGFloat _showAnimationScale = 1.4f;
static CGFloat _hideAnimationScale = 0.8f;
static NSArray *_cornerRadii;


@implementation BEAlertView
{
    UIView *backgroundView;
    UIView *shadowView;
    NSMutableArray *_buttons;
    CGSize _size;
}

+ (void)initialize
{
    _cornerRadii = @[@0.0f, @0.0f, @0.0f, @0.0f];
}

+ (CGFloat)showAnimationScale
{
    return _showAnimationScale;
}

+ (void)setShowAnimationScale:(CGFloat)showAnimationScale
{
    _showAnimationScale = showAnimationScale;
}

+ (CGFloat)hideAnimationScale
{
    return _hideAnimationScale;
}

+ (void)setHideAnimationScale:(CGFloat)hideAnimationScale
{
    _hideAnimationScale = hideAnimationScale;
}

+ (NSArray *)cornerRadii
{
    return _cornerRadii;
}

+ (void)setCornerRadii:(NSArray *)cornerRadii
{
    if (!cornerRadii) {
        cornerRadii = @[@0.0f, @0.0f, @0.0f, @0.0f];
    }
    _cornerRadii = cornerRadii;
}

@synthesize buttons = _buttons;
@synthesize maskAlpha = _maskAlpha;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [NSMutableArray array];
        _maskAlpha = 0.0f;
        _size = CGSizeMake(240.0f, 120.0f);

        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.userInteractionEnabled = YES;

        CGRect backgroundFrame = CGRectMake(0, 0, _size.width, _size.height);
        backgroundView = [[UIView alloc] initWithFrame:backgroundFrame];
        backgroundView.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        backgroundView.backgroundColor = [UIColor whiteColor];
        backgroundView.contentMode = UIViewContentModeRedraw;
        backgroundView.userInteractionEnabled = YES;
        backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                           UIViewAutoresizingFlexibleBottomMargin |
                                           UIViewAutoresizingFlexibleRightMargin |
                                           UIViewAutoresizingFlexibleLeftMargin);
        [backgroundView roundCorners:_cornerRadii];

        shadowView = [[UIView alloc] initWithFrame:backgroundFrame];
        shadowView.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        shadowView.backgroundColor = [UIColor clearColor];
        shadowView.userInteractionEnabled = NO;
        shadowView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleLeftMargin);
        shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:backgroundView.bounds cornerRadii:_cornerRadii].CGPath;
        shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        shadowView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        shadowView.layer.shadowOpacity = 0.5f;
        shadowView.layer.shadowRadius = 10.0f;

        [self addSubview:shadowView];
        [self addSubview:backgroundView];

        self.maskAlpha = _maskAlpha;
        self.size = _size;
    }
    return self;
}

- (UIColor *)shadowColor
{
    return [UIColor colorWithCGColor:shadowView.layer.shadowColor];
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    shadowView.layer.shadowColor = shadowColor.CGColor;
}

- (CGSize)shadowOffset
{
    return shadowView.layer.shadowOffset;
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    shadowView.layer.shadowOffset = shadowOffset;
}

- (CGFloat)shadowOpacity
{
    return shadowView.layer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity
{
    shadowView.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowRadius
{
    return shadowView.layer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    shadowView.layer.shadowRadius = shadowRadius;
}

- (void)setButtons:(NSArray *)buttons
{
    for (UIButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    NSUInteger count = 0;
    CGFloat buttonHeight = self.size.height / buttons.count;
    for (UIButton *button in buttons) {
        button.frame = CGRectMake(0, buttonHeight * count, self.size.width, buttonHeight);
        [_buttons addObject:button];
        [backgroundView addSubview:button];
        count += 1;
    }
}

- (void)setMaskAlpha:(CGFloat)maskAlpha
{
    _maskAlpha = maskAlpha;
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:_maskAlpha];
}

- (CGSize)size
{
    return _size;
}

- (void)setSize:(CGSize)size
{
    _size = size;
    [self setSubviewSizes:size];
}

- (void)setSubviewSizes:(CGSize)size
{
    backgroundView.frame = CGRectMake((self.bounds.size.width / 2.0f) - (size.width / 2.0f),
                                      (self.bounds.size.height / 2.0f) - (size.height / 2.0f),
                                      size.width,
                                      size.height);

    NSUInteger count = 0;
    CGFloat buttonHeight = size.height / _buttons.count;
    for (UIButton *button in _buttons) {
        button.frame = CGRectMake(0, buttonHeight * count, size.width, buttonHeight);
        count += 1;
    }
}

- (void)show:(void(^)())animations completion:(void(^)(BOOL finished))completion
{
    UIView *backgroundClone = backgroundView.visualClone;
    backgroundClone.frame = backgroundView.frame;
    [self addSubview:backgroundClone];

    backgroundView.hidden = YES;
    self.alpha = 0.0f;
    self.hidden = NO;

    CGSize initialSize = CGSizeMake(_size.width * _showAnimationScale, _size.height * _showAnimationScale);
    backgroundClone.frame = CGRectMake((self.bounds.size.width / 2.0f) - (initialSize.width / 2.0f),
                                       (self.bounds.size.height / 2.0f) - (initialSize.height / 2.0f),
                                       initialSize.width,
                                       initialSize.height);
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        if (animations) {
            animations();
        }
        self.alpha = 1.0f;
        backgroundClone.frame = CGRectMake((self.bounds.size.width / 2.0f) - (_size.width / 2.0f),
                                           (self.bounds.size.height / 2.0f) - (_size.height / 2.0f),
                                           _size.width,
                                           _size.height);
    } completion:^(BOOL finished) {
        backgroundView.hidden = NO;
        [backgroundClone removeFromSuperview];
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)hide:(void(^)())animations completion:(void(^)(BOOL finished))completion
{
    for (UIButton *button in _buttons) {
        button.highlighted = NO;
    }

    UIView *backgroundClone = backgroundView.visualClone;
    backgroundClone.frame = backgroundView.frame;
    [self addSubview:backgroundClone];

    backgroundView.hidden = YES;

    CGSize finalSize = CGSizeMake(_size.width * _hideAnimationScale, _size.height * _hideAnimationScale);
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        if (animations) {
            animations();
        }
        self.alpha = 0.0f;
        backgroundClone.frame = CGRectMake((self.bounds.size.width / 2.0f) - (finalSize.width / 2.0f),
                                           (self.bounds.size.height / 2.0f) - (finalSize.height / 2.0f),
                                           finalSize.width,
                                           finalSize.height);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        backgroundView.hidden = NO;
        [backgroundClone removeFromSuperview];
        if (completion) {
            completion(finished);
        }
    }];
}

@end
