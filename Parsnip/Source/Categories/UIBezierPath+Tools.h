//
//  UIBezierPath+Tools.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface UIBezierPath (Tools)

+ (UIBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadii:(NSArray *)cornerRadii;

@end
