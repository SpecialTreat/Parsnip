#import <UIKit/UIKit.h>


@interface UIImage (Drawing)

+ (UIImage *)clearImage;
+ (UIImage *)whiteImage;

+ (UIImage *)imageFromView:(UIView *)view;

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)imageWithColor:(UIColor *)color inPath:(UIBezierPath *)path;
+ (UIImage *)imageWithColor:(UIColor *)color inPath:(UIBezierPath *)path withSize:(CGSize)size;

+ (UIImage *)imageWithVerticalGradient:(CGSize)size
                            startColor:(UIColor *)startColor
                              endColor:(UIColor *)endColor;

+ (UIImage *)imageWithGradient:(CGSize)size
                    startColor:(UIColor *)startColor
                      endColor:(UIColor *)endColor
                 startPosition:(CGPoint)startPosition
                   endPosition:(CGPoint)endPosition;
+ (UIImage *)imageWithGradient:(CGSize)size
                    startColor:(UIColor *)startColor
                      endColor:(UIColor *)endColor
                 startPosition:(CGPoint)startPosition
                   endPosition:(CGPoint)endPosition
                withBackground:(UIColor *)background;

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                       startPosition:(CGPoint)startPosition
                         endPosition:(CGPoint)endPosition;
+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                       startPosition:(CGPoint)startPosition
                         endPosition:(CGPoint)endPosition
                      withBackground:(UIColor *)background;
+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                            withSize:(CGSize)size
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                       startPosition:(CGPoint)startPosition
                         endPosition:(CGPoint)endPosition
                      withBackground:(UIColor *)background;

+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint;
+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
                      withBackground:(UIColor *)background;
+ (UIImage *)imageWithGradientInPath:(UIBezierPath *)path
                            withSize:(CGSize)size
                          startColor:(UIColor *)startColor
                            endColor:(UIColor *)endColor
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
                      withBackground:(UIColor *)background;

+ (UIImage *)imageWithGradients:(NSArray *)gradients
                         points:(NSArray *)points
                         inPath:(UIBezierPath *)path;
+ (UIImage *)imageWithGradients:(NSArray *)gradients
                         points:(NSArray *)points
                         inPath:(UIBezierPath *)path
                 withBackground:(UIColor *)background;

- (UIImage *)border:(NSDictionary *)color width:(UIEdgeInsets)width;

- (UIImage *)clipMask:(UIImage *)clipMask;

- (UIImage *)colorize:(UIColor *)color;
- (UIImage *)colorizeStartColor:(UIColor *)startColor
                       endColor:(UIColor *)endColor
                  startPosition:(CGPoint)startPosition
                    endPosition:(CGPoint)endPosition
                 withBackground:(UIColor *)background;
- (UIImage *)colorizeStartColor:(UIColor *)startColor
                       endColor:(UIColor *)endColor
                     startPoint:(CGPoint)startPoint
                       endPoint:(CGPoint)endPoint
                 withBackground:(UIColor *)background;

- (UIImage *)drawOverImage:(UIImage *)image;

@end
