#import "BEDialogView.h"

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import "UIBezierPath+Tools.h"
#import "UIView+Tools.h"


@implementation BEDialogView
{
    UIView *backgroundView;
    UIView *shadowView;
    UILabel *titleLabel;
    UILabel *descriptionLabel;
    NSString *_title;
    NSString *_description;
    NSMutableArray *_buttons;
    CGSize _size;
}

static CGFloat _buttonHeight = 60.0f;
static UIColor *_titleColor;
static UIFont *_titleFont;
static UIEdgeInsets _titleMargin;
static UIColor *_descriptionColor;
static UIFont *_descriptionFont;
static UIEdgeInsets _descriptionMargin;
static CGFloat _showAnimationScale = 1.4f;
static CGFloat _hideAnimationScale = 0.8f;
static NSArray *_cornerRadii;

+ (void)initialize
{
    _cornerRadii = @[@0.0f, @0.0f, @0.0f, @0.0f];
    _titleColor = [UIColor blackColor];
    _titleFont = [UIFont boldSystemFontOfSize:UIFont.systemFontSize];
    _titleMargin = UIEdgeInsetsZero;
    _descriptionColor = [UIColor blackColor];
    _descriptionFont = [UIFont systemFontOfSize:UIFont.systemFontSize];
    _descriptionMargin = UIEdgeInsetsZero;
}

+ (CGFloat)buttonHeight
{
    return _buttonHeight;
}

+ (void)setButtonHeight:(CGFloat)buttonHeight
{
    _buttonHeight = buttonHeight;
}

+ (UIColor *)titleColor
{
    return _titleColor;
}

+ (void)setTitleColor:(UIColor *)titleColor
{
    _titleColor = titleColor;
}

+ (UIFont *)titleFont
{
    return _titleFont;
}

+ (void)setTitleFont:(UIFont *)titleFont
{
    _titleFont = titleFont;
}

+ (UIEdgeInsets)titleMargin
{
    return _titleMargin;
}

+ (void)setTitleMargin:(UIEdgeInsets)titleMargin
{
    _titleMargin = titleMargin;
}

+ (UIColor *)descriptionColor
{
    return _descriptionColor;
}

+ (void)setDescriptionColor:(UIColor *)descriptionColor
{
    _descriptionColor = descriptionColor;
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

@synthesize title = _title;
@synthesize description = _description;
@synthesize buttons = _buttons;
@synthesize maskAlpha = _maskAlpha;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [NSMutableArray array];
        _maskAlpha = 0.0f;
        _size = CGSizeMake(280.0f, 240.0f);

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

        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(_titleMargin.left, _titleMargin.top, 0, 0)];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = _titleFont;
        titleLabel.textColor = _titleColor;

        descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(_descriptionMargin.left, _titleMargin.top + _titleMargin.bottom + _descriptionMargin.top, 0, 0)];
        descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.font = _descriptionFont;
        descriptionLabel.textColor = _descriptionColor;

        [backgroundView addSubview:titleLabel];
        [backgroundView addSubview:descriptionLabel];
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

- (void)setTitle:(NSString *)title
{
    _title = title;
    titleLabel.text = title;
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(_size.width / 2, (titleLabel.frame.size.height / 2) + _titleMargin.top);
    CGFloat descriptionY = _titleMargin.top + _titleMargin.bottom + titleLabel.frame.size.height + _descriptionMargin.top;
    descriptionLabel.frame = CGRectMake(_descriptionMargin.left,
                                        descriptionY,
                                        descriptionLabel.frame.size.width,
                                        descriptionLabel.frame.size.height);
}

- (void)setDescription:(NSString *)description
{
    _description = description;
    descriptionLabel.text = description;
    CGFloat descriptionY = _titleMargin.top + _titleMargin.bottom + titleLabel.frame.size.height + _descriptionMargin.top;
    CGSize descriptionSize = [descriptionLabel sizeThatFits:CGSizeMake(_size.width - (_descriptionMargin.left + _descriptionMargin.right),
                                                                       _size.height - descriptionY - _buttonHeight)];
    descriptionLabel.frame = CGRectMake(_descriptionMargin.left, descriptionY, descriptionSize.width, descriptionSize.height);
}

- (void)setButtons:(NSArray *)buttons
{
    for (UIButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    NSUInteger count = 0;

    CGFloat buttonWidth = self.size.width / buttons.count;
    CGFloat buttonY = self.size.height - _buttonHeight;
    for (UIButton *button in buttons) {
        button.frame = CGRectMake(buttonWidth * count, buttonY, buttonWidth, _buttonHeight);
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
    [backgroundView roundCorners:_cornerRadii];

    NSUInteger count = 0;
    CGFloat buttonWidth = size.width / _buttons.count;
    CGFloat buttonY = size.height - _buttonHeight;
    for (UIButton *button in _buttons) {
        button.frame = CGRectMake(buttonWidth * count, buttonY, buttonWidth, _buttonHeight);
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

- (void)fadeOutDialog:(void(^)(BOOL finished))completion
{
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        backgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)fadeInDialog:(void(^)(BOOL finished))completion
{
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        backgroundView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}


@end
