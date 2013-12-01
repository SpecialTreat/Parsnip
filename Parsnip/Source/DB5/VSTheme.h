//
//  VSTheme.h
//  Q Branch LLC
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, VSTextCaseTransform) {
    VSTextCaseTransformNone,
    VSTextCaseTransformUpper,
    VSTextCaseTransformLower
};


@class VSAnimationSpecifier;

@interface VSTheme : NSObject

- (id)initWithDictionary:(NSDictionary *)themeDictionary;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, weak) VSTheme *parentTheme;
@property (nonatomic, strong) UIColor *defaultColor;
@property (nonatomic, strong) UIFont *defaultFont;

- (BOOL)hasKey:(id)key;
- (BOOL)hasKey:(id)key withSubkey:(NSString *)subkey;

- (BOOL)boolForKey:(id)key;
- (BOOL)boolForKey:(id)key withDefault:(BOOL)value;
- (BOOL)boolForKey:(id)key withSubkey:(NSString *)subkey;
- (BOOL)boolForKey:(id)key withSubkey:(NSString *)subkey withDefault:(BOOL)value;

- (NSString *)stringForKey:(id)key;
- (NSString *)stringForKey:(id)key withDefault:(NSString *)value;
- (NSString *)stringForKey:(id)key withSubkey:(NSString *)subkey;
- (NSString *)stringForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSString *)value;

- (NSInteger)integerForKey:(id)key;
- (NSInteger)integerForKey:(id)key withDefault:(NSInteger)value;
- (NSInteger)integerForKey:(id)key withSubkey:(NSString *)subkey;
- (NSInteger)integerForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSInteger)value;

- (CGFloat)floatForKey:(id)key;
- (CGFloat)floatForKey:(id)key withDefault:(CGFloat)value;
- (CGFloat)floatForKey:(id)key withSubkey:(NSString *)subkey;
- (CGFloat)floatForKey:(id)key withSubkey:(NSString *)subkey withDefault:(CGFloat)value;

- (UIImage *)imageForKey:(id)key;
- (UIImage *)imageForKey:(id)key withDefault:(UIImage *)value;
- (UIImage *)imageForKey:(id)key withSubkey:(NSString *)subkey;
- (UIImage *)imageForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIImage *)value;

- (UIColor *)colorForKey:(id)key;
- (UIColor *)colorForKey:(id)key withDefault:(UIColor *)value;
- (UIColor *)colorForKey:(id)key withSubkey:(NSString *)subkey;
- (UIColor *)colorForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIColor *)value;

- (UIEdgeInsets)edgeInsetsForKey:(id)key;
- (UIEdgeInsets)edgeInsetsForKey:(id)key withDefault:(UIEdgeInsets)value;
- (UIEdgeInsets)edgeInsetsForKey:(id)key withSubkey:(NSString *)subkey;
- (UIEdgeInsets)edgeInsetsForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIEdgeInsets)value;

- (UIFont *)fontForKey:(id)key;
- (UIFont *)fontForKey:(id)key withDefault:(UIFont *)value;
- (UIFont *)fontForKey:(id)key withSubkey:(NSString *)subkey;
- (UIFont *)fontForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIFont *)value;

- (CGPoint)pointForKey:(id)key;
- (CGPoint)pointForKey:(id)key withDefault:(CGPoint)value;
- (CGPoint)pointForKey:(id)key withSubkey:(NSString *)subkey;
- (CGPoint)pointForKey:(id)key withSubkey:(NSString *)subkey withDefault:(CGPoint)value;

- (CGSize)sizeForKey:(id)key;
- (CGSize)sizeForKey:(id)key withDefault:(CGSize)value;
- (CGSize)sizeForKey:(id)key withSubkey:(NSString *)subkey;
- (CGSize)sizeForKey:(id)key withSubkey:(NSString *)subkey withDefault:(CGSize)value;

- (UIOffset)offsetForKey:(id)key;
- (UIOffset)offsetForKey:(id)key withDefault:(UIOffset)value;
- (UIOffset)offsetForKey:(id)key withSubkey:(NSString *)subkey;
- (UIOffset)offsetForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIOffset)value;

- (NSTimeInterval)timeIntervalForKey:(id)key;
- (NSTimeInterval)timeIntervalForKey:(id)key withDefault:(NSTimeInterval)value;
- (NSTimeInterval)timeIntervalForKey:(id)key withSubkey:(NSString *)subkey;
- (NSTimeInterval)timeIntervalForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSTimeInterval)value;

/**
 * @[TopLeft, TopRight, BottomRight, BottomLeft]
 */
- (NSArray *)cornerRadiiForKey:(id)key;
- (NSArray *)cornerRadiiForKey:(id)key withDefault:(NSArray *)value;
- (NSArray *)cornerRadiiForKey:(id)key withSubkey:(NSString *)subkey;
- (NSArray *)cornerRadiiForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSArray *)value;

/**
 * @{top: "", left: "", right: "", bottom: ""}
 */
- (NSDictionary *)borderColorForKey:(id)key;
- (NSDictionary *)borderColorForKey:(id)key withDefault:(NSDictionary *)value;
- (NSDictionary *)borderColorForKey:(id)key withSubkey:(NSString *)subkey;
- (NSDictionary *)borderColorForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSDictionary *)value;

- (UIBezierPath *)roundedRectForKey:(id)key;
- (UIBezierPath *)roundedRectForKey:(id)key withSize:(CGSize)size;
- (UIBezierPath *)roundedRectForKey:(id)key withSubkey:(NSString *)subkey;
- (UIBezierPath *)roundedRectForKey:(id)key withSubkey:(NSString *)subkey withSize:(CGSize)size;

/**
 * Possible values: easeinout, easeout, easein, linear
 */
- (UIViewAnimationOptions)curveForKey:(id)key;
- (UIViewAnimationOptions)curveForKey:(id)key withDefault:(UIViewAnimationOptions)value;
- (UIViewAnimationOptions)curveForKey:(id)key withSubkey:(NSString *)subkey;
- (UIViewAnimationOptions)curveForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIViewAnimationOptions)value;

/**
 * xDuration, xDelay, xCurve
 */
- (VSAnimationSpecifier *)animationSpecifierForKey:(id)key;

/**
 * lowercase or uppercase -- returns VSTextCaseTransformNone
 */
- (VSTextCaseTransform)textCaseTransformForKey:(id)key;

@end


@interface VSTheme (Animations)

- (void)animateWithAnimationSpecifierKey:(NSString *)animationSpecifierKey animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

@end


@interface VSAnimationSpecifier : NSObject

@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) UIViewAnimationOptions curve;

@end

