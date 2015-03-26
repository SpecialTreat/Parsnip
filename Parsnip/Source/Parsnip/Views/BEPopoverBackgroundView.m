//
//  BEPopoverBackgroundView.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEPopoverBackgroundView.h"

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#import "UIImage+Drawing.h"


@implementation BEPopoverBackgroundViewDefaultContentAppearance

+ (BOOL)wantsDefaultContentAppearance
{
    return YES;
}

@end


@implementation BEPopoverBackgroundView
{
    UIImageView *backgroundView;
    UIBezierPath *currentPath;
}

static CGFloat _arrowBase = 44.0f;
static CGFloat _arrowHeight = 22.0f;
static CGFloat _arrowSlope = 22.0f / (44.0f / 2.0f); // _arrowHeight / (_arrowBase / 2.0f);
static UIEdgeInsets _contentViewInsets;
static CGFloat _cornerRadius = 10.0f;
static UIColor *_backgroundColor = nil;
static CGFloat _gradientHeight = 0.0f;
static UIColor *_gradientTopColor = nil;
static UIColor *_gradientBottomColor = nil;
static UIColor *_upArrowGradientTopColor = nil;
static UIColor *_upArrowGradientBottomColor = nil;

+ (void)initialize
{
    _contentViewInsets = UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f);
}

+ (UIColor *)backgroundColor
{
    return _backgroundColor;
}

+ (void)setBackgroundColor:(UIColor *)color
{
    _backgroundColor = color;
}

+ (CGFloat)gradientHeight
{
    return _gradientHeight;
}

+ (void)setGradientHeight:(CGFloat)gradientHeight
{
    _gradientHeight = gradientHeight;
}

+ (UIColor *)gradientTopColor
{
    return _gradientTopColor;
}

+ (void)setGradientTopColor:(UIColor *)gradientTopColor
{
    _gradientTopColor = gradientTopColor;
}

+ (UIColor *)gradientBottomColor
{
    return _gradientBottomColor;
}

+ (void)setGradientBottomColor:(UIColor *)gradientBottomColor
{
    _gradientBottomColor = gradientBottomColor;
}

+ (UIColor *)upArrowGradientTopColor
{
    return _upArrowGradientTopColor;
}

+ (void)setUpArrowGradientTopColor:(UIColor *)upArrowGradientTopColor
{
    _upArrowGradientTopColor = upArrowGradientTopColor;
}

+ (UIColor *)upArrowGradientBottomColor
{
    return _upArrowGradientBottomColor;
}

+ (void)setUpArrowGradientBottomColor:(UIColor *)upArrowGradientBottomColor
{
    _upArrowGradientBottomColor = upArrowGradientBottomColor;
}

@synthesize arrowDirection = _arrowDirection;
@synthesize arrowOffset = _arrowOffset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _arrowDirection = UIPopoverArrowDirectionUnknown;
        _arrowOffset = 0.0f;
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.contentMode = UIViewContentModeRedraw;
    [self addSubview:backgroundView];
}

- (void)setClipsToBounds:(BOOL)clipsToBounds
{
    [super setClipsToBounds:clipsToBounds];
    if (clipsToBounds && currentPath) {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        maskLayer.path = currentPath.CGPath;
        self.layer.mask = maskLayer;
    } else {
        self.layer.mask = nil;
    }
}

- (CGFloat)minArrow
{
    CGFloat dimension;
    if(_arrowDirection == UIPopoverArrowDirectionRight || _arrowDirection == UIPopoverArrowDirectionLeft) {
        dimension = self.bounds.size.height;
    } else {
        dimension = self.bounds.size.width;
    }
    CGFloat desiredArrow = (dimension / 2.0f) + _arrowOffset - (_arrowBase / 2.0f);
    CGFloat minArrow = 0.0f;
    CGFloat maxArrow = dimension - _arrowBase;
    return MIN(maxArrow, MAX(minArrow, desiredArrow));
}

- (CGFloat)maxArrow
{
    CGFloat dimension;
    if(_arrowDirection == UIPopoverArrowDirectionRight || _arrowDirection == UIPopoverArrowDirectionLeft) {
        dimension = self.bounds.size.height;
    } else {
        dimension = self.bounds.size.width;
    }
    CGFloat desiredArrow = (dimension / 2.0f) + _arrowOffset + (_arrowBase / 2.0f);
    CGFloat minArrow = _arrowBase;
    CGFloat maxArrow = dimension;
    return MIN(maxArrow, MAX(minArrow, desiredArrow));
}

- (UIEdgeInsets)resizeInsets
{
    CGFloat prefix;
    CGFloat suffix;
    if(_arrowOffset > 0) {
        prefix = _cornerRadius;
        if(_arrowDirection == UIPopoverArrowDirectionRight || _arrowDirection == UIPopoverArrowDirectionLeft) {
            suffix = self.bounds.size.height - [self minArrow];
        } else {
            suffix = self.bounds.size.width - [self minArrow];
        }
    } else {
        prefix = [self maxArrow];
        suffix = _cornerRadius;
    }
    switch(_arrowDirection) {
        case UIPopoverArrowDirectionLeft: {
            CGFloat top = MAX(_gradientHeight, prefix);
            return UIEdgeInsetsMake(top, _cornerRadius + _arrowHeight, suffix, _cornerRadius);
            break;
        }
        case UIPopoverArrowDirectionRight: {
            CGFloat top = MAX(_gradientHeight, prefix);
            return UIEdgeInsetsMake(top, _cornerRadius, suffix, _cornerRadius + _arrowHeight);
            break;
        }
        case UIPopoverArrowDirectionUp: {
            CGFloat top = _arrowHeight + MAX(_gradientHeight, _cornerRadius);
            return UIEdgeInsetsMake(top, prefix, _cornerRadius, suffix);
            break;
        }
        case UIPopoverArrowDirectionDown: {
            CGFloat top = MAX(_gradientHeight, _cornerRadius);
            return UIEdgeInsetsMake(top, prefix, _cornerRadius + _arrowHeight, suffix);
            break;
        }
        default: {
            CGFloat top = MAX(_gradientHeight, _cornerRadius);
            return UIEdgeInsetsMake(top, _cornerRadius, _cornerRadius, _cornerRadius);
            break;
        }
    }
}

- (UIBezierPath *)pathForPopover
{
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat minArrow = [self minArrow];
    CGFloat maxArrow = [self maxArrow];

    switch(_arrowDirection) {
        case UIPopoverArrowDirectionUp: {
            [path moveToPoint:CGPointMake(0.0f, _arrowHeight + _cornerRadius)];
            [path addLineToPoint:CGPointMake(0.0f, height - _cornerRadius)];
            [path addArcWithCenter:CGPointMake(_cornerRadius, height - _cornerRadius) radius:_cornerRadius startAngle:M_PI endAngle:M_PI / 2.0f clockwise:NO];
            [path addLineToPoint:CGPointMake(width - _cornerRadius, height)];
            [path addArcWithCenter:CGPointMake(width - _cornerRadius, height - _cornerRadius) radius:_cornerRadius startAngle:M_PI / 2.0f endAngle:0 clockwise:NO];
            [path addLineToPoint:CGPointMake(width, _arrowHeight + _cornerRadius)];
            if(maxArrow > (width - _cornerRadius)) {
                CGFloat desiredX = maxArrow;
                CGFloat desiredY = _arrowHeight;
                CGFloat m = _arrowSlope;
                CGFloat y = _arrowHeight - sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat x = ((y - desiredY) / m) + desiredX;
                [path addCurveToPoint:CGPointMake(x, y)
                        controlPoint1:CGPointMake(width, _arrowHeight)
                        controlPoint2:CGPointMake(desiredX, desiredY)];
            } else {
                [path addArcWithCenter:CGPointMake(width - _cornerRadius, _arrowHeight + _cornerRadius) radius:_cornerRadius startAngle:2.0f * M_PI endAngle:3.0f * M_PI / 2.0f clockwise:NO];
                [path addLineToPoint:CGPointMake(maxArrow, _arrowHeight)];
            }
            [path addLineToPoint:CGPointMake(minArrow + (_arrowBase / 2.0f), 0.0f)];
            if(minArrow < _cornerRadius) {
                CGFloat desiredX = minArrow;
                CGFloat desiredY = _arrowHeight;
                CGFloat m = 0.0f - _arrowSlope;
                CGFloat y = _arrowHeight - sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat x = ((y - desiredY) / m) + desiredX;
                [path addLineToPoint:CGPointMake(x, y)];
                [path addCurveToPoint:CGPointMake(0.0f, _arrowHeight + _cornerRadius)
                        controlPoint1:CGPointMake(desiredX, desiredY)
                        controlPoint2:CGPointMake(0.0f, _arrowHeight)];
            } else {
                [path addLineToPoint:CGPointMake(minArrow, _arrowHeight)];
                [path addLineToPoint:CGPointMake(_cornerRadius, _arrowHeight)];
                [path addArcWithCenter:CGPointMake(_cornerRadius, _arrowHeight + _cornerRadius) radius:_cornerRadius startAngle:3.0f * M_PI / 2.0f endAngle:M_PI clockwise:NO];
            }
            [path closePath];
            return path;
            break;
        }
        case UIPopoverArrowDirectionDown: {
            [path moveToPoint:CGPointMake(width, height - _arrowHeight - _cornerRadius)];
            [path addLineToPoint:CGPointMake(width, _cornerRadius)];
            [path addArcWithCenter:CGPointMake(width - _cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:2.0f * M_PI endAngle:3.0f * M_PI / 2.0f clockwise:NO];
            [path addLineToPoint:CGPointMake(_cornerRadius, 0.0f)];
            [path addArcWithCenter:CGPointMake(_cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:3.0f * M_PI / 2.0f endAngle:M_PI clockwise:NO];
            [path addLineToPoint:CGPointMake(0.0f, height - _arrowHeight - _cornerRadius)];
            if(minArrow < _cornerRadius) {
                CGFloat desiredX = minArrow;
                CGFloat desiredY = height - _arrowHeight;
                CGFloat m = _arrowSlope;
                CGFloat y = height - _arrowHeight + sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat x = ((y - desiredY) / m) + desiredX;
                [path addCurveToPoint:CGPointMake(x, y)
                        controlPoint1:CGPointMake(0.0f, height - _arrowHeight)
                        controlPoint2:CGPointMake(desiredX, desiredY)];
            } else {
                [path addArcWithCenter:CGPointMake(_cornerRadius, height - _arrowHeight - _cornerRadius) radius:_cornerRadius startAngle:M_PI endAngle:M_PI / 2.0f clockwise:NO];
                [path addLineToPoint:CGPointMake(minArrow, height - _arrowHeight)];
            }
            [path addLineToPoint:CGPointMake(minArrow + (_arrowBase / 2.0f), height)];
            if(maxArrow > (width - _cornerRadius)) {
                CGFloat desiredX = maxArrow;
                CGFloat desiredY = height - _arrowHeight;
                CGFloat m = 0.0f - _arrowSlope;
                CGFloat y = height - _arrowHeight + sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat x = ((y - desiredY) / m) + desiredX;
                [path addLineToPoint:CGPointMake(x, y)];
                [path addCurveToPoint:CGPointMake(width, height - _arrowHeight - _cornerRadius)
                        controlPoint1:CGPointMake(desiredX, desiredY)
                        controlPoint2:CGPointMake(width, height - _arrowHeight)];
            } else {
                [path addLineToPoint:CGPointMake(maxArrow, height - _arrowHeight)];
                [path addLineToPoint:CGPointMake(width - _cornerRadius, height - _arrowHeight)];
                [path addArcWithCenter:CGPointMake(width - _cornerRadius, height - _arrowHeight - _cornerRadius) radius:_cornerRadius startAngle:M_PI / 2.0f endAngle:0.0f clockwise:NO];
            }
            [path closePath];
            return path;
            break;
        }
        case UIPopoverArrowDirectionRight: {
            [path moveToPoint:CGPointMake(width - _arrowHeight - _cornerRadius, 0.0f)];
            [path addLineToPoint:CGPointMake(_cornerRadius, 0.0f)];
            [path addArcWithCenter:CGPointMake(_cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:3.0f * M_PI / 2.0f endAngle:M_PI clockwise:NO];
            [path addLineToPoint:CGPointMake(0.0f, height - _cornerRadius)];
            [path addArcWithCenter:CGPointMake(_cornerRadius, height - _cornerRadius) radius:_cornerRadius startAngle:M_PI endAngle:M_PI / 2.0f clockwise:NO];
            [path addLineToPoint:CGPointMake(width - _arrowHeight - _cornerRadius, height)];
            if(maxArrow > height - _cornerRadius) {
                CGFloat desiredX = width - _arrowHeight;
                CGFloat desiredY = maxArrow;
                CGFloat m = -1.0f / _arrowSlope;
                CGFloat x = width - _arrowHeight + sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat y = ((x - desiredX) * m) + desiredY;
                [path addCurveToPoint:CGPointMake(x, y)
                        controlPoint1:CGPointMake(width - _arrowHeight, height)
                        controlPoint2:CGPointMake(desiredX, desiredY)];
            } else {
                [path addArcWithCenter:CGPointMake(width - _arrowHeight - _cornerRadius, height - _cornerRadius) radius:_cornerRadius startAngle:M_PI / 2.0f endAngle:0 clockwise:NO];
                [path addLineToPoint:CGPointMake(width - _arrowHeight, maxArrow)];
            }
            [path addLineToPoint:CGPointMake(width, maxArrow - (_arrowBase / 2.0f))];
            if(minArrow < _cornerRadius) {
                CGFloat desiredX = width - _arrowHeight;
                CGFloat desiredY = minArrow;
                CGFloat m = 1.0f / _arrowSlope;
                CGFloat x = width - _arrowHeight + sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat y = ((x - desiredX) * m) + desiredY;
                [path addLineToPoint:CGPointMake(x, y)];
                [path addCurveToPoint:CGPointMake(width - _arrowHeight - _cornerRadius, 0.0f)
                        controlPoint1:CGPointMake(desiredX, desiredY)
                        controlPoint2:CGPointMake(width - _arrowHeight, 0.0f)];
            } else {
                [path addLineToPoint:CGPointMake(width - _arrowHeight, minArrow)];
                [path addLineToPoint:CGPointMake(width - _arrowHeight, _cornerRadius)];
                [path addArcWithCenter:CGPointMake(width - _arrowHeight - _cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:2.0f * M_PI endAngle:3.0f * M_PI / 2.0f clockwise:NO];
            }
            [path closePath];
            return path;
            break;
        }
        case UIPopoverArrowDirectionLeft: {
            [path moveToPoint:CGPointMake(_arrowHeight + _cornerRadius, height)];
            [path addLineToPoint:CGPointMake(width - _cornerRadius, height)];
            [path addArcWithCenter:CGPointMake(width - _cornerRadius, height - _cornerRadius) radius:_cornerRadius startAngle:M_PI / 2.0f endAngle:0 clockwise:NO];
            [path addLineToPoint:CGPointMake(width, _cornerRadius)];
            [path addArcWithCenter:CGPointMake(width - _cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:2.0f * M_PI endAngle:3.0f * M_PI / 2.0f clockwise:NO];
            [path addLineToPoint:CGPointMake(_arrowHeight + _cornerRadius, 0.0f)];
            if(minArrow < _cornerRadius) {
                CGFloat desiredX = _arrowHeight;
                CGFloat desiredY = minArrow;
                CGFloat m = -1.0f / _arrowSlope;
                CGFloat x = _arrowHeight - sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat y = ((x - desiredX) * m) + desiredY;
                [path addCurveToPoint:CGPointMake(x, y)
                        controlPoint1:CGPointMake(_arrowHeight, 0.0f)
                        controlPoint2:CGPointMake(desiredX, desiredY)];
            } else {
                [path addArcWithCenter:CGPointMake(_arrowHeight + _cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:3.0f * M_PI / 2.0f endAngle:M_PI clockwise:NO];
                [path addLineToPoint:CGPointMake(_arrowHeight, minArrow)];
            }
            [path addLineToPoint:CGPointMake(0.0f, minArrow + (_arrowBase / 2.0f))];
            if(maxArrow > height - _cornerRadius) {
                CGFloat desiredX = _arrowHeight;
                CGFloat desiredY = maxArrow;
                CGFloat m = 1.0f / _arrowSlope;
                CGFloat x = _arrowHeight - sqrtf((_cornerRadius * _cornerRadius) / 2.0f);
                CGFloat y = ((x - desiredX) * m) + desiredY;
                [path addLineToPoint:CGPointMake(x, y)];
                [path addCurveToPoint:CGPointMake(_arrowHeight + _cornerRadius, height)
                        controlPoint1:CGPointMake(desiredX, desiredY)
                        controlPoint2:CGPointMake(_arrowHeight, height)];
            } else {
                [path addLineToPoint:CGPointMake(_arrowHeight, maxArrow)];
                [path addLineToPoint:CGPointMake(_arrowHeight, height - _cornerRadius)];
                [path addArcWithCenter:CGPointMake(_arrowHeight + _cornerRadius, height - _cornerRadius) radius:_cornerRadius startAngle:M_PI endAngle:M_PI / 2.0f clockwise:NO];
            }
            [path closePath];
            return path;
            break;
        }
        default: {
            CGRect frame = CGRectMake(0, 0, width, height - _arrowHeight);
            return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:_cornerRadius];
            break;
        }
    }
}

- (CGGradientRef)createArrowGradient:(CGColorSpaceRef)colorSpace
{
    if(_arrowDirection == UIPopoverArrowDirectionUp) {
        UIColor *topColor = nil;
        UIColor *bottomColor = nil;
        if(_upArrowGradientTopColor || _upArrowGradientBottomColor) {
            if(_upArrowGradientTopColor) {
                topColor = _upArrowGradientTopColor;
            } else {
                topColor = [UIColor clearColor];
            }
            if(_upArrowGradientBottomColor) {
                bottomColor = _upArrowGradientBottomColor;
            } else if(_gradientTopColor) {
                bottomColor = _gradientTopColor;
            } else {
                bottomColor = [UIColor clearColor];
            }
        } else if(_gradientTopColor) {
            topColor = _gradientTopColor;
            bottomColor = _gradientTopColor;
        }
        if(topColor && bottomColor) {
            CGFloat locations[] = {0.0, 1.0};
            NSArray *colors = @[(id)topColor.CGColor, (id)bottomColor.CGColor];
            return CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
        }
    }
    return nil;
}

- (CGGradientRef)createGradient:(CGColorSpaceRef)colorSpace
{
    if(_gradientTopColor) {
        UIColor *bottomColor;
        if(_gradientBottomColor) {
            bottomColor = _gradientBottomColor;
        } else {
            bottomColor = [UIColor clearColor];
        }
        CGFloat locations[] = {0.0, 1.0};
        NSArray *colors = @[(id)_gradientTopColor.CGColor, (id)bottomColor.CGColor];
        return CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    }
    return nil;
}

- (void)updateBackgroundImage
{
    UIBezierPath *path = [self pathForPopover];
    currentPath = path;
    [self setClipsToBounds:self.clipsToBounds];
    self.layer.shadowPath = path.CGPath;

    UIColor *backgroundColor;
    if(_backgroundColor) {
        backgroundColor = _backgroundColor;
    } else {
        backgroundColor = [UIColor blackColor];
    };

    UIImage *image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    NSMutableArray *gradients = [NSMutableArray array];
    NSMutableArray *points = [NSMutableArray array];

    CGGradientRef arrowGradient = [self createArrowGradient:colorSpace];
    if(arrowGradient) {
        [gradients addObject:(__bridge id)arrowGradient];
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(1.0f, 0.0f)]];
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(1.0f, _arrowHeight)]];
    }
    CGGradientRef bodyGradient = [self createGradient:colorSpace];
    if(bodyGradient) {
        [gradients addObject:(__bridge id)bodyGradient];
        CGFloat y = self.bounds.size.height;
        CGFloat yOffset = 0.0f;
        if(_arrowDirection == UIPopoverArrowDirectionUp) {
            yOffset = _arrowHeight;
        }
        if(_gradientHeight) {
            y = _gradientHeight;
        }
        if(points.count == 0) {
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(1.0f, yOffset)]];
        }
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(1.0f, y + yOffset)]];
    }

    if(arrowGradient || bodyGradient) {
        image = [UIImage imageWithGradients:gradients points:points inPath:path withBackground:backgroundColor];
        if(arrowGradient) {
            CGGradientRelease(arrowGradient);
        }
        if(bodyGradient) {
            CGGradientRelease(bodyGradient);
        }
    } else {
        image = [UIImage imageWithColor:backgroundColor inPath:path];
    }
    CGColorSpaceRelease(colorSpace);
    backgroundView.image = [image resizableImageWithCapInsets:[self resizeInsets] resizingMode:UIImageResizingModeStretch];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection
{
    BOOL needsBackgroundImageUpdate = !backgroundView.image;
    if(arrowDirection != _arrowDirection) {
        _arrowDirection = arrowDirection;
        needsBackgroundImageUpdate = YES;
    }
    if(needsBackgroundImageUpdate) {
        [self updateBackgroundImage];
    }
}

- (void)setArrowOffset:(CGFloat)arrowOffset
{
    BOOL needsBackgroundImageUpdate = !backgroundView.image;
    if(arrowOffset != _arrowOffset) {
        UIEdgeInsets oldInsets = [self resizeInsets];
        _arrowOffset = arrowOffset;
        UIEdgeInsets newInsets = [self resizeInsets];
        if(!UIEdgeInsetsEqualToEdgeInsets(oldInsets, newInsets)) {
            needsBackgroundImageUpdate = YES;
        }
    }
    if(needsBackgroundImageUpdate) {
        [self updateBackgroundImage];
    }
}

+ (CGFloat)arrowBase
{
    return _arrowBase;
}

+ (void)setArrowBase:(CGFloat)arrowBase
{
    _arrowBase = arrowBase;
    _arrowSlope = _arrowHeight / (_arrowBase / 2.0f);
}

+ (CGFloat)arrowHeight
{
    return _arrowHeight;
}

+ (void)setArrowHeight:(CGFloat)arrowHeight
{
    _arrowHeight = arrowHeight;
    _arrowSlope = _arrowHeight / (_arrowBase / 2.0f);
}

+ (CGFloat)cornerRadius
{
    return _cornerRadius;
}

+ (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
}

+ (UIEdgeInsets)contentViewInsets
{
    return _contentViewInsets;
}

+ (void)setContentViewInsets:(UIEdgeInsets)contentViewInsets
{
    _contentViewInsets = contentViewInsets;
}

+ (BOOL)wantsDefaultContentAppearance
{
    return NO;
}

@end
