//
//  UIView+Tools.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "UIView+Tools.h"

#import "UIBezierPath+Tools.h"
#import "UIImage+Drawing.h"


@implementation UIView (Tools)

+ (CGRect)frameWithParentSize:(CGSize)parentSize
            withParentPadding:(UIEdgeInsets)parentPadding
                     withSize:(CGSize)size
                   withMargin:(UIEdgeInsets)margin
{
    CGFloat maxWidth = parentSize.width - parentPadding.left - parentPadding.right - margin.left - margin.right;
    CGFloat maxHeight = parentSize.height - parentPadding.top - parentPadding.bottom - margin.top - margin.bottom;
    return CGRectMake(parentPadding.left + margin.left,
                      parentPadding.top + margin.top,
                      MIN(maxWidth, size.width),
                      MIN(maxHeight, size.height));
}

+ (CGRect)frameWithParentPadding:(UIEdgeInsets)parentPadding
                        withSize:(CGSize)size
                      withMargin:(UIEdgeInsets)margin
{
    return CGRectMake(parentPadding.left + margin.left,
                      parentPadding.top + margin.top,
                      size.width,
                      size.height);
}

+ (CGFloat)alignCoordinate:(CGFloat)coordinate
{
    CGFloat scale = [UIScreen mainScreen].scale;
    if(scale == 1.0f) {
        return round(coordinate);
    } else {
        return round(coordinate * scale) / scale;
    }
}

+ (CGFloat)alignDimension:(CGFloat)dimension
{
    CGFloat scale = [UIScreen mainScreen].scale;
    if(scale == 1.0f) {
        return ceil(dimension);
    } else {
        return ceil(dimension * scale) / scale;
    }
}

+ (CGPoint)alignPoint:(CGPoint)point
{
    CGFloat scale = [UIScreen mainScreen].scale;
    if(scale == 1.0f) {
        return CGPointMake(round(point.x), round(point.y));
    } else {
        return CGPointMake(round(point.x * scale) / scale, round(point.y * scale) / scale);
    }
}

+ (CGSize)alignSize:(CGSize)size
{
    CGFloat scale = [UIScreen mainScreen].scale;
    if(scale == 1.0f) {
        return CGSizeMake(ceil(size.width), ceil(size.height));
    } else {
        return CGSizeMake(ceil(size.width * scale) / scale, ceil(size.height * scale) / scale);
    }
}

+ (CGRect)alignRect:(CGRect)rect
{
    CGFloat scale = [UIScreen mainScreen].scale;
    if(scale == 1.0f) {
        return CGRectMake(round(rect.origin.x),
                          round(rect.origin.y),
                          ceil(rect.size.width),
                          ceil(rect.size.height));
    } else {
        return CGRectMake(round(rect.origin.x * scale) / scale,
                          round(rect.origin.y * scale) / scale,
                          ceil(rect.size.width * scale) / scale,
                          ceil(rect.size.height * scale) / scale);
    }
}

- (void)setFrameAligned:(CGRect)frame
{
    self.frame = [UIView alignRect:frame];
}

- (CGRect)frameAligned
{
    return [UIView alignRect:self.frame];
}

- (void)setCenterAligned:(CGPoint)center
{
    self.center = [UIView alignPoint:center];
}

- (CGPoint)centerAligned
{
    return [UIView alignPoint:self.center];
}

- (UIView *)visualClone
{
    return [[UIImageView alloc] initWithImage:[UIImage imageFromView:self]];
}

- (void)roundCorners:(NSArray *)cornerRadii
{
    if (!cornerRadii || cornerRadii.count != 4 || (!cornerRadii[0] && !cornerRadii[1] && !cornerRadii[2] && !cornerRadii[3])) {
        self.layer.mask = nil;
    } else {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadii:cornerRadii].CGPath;
        self.layer.mask = maskLayer;
    }
}

@end
