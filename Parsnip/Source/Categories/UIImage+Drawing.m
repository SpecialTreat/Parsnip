#import "UIImage+Drawing.h"

#import <QuartzCore/QuartzCore.h>


@implementation UIImage (Drawing)

static UIImage* CLEAR_IMAGE;
static UIImage* WHITE_IMAGE;

+ (UIImage *)clearImage
{
    if (!CLEAR_IMAGE) {
        CLEAR_IMAGE = [UIImage imageWithColor:[UIColor clearColor] size:CGSizeMake(1.0f, 1.0f)];
    }
    return CLEAR_IMAGE;
}

+ (UIImage *)whiteImage
{
    if (!WHITE_IMAGE) {
        WHITE_IMAGE = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(1.0f, 1.0f)];
    }
    return WHITE_IMAGE;
}

+ (UIImage *)imageFromView:(UIView *)view
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, scale);
    if (view.layer.mask && [view.layer.mask isKindOfClass:CAShapeLayer.class]) {
        CAShapeLayer *layer = (CAShapeLayer *)view.layer.mask;
        UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:layer.path];
        [path addClip];
    } else if (view.layer.cornerRadius) {
        CGRect frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:view.layer.cornerRadius];
        [path addClip];
    }
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    return [UIImage imageWithColor:color size:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    UIGraphicsBeginImageContextWithOptions(size, (alpha == 1.0f), scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color inPath:(UIBezierPath *)path
{
    return [self imageWithColor:color inPath:path withSize:CGSizeZero];
}

+ (UIImage *)imageWithColor:(UIColor *)color inPath:(UIBezierPath *)path withSize:(CGSize)size
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        if (path) {
            size = path.bounds.size;
        } else {
            size = CGSizeMake(1.0f, 1.0f);
        }
    }
    if (path) {
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    } else {
        path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)];

        CGFloat red, green, blue, alpha;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        UIGraphicsBeginImageContextWithOptions(size, (alpha == 1.0f), scale);
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, path.CGPath);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithVerticalGradient:(CGSize)size
                            startColor:(UIColor *)startColor
                              endColor:(UIColor *)endColor
{
    return [UIImage imageWithGradient:size
                           startColor:startColor
                             endColor:endColor
                        startPosition:CGPointMake(0.5f, 0.0f)
                          endPosition:CGPointMake(0.5f, 1.0f)];
}

+ (UIImage *)imageWithGradient:(CGSize)size
                    startColor:(UIColor *)startColor
                      endColor:(UIColor *)endColor
                 startPosition:(CGPoint)startPosition
                   endPosition:(CGPoint)endPosition
{
    return [self imageWithGradient:size
                        startColor:startColor
                          endColor:endColor
                     startPosition:startPosition
                       endPosition:endPosition
                    withBackground:nil];
}

+ (UIImage *)imageWithGradient:(CGSize)size
                    startColor:(UIColor *)startColor
                      endColor:(UIColor *)endColor
                 startPosition:(CGPoint)startPosition
                   endPosition:(CGPoint)endPosition
                withBackground:(UIColor *)background
{
    CGFloat scale = [UIScreen mainScreen].scale;

    CGFloat red, green, blue, startAlpha, endAlpha, backgroundAlpha = 0.0f;
    [startColor getRed:&red green:&green blue:&blue alpha:&startAlpha];
    [endColor getRed:&red green:&green blue:&blue alpha:&endAlpha];
    [background getRed:&red green:&green blue:&blue alpha:&backgroundAlpha];
    BOOL opaque = (background && backgroundAlpha == 1.0f) || (startAlpha == 1.0f && endAlpha == 1.0f);

    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0, 1.0};
    NSArray *colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

    CGPoint startPoint = CGPointMake(startPosition.x * size.width, startPosition.y * size.height);
    CGPoint endPoint = CGPointMake(endPosition.x * size.width, endPosition.y * size.height);

    if(background) {
        CGContextSetFillColorWithColor(context, background.CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
    }
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                       startPosition:(CGPoint)startPosition
                         endPosition:(CGPoint)endPosition
{
    return [self imageWithGradientInPath:path
                              startColor:startColor
                                endColor:endColor
                           startPosition:startPosition
                             endPosition:endPosition
                          withBackground:nil];
}

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                       startPosition:(CGPoint)startPosition
                         endPosition:(CGPoint)endPosition
                      withBackground:(UIColor *)background
{
    return [self imageWithGradientInPath:path
                                withSize:CGSizeZero
                              startColor:startColor
                                endColor:endColor
                           startPosition:startPosition
                             endPosition:endPosition
                          withBackground:nil];
}

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                            withSize:(CGSize)size
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                       startPosition:(CGPoint)startPosition
                         endPosition:(CGPoint)endPosition
                      withBackground:(UIColor *)background
{
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        if (path) {
            size = path.bounds.size;
        } else {
            size = CGSizeMake(1.0f, 1.0f);
        }
    }

    CGFloat pathX = path.bounds.origin.x;
    CGFloat pathY = path.bounds.origin.y;
    
    CGPoint startPoint = CGPointMake(pathX + (startPosition.x * size.width), pathY + (startPosition.y * size.height));
    CGPoint endPoint = CGPointMake(pathX + (endPosition.x * size.width), pathY + (endPosition.y * size.height));
    return [self imageWithGradientInPath:path
                                withSize:size
                              startColor:startColor
                                endColor:endColor
                              startPoint:startPoint
                                endPoint:endPoint
                          withBackground:background];
}

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    return [self imageWithGradientInPath:path
                              startColor:startColor
                                endColor:endColor
                              startPoint:startPoint
                                endPoint:endPoint
                          withBackground:nil];
}

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
                      withBackground:(UIColor *)background
{
    return [self imageWithGradientInPath:path
                                withSize:CGSizeZero
                              startColor:startColor
                                endColor:endColor
                              startPoint:startPoint
                                endPoint:endPoint
                          withBackground:nil];
}

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                            withSize:(CGSize)size
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
                      withBackground:(UIColor *)background
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        if (path) {
            size = path.bounds.size;
        } else {
            size = CGSizeMake(1.0f, 1.0f);
        }
    }

    if (path) {
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    } else {
        path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)];

        CGFloat red, green, blue, startAlpha, endAlpha, backgroundAlpha = 0.0f;
        [startColor getRed:&red green:&green blue:&blue alpha:&startAlpha];
        [endColor getRed:&red green:&green blue:&blue alpha:&endAlpha];
        [background getRed:&red green:&green blue:&blue alpha:&backgroundAlpha];
        BOOL opaque = (background && backgroundAlpha == 1.0f) || (startAlpha == 1.0f && endAlpha == 1.0f);

        UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    }

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0, 1.0};
    NSArray *colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

    if(background) {
        CGContextSetFillColorWithColor(context, background.CGColor);
        CGContextAddPath(context, path.CGPath);
        CGContextFillPath(context);
    }

    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithGradients:(NSArray *)gradients
                         points:(NSArray *)points
                         inPath:(UIBezierPath *)path
{
    return [self imageWithGradients:gradients points:points inPath:path withBackground:nil];
}

+ (UIImage *)imageWithGradients:(NSArray *)gradients
                         points:(NSArray *)points
                         inPath:(UIBezierPath *)path
                 withBackground:(UIColor *)background
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize size = path.bounds.size;

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    if(background) {
        CGContextSetFillColorWithColor(context, background.CGColor);
        CGContextAddPath(context, path.CGPath);
        CGContextFillPath(context);
    }

    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    for(int i = 0; i < gradients.count; i++) {
        CGGradientRef gradient = (__bridge CGGradientRef)[gradients objectAtIndex:i];
        CGPoint startPoint = [[points objectAtIndex:i] CGPointValue];
        CGPoint endPoint = [[points objectAtIndex:i + 1] CGPointValue];
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)border:(NSDictionary *)color width:(UIEdgeInsets)width
{
    CGFloat h = self.size.height;
    CGFloat w = self.size.width;
	UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);

	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);

    //Draw the border around the context
    if (width.top && color[@"top"]) {
        UIColor *borderColor = color[@"top"];
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, width.top);
        CGPoint points[2] = {CGPointMake(0.0f, (width.bottom / 2.0f)), CGPointMake(w, (width.bottom / 2.0f))};
        CGContextStrokeLineSegments(context, points, 2);
    }
    if (width.top && color[@"right"]) {
        UIColor *borderColor = color[@"right"];
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, width.right);
        CGPoint points[2] = {CGPointMake(w - (width.right / 2.0f), 0.0f), CGPointMake(w - (width.right / 2.0f), h)};
        CGContextStrokeLineSegments(context, points, 2);
    }
    if (width.bottom && color[@"bottom"]) {
        UIColor *borderColor = color[@"bottom"];
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, width.bottom);
        CGPoint points[2] = {CGPointMake(0.0f, h - (width.top / 2.0f)), CGPointMake(w, h - (width.top / 2.0f))};
        CGContextStrokeLineSegments(context, points, 2);
    }
    if (width.left && color[@"left"]) {
        UIColor *borderColor = color[@"left"];
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, width.left);
        CGPoint points[2] = {CGPointMake((width.left / 2.0f), 0.0f), CGPointMake((width.left / 2.0f), h)};
        CGContextStrokeLineSegments(context, points, 2);
    }

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)clipMask:(UIImage *)clipMask
{
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    [self drawInRect:rect];
	[clipMask drawInRect:rect blendMode:kCGBlendModeDestinationOut alpha:1.0f];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return image;
}

- (UIImage *)colorize:(UIColor *)color
{
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawInRect:rect];
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextSetBlendMode(context, kCGBlendModeSourceIn);
	CGContextFillRect(context, rect);
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return image;
}

- (UIImage *)colorizeStartColor:(UIColor *)startColor
                       endColor:(UIColor *)endColor
                  startPosition:(CGPoint)startPosition
                    endPosition:(CGPoint)endPosition
                 withBackground:(UIColor *)background
{
	CGSize size = self.size;
    CGPoint startPoint = CGPointMake(startPosition.x * size.width, startPosition.y * size.height);
    CGPoint endPoint = CGPointMake(endPosition.x * size.width, endPosition.y * size.height);
    return [self colorizeStartColor:startColor
                           endColor:endColor
                         startPoint:startPoint
                           endPoint:endPoint
                     withBackground:background];
}

- (UIImage *)colorizeStartColor:(UIColor *)startColor
                       endColor:(UIColor *)endColor
                     startPoint:(CGPoint)startPoint
                       endPoint:(CGPoint)endPoint
                 withBackground:(UIColor *)background;
{
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawInRect:rect];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0, 1.0};
    NSArray *colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

    CGContextSetBlendMode(context, kCGBlendModeSourceAtop);
    if(background) {
        CGContextSetFillColorWithColor(context, background.CGColor);
        CGContextFillRect(context, rect);
    }

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
	return image;
}

- (UIImage *)drawOverImage:(UIImage *)image
{
	CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    [image drawInRect:rect];
	[self drawInRect:rect];
	UIImage *compositeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return compositeImage;
}

@end
