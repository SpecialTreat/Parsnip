//
//  UIImage+Manipulation.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface UIImage (Manipulation)

- (UIImage *)autolevels;
- (UIImage *)brightness:(CGFloat)brightnessFactor;
- (UIImage *)contrast:(CGFloat)contrastFactor;
- (UIImage *)contrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor;
- (UIImage *)crop:(CGRect)rect;
- (UIImage *)gaussianBlur3x3;
- (UIImage *)gaussianBlur5x5;
- (UIImage *)grayscale;
- (BOOL)hasAlpha;
- (BOOL)isLandscape;
- (BOOL)isPortrait;
- (UIImage *)rectangle:(CGRect)rect color:(UIColor *)color width:(CGFloat)width;
- (UIImage *)reorient;
- (UIImage *)reorientToOrientation:(UIImageOrientation)imageOrientation;
- (UIImage *)resize:(CGSize)size interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizeWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize)bounds interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)rotate:(CGFloat)degrees;
- (UIImage *)thumbnail:(CGSize)size;
- (UIImage *)removeAlpha;

@end
