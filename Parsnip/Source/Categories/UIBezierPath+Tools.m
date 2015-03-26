//
//  UIBezierPath+Tools.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "UIBezierPath+Tools.h"


@implementation UIBezierPath (Tools)

+ (UIBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadii:(NSArray *)cornerRadii
{
    CGFloat topLeft = [cornerRadii[0] floatValue];
    CGFloat topRight = [cornerRadii[1] floatValue];
    CGFloat bottomRight = [cornerRadii[2] floatValue];
    CGFloat bottomLeft = [cornerRadii[3] floatValue];
    if (!topLeft && !topRight && !bottomRight && !bottomLeft) {
        return [UIBezierPath bezierPathWithRect:rect];
    }

    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    CGFloat width = MAX(rect.size.width, MAX(topLeft, bottomLeft) + MAX(topRight, bottomRight));
    CGFloat height = MAX(rect.size.height, MAX(topLeft, topRight) + MAX(bottomLeft, bottomRight));

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:CGPointMake(x, y + topLeft)];
    [path addLineToPoint:CGPointMake(x, y + height - bottomLeft)];
    if (bottomLeft) {
        [path addArcWithCenter:CGPointMake(x + bottomLeft, y + height - bottomLeft) radius:bottomLeft startAngle:M_PI endAngle:M_PI / 2.0f clockwise:NO];
    }
    [path addLineToPoint:CGPointMake(x + width - bottomRight, y + height)];
    if (bottomRight) {
        [path addArcWithCenter:CGPointMake(x + width - bottomRight, y + height - bottomRight) radius:bottomRight startAngle:M_PI / 2.0f endAngle:0 clockwise:NO];
    }
    [path addLineToPoint:CGPointMake(x + width, y + topRight)];
    if (topRight) {
        [path addArcWithCenter:CGPointMake(x + width - topRight, y + topRight) radius:topRight startAngle:2.0f * M_PI endAngle:3.0f * M_PI / 2.0f clockwise:NO];
    }
    [path addLineToPoint:CGPointMake(x + topLeft, y)];
    if (topLeft) {
        [path addArcWithCenter:CGPointMake(x + topLeft, y + topLeft) radius:topLeft startAngle:3.0f * M_PI / 2.0f endAngle:M_PI clockwise:NO];
    }
    [path closePath];
    return path;
}

@end
