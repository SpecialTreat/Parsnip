//
//  UIView+Tools.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface UIView (Tools)

+ (CGRect)frameWithParentSize:(CGSize)parentSize
            withParentPadding:(UIEdgeInsets)parentPadding
                     withSize:(CGSize)size
                   withMargin:(UIEdgeInsets)margin;
+ (CGRect)frameWithParentPadding:(UIEdgeInsets)parentPadding
                        withSize:(CGSize)size
                      withMargin:(UIEdgeInsets)margin;

+ (CGFloat)alignCoordinate:(CGFloat)coordinate;
+ (CGFloat)alignDimension:(CGFloat)dimension;
+ (CGPoint)alignPoint:(CGPoint)point;
+ (CGSize)alignSize:(CGSize)size;
+ (CGRect)alignRect:(CGRect)rect;

@property (nonatomic) CGRect frameAligned;
@property (nonatomic) CGPoint centerAligned;
@property (nonatomic, readonly) UIView *visualClone;

- (void)roundCorners:(NSArray *)cornerRadii;

@end
