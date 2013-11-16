//
//  VSTheme.m
//  Q Branch LLC
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSTheme.h"

#import "NSString+Tools.h"
#import "UIBezierPath+Tools.h"
#import "UIColor+Tools.h"
#import "UIImage+Drawing.h"


@interface VSTheme ()

@property (nonatomic, strong) NSDictionary *themeDictionary;
@property (nonatomic, strong) NSCache *colorCache;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSCache *fontCache;

- (id)objectForKey:(id)key;
- (NSArray *)resolveKey:(id)key withSubkey:(NSString *)subkey;

@end


@implementation VSTheme

- (id)initWithDictionary:(NSDictionary *)themeDictionary
{
	self = [super init];
	if (self) {
        _themeDictionary = themeDictionary;
        _colorCache = [[NSCache alloc] init];
        _imageCache = [[NSCache alloc] init];
        _fontCache = [[NSCache alloc] init];
        _defaultColor = [UIColor blackColor];
        _defaultFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
	return self;
}


- (id)objectForKey:(id)key
{
    if (!key) {
        return nil;
    }
    id obj = nil;
    if ([key isKindOfClass:NSString.class]) {
        obj = [self.themeDictionary valueForKeyPath:key];
    } else if ([key isKindOfClass:NSArray.class]) {
        for (NSString *s in key) {
            obj = [self.themeDictionary valueForKeyPath:s];
            if (obj) {
                break;
            }
        }
    }
    if (!obj && self.parentTheme) {
        obj = [self.parentTheme objectForKey:key];
    }
    if (obj && [obj isKindOfClass:NSString.class] && [obj hasPrefix:@"@"]) {
        obj = [self objectForKey:[((NSString *)obj) substringFromIndex:1]];
    }
    return obj;
}


- (NSArray *)resolveKey:(id)key withSubkey:(NSString *)subkey
{
    if (!key || ([key isKindOfClass:NSArray.class] && [key count] == 0)) {
        return nil;
    }
    if (![key isKindOfClass:NSArray.class]) {
        key = @[key];
    }
    if (!subkey) {
        return key;
    }
    NSMutableArray *resolvedKeys = [NSMutableArray array];
    for (NSString *s in key) {
        [resolvedKeys addObject:[NSString stringWithFormat:@"%@.%@", s, subkey]];
    }
    return resolvedKeys;
}


- (BOOL)hasKey:(id)key
{
    return [self hasKey:key withSubkey:nil];
}

- (BOOL)hasKey:(id)key withSubkey:(NSString *)subkey
{
    return !!([self objectForKey:[self resolveKey:key withSubkey:subkey]]);
}


- (BOOL)boolForKey:(id)key
{
    return [self boolForKey:key withSubkey:nil withDefault:NO];
}

- (BOOL)boolForKey:(id)key withDefault:(BOOL)value
{
    return [self boolForKey:key withSubkey:nil withDefault:value];
}

- (BOOL)boolForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self boolForKey:key withSubkey:subkey withDefault:NO];
}

- (BOOL)boolForKey:(id)key withSubkey:(NSString *)subkey withDefault:(BOOL)value
{
	id obj = [self objectForKey:[self resolveKey:key withSubkey:subkey]];
	if (!obj) {
        return value;
    }
    return [obj boolValue];
}


- (NSString *)stringForKey:(id)key
{
    return [self stringForKey:key withSubkey:nil withDefault:nil];
}

- (NSString *)stringForKey:(id)key withDefault:(NSString *)value
{
    return [self stringForKey:key withSubkey:nil withDefault:value];
}

- (NSString *)stringForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self stringForKey:key withSubkey:subkey withDefault:nil];
}

- (NSString *)stringForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSString *)value
{
	id obj = [self objectForKey:[self resolveKey:key withSubkey:subkey]];
	if (!obj) {
		return value;
    }
	if ([obj isKindOfClass:NSString.class]) {
		return obj;
    }
	if ([obj isKindOfClass:NSNumber.class]) {
		return [obj stringValue];
    }
    if ([obj isKindOfClass:NSDictionary.class]) {
        return nil;
    }
	return [NSString stringWithFormat:@"%@", obj];
}


- (NSInteger)integerForKey:(id)key
{
    return [self integerForKey:key withSubkey:nil withDefault:0];
}

- (NSInteger)integerForKey:(id)key withDefault:(NSInteger)value
{
    return [self integerForKey:key withSubkey:nil withDefault:value];
}

- (NSInteger)integerForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self integerForKey:key withSubkey:subkey withDefault:0];
}

- (NSInteger)integerForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSInteger)value
{
	id obj = [self objectForKey:[self resolveKey:key withSubkey:subkey]];
	if (!obj) {
		return value;
    }
	return [obj integerValue];
}


- (CGFloat)floatForKey:(id)key
{
    return [self floatForKey:key withSubkey:nil withDefault:0.0f];
}

- (CGFloat)floatForKey:(id)key withDefault:(CGFloat)value
{
    return [self floatForKey:key withSubkey:nil withDefault:value];
}

- (CGFloat)floatForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self floatForKey:key withSubkey:subkey withDefault:0.0f];
}

- (CGFloat)floatForKey:(id)key withSubkey:(NSString *)subkey withDefault:(CGFloat)value
{
	id obj = [self objectForKey:[self resolveKey:key withSubkey:subkey]];
	if (!obj) {
		return value;
    }
	return [obj floatValue];
}


- (NSTimeInterval)timeIntervalForKey:(id)key
{
    return [self timeIntervalForKey:key withSubkey:nil withDefault:0];
}

- (NSTimeInterval)timeIntervalForKey:(id)key withDefault:(NSTimeInterval)value
{
    return [self timeIntervalForKey:key withSubkey:nil withDefault:value];
}

- (NSTimeInterval)timeIntervalForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self timeIntervalForKey:key withSubkey:subkey withDefault:0];
}

- (NSTimeInterval)timeIntervalForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSTimeInterval)value
{
	id obj = [self objectForKey:[self resolveKey:key withSubkey:subkey]];
	if (!obj) {
		return value;
    }
	return [obj doubleValue];
}


- (UIImage *)imageForKey:(id)key
{
    return [self imageForKey:key withSubkey:nil withDefault:nil];
}

- (UIImage *)imageForKey:(id)key withDefault:(UIImage *)value
{
    return [self imageForKey:key withSubkey:nil withDefault:value];
}

- (UIImage *)imageForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self imageForKey:key withSubkey:subkey withDefault:nil];
}

- (UIImage *)imageForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIImage *)value
{
    key = [self resolveKey:key withSubkey:subkey];
	UIImage *cachedImage = [self.imageCache objectForKey:[key firstObject]];
	if (cachedImage) {
		return cachedImage;
    }

    UIImage *image = nil;
	NSString *imageName = [self stringForKey:key withDefault:nil];
	if (![NSString isEmpty:imageName]) {
        image = [UIImage imageNamed:imageName];
    } else {
        UIImage *template = nil;
        if ([self hasKey:key withSubkey:@"Template"]) {
            template = [self imageForKey:key withSubkey:@"Template" withDefault:nil];
        }

        UIColor *color = [self colorForKey:key withSubkey:@"Color" withDefault:nil];
        UIColor *startColor = [self colorForKey:key withSubkey:@"StartColor" withDefault:nil];
        UIColor *endColor = [self colorForKey:key withSubkey:@"EndColor" withDefault:nil];

        if (color || startColor || endColor) {
            CGSize size = [self sizeForKey:key withDefault:CGSizeMake(1.0f, 1.0f)];
            UIEdgeInsets padding = [self edgeInsetsForKey:key withSubkey:@"Padding" withDefault:UIEdgeInsetsZero];
            CGRect rect = CGRectMake(padding.left,
                                     padding.top,
                                     MAX(0.0f, size.width - padding.left - padding.right),
                                     MAX(0.0f, size.height - padding.top - padding.bottom));
            UIBezierPath *path = nil;
            if ([self hasKey:key withSubkey:@"Circular"]) {
                path = [UIBezierPath bezierPathWithOvalInRect:rect];
            } else {
                NSArray *cornerRadii = [self cornerRadiiForKey:key withSubkey:@"CornerRadius"];
                CGFloat topLeft = [cornerRadii[0] floatValue];
                CGFloat topRight = [cornerRadii[1] floatValue];
                CGFloat bottomRight = [cornerRadii[2] floatValue];
                CGFloat bottomLeft = [cornerRadii[3] floatValue];
                if (topLeft || topRight || bottomRight || bottomLeft) {
                    path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadii:cornerRadii];
                }
            }
            if (startColor || endColor) {
                if (!startColor) {
                    startColor = [UIColor clearColor];
                }
                if (!endColor) {
                    endColor = [UIColor clearColor];
                }
                if (!color) {
                    color = endColor;
                }
                if ([self hasKey:key withSubkey:@"StartPoint"] || [self hasKey:key withSubkey:@"EndPoint"]) {
                    if (template) {
                        CGFloat height = template.size.height;
                        CGFloat width = template.size.width;
                        CGPoint startPoint = [self pointForKey:key withSubkey:@"StartPoint" withDefault:CGPointMake(width / 2.0f, padding.top)];
                        CGPoint endPoint = [self pointForKey:key withSubkey:@"EndPoint" withDefault:CGPointMake(width / 2.0f, height - padding.bottom)];
                        image = [template colorizeStartColor:startColor endColor:endColor startPoint:startPoint endPoint:endPoint withBackground:color];
                    } else {
                        CGFloat height = rect.size.height;
                        CGFloat width = rect.size.width;
                        CGPoint startPoint = [self pointForKey:key withSubkey:@"StartPoint" withDefault:CGPointMake(width / 2.0f, padding.top)];
                        CGPoint endPoint = [self pointForKey:key withSubkey:@"EndPoint" withDefault:CGPointMake(width / 2.0f, height - padding.bottom)];
                        image = [UIImage imageWithGradientInPath:path withSize:size startColor:startColor endColor:endColor startPoint:startPoint endPoint:endPoint withBackground:color];
                    }
                } else {
                    if (template) {
                        CGFloat height = template.size.height;
                        CGPoint startPosition = [self pointForKey:key withSubkey:@"StartPosition" withDefault:CGPointMake(0.5f, padding.top / height)];
                        CGPoint endPosition = [self pointForKey:key withSubkey:@"EndPosition" withDefault:CGPointMake(0.5f, (height - padding.bottom) / height)];
                        image = [template colorizeStartColor:startColor endColor:endColor startPosition:startPosition endPosition:endPosition withBackground:color];
                    } else {
                        CGPoint startPosition = [self pointForKey:key withSubkey:@"StartPosition" withDefault:CGPointMake(0.5f, 0.0f)];
                        CGPoint endPosition = [self pointForKey:key withSubkey:@"EndPosition" withDefault:CGPointMake(0.5f, 1.0f)];
                        image = [UIImage imageWithGradientInPath:path withSize:size startColor:startColor endColor:endColor startPosition:startPosition endPosition:endPosition withBackground:color];
                    }
                }
            } else {
                if (template) {
                    image = [template colorize:color];
                } else {
                    image = [UIImage imageWithColor:color inPath:path withSize:size];
                }
            }
        }
        if (!image && template) {
            image = template;
        }
    }

    if (!image) {
        image = value;
    }

    if (image && [NSString isEmpty:imageName]) {
        UIEdgeInsets border = [self edgeInsetsForKey:key withSubkey:@"Border"];
        if (!UIEdgeInsetsEqualToEdgeInsets(border, UIEdgeInsetsZero)) {
            NSMutableDictionary *defaultColor = [[NSMutableDictionary alloc] init];
            if (border.top) {
                defaultColor[@"top"] = [UIColor blackColor];
            }
            if (border.right) {
                defaultColor[@"right"] = [UIColor blackColor];
            }
            if (border.bottom) {
                defaultColor[@"bottom"] = [UIColor blackColor];
            }
            if (border.left) {
                defaultColor[@"left"] = [UIColor blackColor];
            }
            NSDictionary *borderColor = [self borderColorForKey:key withSubkey:@"BorderColor" withDefault:defaultColor];
            image = [image border:borderColor width:border];
        }

        if ([self hasKey:key withSubkey:@"ClipMask"]) {
            image = [image clipMask:[self imageForKey:key withSubkey:@"ClipMask"]];
        }

        if ([self hasKey:key withSubkey:@"CapInsets"]) {
            image = [image resizableImageWithCapInsets:[self edgeInsetsForKey:key withSubkey:@"CapInsets"]];
        }
    }

    // Do not cache named images, the OS already caches them
    if (image && [NSString isEmpty:imageName]) {
        [self.imageCache setObject:image forKey:[key firstObject]];
    }
    return image;
}


- (UIColor *)colorForKey:(id)key
{
    return [self colorForKey:key withSubkey:nil withDefault:self.defaultColor];
}

- (UIColor *)colorForKey:(id)key withDefault:(UIColor *)value
{
    return [self colorForKey:key withSubkey:nil withDefault:value];
}

- (UIColor *)colorForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self colorForKey:key withSubkey:subkey withDefault:self.defaultColor];
}

- (UIColor *)colorForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIColor *)value
{
    key = [self resolveKey:key withSubkey:subkey];
	UIColor *cachedColor = [self.colorCache objectForKey:[key firstObject]];
	if (cachedColor) {
		return cachedColor;
    }

    UIColor *color = nil;
	NSString *colorString = [self stringForKey:key];
	if ([NSString isEmpty:colorString]) {
        color = value;
    } else {
        color = [UIColor hex:colorString];
    }
    if (color) {
        [self.colorCache setObject:color forKey:[key firstObject]];
    }
	return color;
}


- (UIEdgeInsets)edgeInsetsForKey:(id)key
{
    return [self edgeInsetsForKey:key withSubkey:nil withDefault:UIEdgeInsetsZero];
}

- (UIEdgeInsets)edgeInsetsForKey:(id)key withDefault:(UIEdgeInsets)value
{
    return [self edgeInsetsForKey:key withSubkey:nil withDefault:value];
}

- (UIEdgeInsets)edgeInsetsForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self edgeInsetsForKey:key withSubkey:subkey withDefault:UIEdgeInsetsZero];
}

- (UIEdgeInsets)edgeInsetsForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIEdgeInsets)value
{
    key = [self resolveKey:key withSubkey:subkey];
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSDictionary.class]) {
            CGFloat left = [self floatForKey:key withSubkey:@"Left" withDefault:value.left];
            CGFloat top = [self floatForKey:key withSubkey:@"Top" withDefault:value.top];
            CGFloat right = [self floatForKey:key withSubkey:@"Right" withDefault:value.right];
            CGFloat bottom = [self floatForKey:key withSubkey:@"Bottom" withDefault:value.bottom];
            return UIEdgeInsetsMake(top, left, bottom, right);
        } else {
            CGFloat defaultValue = [baseValue floatValue];
            return UIEdgeInsetsMake(defaultValue, defaultValue, defaultValue, defaultValue);
        }
    } else {
        return value;
    }
}


- (UIFont *)fontForKey:(id)key
{
    return [self fontForKey:key withSubkey:nil withDefault:nil];
}

- (UIFont *)fontForKey:(id)key withDefault:(UIFont *)value
{
    return [self fontForKey:key withSubkey:nil withDefault:value];
}

- (UIFont *)fontForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self fontForKey:key withSubkey:subkey withDefault:nil];
}

- (UIFont *)fontForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIFont *)value
{
    key = [self resolveKey:key withSubkey:subkey];
	UIFont *cachedFont = [self.fontCache objectForKey:[key firstObject]];
	if (cachedFont) {
		return cachedFont;
    }

    NSString *fontName;
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSString.class]) {
            fontName = baseValue;
        } else {
            fontName = [self stringForKey:key withSubkey:@"Name" withDefault:value.fontName];
        }
    }

	CGFloat fontSize = [self floatForKey:key withSubkey:@"Size" withDefault:value.pointSize];

	if (fontSize < 1.0f) {
		fontSize = 15.0f;
    }

	UIFont *font = nil;
    
	if ([NSString isEmpty:fontName]) {
        if ([self boolForKey:key withSubkey:@"Bold" withDefault:NO]) {
            font = [UIFont boldSystemFontOfSize:fontSize];
        } else if ([self boolForKey:key withSubkey:@"Italic" withDefault:NO]) {
            font = [UIFont italicSystemFontOfSize:fontSize];
        } else {
            font = [UIFont systemFontOfSize:fontSize];
        }
	} else {
		font = [UIFont fontWithName:fontName size:fontSize];
    }

	if (font) {
		[self.fontCache setObject:font forKey:[key firstObject]];
    }

	return font;
}


- (CGPoint)pointForKey:(id)key
{
    return [self pointForKey:key withSubkey:nil withDefault:CGPointZero];
}

- (CGPoint)pointForKey:(id)key withDefault:(CGPoint)value
{
    return [self pointForKey:key withSubkey:nil withDefault:value];
}

- (CGPoint)pointForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self pointForKey:key withSubkey:subkey withDefault:CGPointZero];
}

- (CGPoint)pointForKey:(id)key withSubkey:(NSString *)subkey withDefault:(CGPoint)value
{
    key = [self resolveKey:key withSubkey:subkey];
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSDictionary.class]) {
            CGFloat x = [self floatForKey:key withSubkey:@"X" withDefault:value.x];
            CGFloat y = [self floatForKey:key withSubkey:@"Y" withDefault:value.y];
            return CGPointMake(x, y);
        } else {
            CGFloat defaultValue = [baseValue floatValue];
            return CGPointMake(defaultValue, defaultValue);
        }
    } else {
        return value;
    }
}


- (CGSize)sizeForKey:(id)key
{
    return [self sizeForKey:key withSubkey:nil withDefault:CGSizeZero];
}

- (CGSize)sizeForKey:(id)key withDefault:(CGSize)value
{
    return [self sizeForKey:key withSubkey:nil withDefault:value];
}

- (CGSize)sizeForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self sizeForKey:key withSubkey:subkey withDefault:CGSizeZero];
}

- (CGSize)sizeForKey:(id)key withSubkey:(NSString *)subkey withDefault:(CGSize)value
{
    key = [self resolveKey:key withSubkey:subkey];
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSDictionary.class]) {
            CGFloat width = [self floatForKey:key withSubkey:@"Width" withDefault:value.width];
            CGFloat height = [self floatForKey:key withSubkey:@"Height" withDefault:value.height];
            return CGSizeMake(width, height);
        } else {
            CGFloat defaultValue = [baseValue floatValue];
            return CGSizeMake(defaultValue, defaultValue);
        }
    } else {
        return value;
    }
}


- (UIOffset)offsetForKey:(id)key
{
    return [self offsetForKey:key withSubkey:nil withDefault:UIOffsetZero];
}

- (UIOffset)offsetForKey:(id)key withDefault:(UIOffset)value
{
    return [self offsetForKey:key withSubkey:nil withDefault:value];
}

- (UIOffset)offsetForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self offsetForKey:key withSubkey:subkey withDefault:UIOffsetZero];
}

- (UIOffset)offsetForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIOffset)value
{
    key = [self resolveKey:key withSubkey:subkey];
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSDictionary.class]) {
            CGFloat horizontal = [self floatForKey:key withSubkey:@"Horizontal" withDefault:value.horizontal];
            CGFloat vertical = [self floatForKey:key withSubkey:@"Vertical" withDefault:value.vertical];
            return UIOffsetMake(horizontal, vertical);
        } else {
            CGFloat defaultValue = [baseValue floatValue];
            return UIOffsetMake(defaultValue, defaultValue);
        }
    } else {
        return value;
    }
}


- (UIViewAnimationOptions)curveForKey:(id)key
{
    return [self curveForKey:key withSubkey:nil withDefault:UIViewAnimationOptionCurveEaseInOut];
}

- (UIViewAnimationOptions)curveForKey:(id)key withDefault:(UIViewAnimationOptions)value
{
    return [self curveForKey:key withSubkey:nil withDefault:value];
}

- (UIViewAnimationOptions)curveForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self curveForKey:key withSubkey:subkey withDefault:UIViewAnimationOptionCurveEaseInOut];
}

- (UIViewAnimationOptions)curveForKey:(id)key withSubkey:(NSString *)subkey withDefault:(UIViewAnimationOptions)value
{
	NSString *curveString = [self stringForKey:key withSubkey:subkey];
	if ([NSString isEmpty:curveString]) {
		return value;
    }

	curveString = [curveString lowercaseString];
	if ([curveString isEqualToString:@"easeinout"]) {
		return UIViewAnimationOptionCurveEaseInOut;
	} else if ([curveString isEqualToString:@"easeout"]) {
		return UIViewAnimationOptionCurveEaseOut;
	} else if ([curveString isEqualToString:@"easein"]) {
		return UIViewAnimationOptionCurveEaseIn;
    } else if ([curveString isEqualToString:@"linear"]) {
		return UIViewAnimationOptionCurveLinear;
    }
    
	return value;
}


- (NSArray *)cornerRadiiForKey:(id)key
{
    return [self cornerRadiiForKey:key withSubkey:nil withDefault:@[@0.0f, @0.0f, @0.0f, @0.0f]];
}

- (NSArray *)cornerRadiiForKey:(id)key withDefault:(NSArray *)value
{
    return [self cornerRadiiForKey:key withSubkey:nil withDefault:value];
}

- (NSArray *)cornerRadiiForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self cornerRadiiForKey:key withSubkey:subkey withDefault:@[@0.0f, @0.0f, @0.0f, @0.0f]];
}

- (NSArray *)cornerRadiiForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSArray *)value
{
    key = [self resolveKey:key withSubkey:subkey];
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSDictionary.class]) {
            CGFloat topLeft = [self floatForKey:key withSubkey:@"TopLeft" withDefault:[value[0] floatValue]];
            CGFloat topRight = [self floatForKey:key withSubkey:@"TopRight" withDefault:[value[1] floatValue]];
            CGFloat bottomRight = [self floatForKey:key withSubkey:@"BottomRight" withDefault:[value[2] floatValue]];
            CGFloat bottomLeft = [self floatForKey:key withSubkey:@"BottomLeft" withDefault:[value[3] floatValue]];
            return @[[NSNumber numberWithFloat:topLeft],
                     [NSNumber numberWithFloat:topRight],
                     [NSNumber numberWithFloat:bottomRight],
                     [NSNumber numberWithFloat:bottomLeft]];
        } else {
            return @[baseValue, baseValue, baseValue, baseValue];
        }
    } else {
        return value;
    }
}


- (NSDictionary *)borderColorForKey:(id)key
{
    return [self borderColorForKey:key withSubkey:nil withDefault:nil];
}

- (NSDictionary *)borderColorForKey:(id)key withDefault:(NSDictionary *)value
{
    return [self borderColorForKey:key withSubkey:nil withDefault:value];
}

- (NSDictionary *)borderColorForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self borderColorForKey:key withSubkey:subkey withDefault:nil];
}

- (NSDictionary *)borderColorForKey:(id)key withSubkey:(NSString *)subkey withDefault:(NSDictionary *)value
{
    key = [self resolveKey:key withSubkey:subkey];
    id baseValue = [self objectForKey:key];
    if (baseValue) {
        if ([baseValue isKindOfClass:NSDictionary.class]) {
            UIColor *top = [self colorForKey:key withSubkey:@"Top" withDefault:value[@"top"]];
            UIColor *left = [self colorForKey:key withSubkey:@"Left" withDefault:value[@"left"]];
            UIColor *right = [self colorForKey:key withSubkey:@"Right" withDefault:value[@"right"]];
            UIColor *bottom = [self colorForKey:key withSubkey:@"Bottom" withDefault:value[@"bottom"]];
            NSMutableDictionary *borders = [NSMutableDictionary dictionary];
            if (top) {
                borders[@"top"] = top;
            }
            if (left) {
                borders[@"left"] = left;
            }
            if (right) {
                borders[@"right"] = right;
            }
            if (bottom) {
                borders[@"bottom"] = bottom;
            }
            return borders;
        } else {
            UIColor *defaultValue = [UIColor hex:baseValue];
            return @{@"top": defaultValue, @"left": defaultValue, @"right": defaultValue, @"bottom": defaultValue};
        }
    } else {
        return value;
    }
}


- (UIBezierPath *)roundedRectForKey:(id)key
{
    return [self roundedRectForKey:key withSubkey:nil withSize:[self sizeForKey:key withDefault:CGSizeZero]];
}

- (UIBezierPath *)roundedRectForKey:(id)key withSize:(CGSize)size
{
    return [self roundedRectForKey:key withSubkey:nil withSize:size];
}

- (UIBezierPath *)roundedRectForKey:(id)key withSubkey:(NSString *)subkey
{
    return [self roundedRectForKey:key withSubkey:subkey withSize:[self sizeForKey:key withDefault:CGSizeZero]];
}

- (UIBezierPath *)roundedRectForKey:(id)key withSubkey:(NSString *)subkey withSize:(CGSize)size
{
    key = [self resolveKey:key withSubkey:subkey];
    NSArray *cornerRadii = [self cornerRadiiForKey:key withSubkey:@"CornerRadius"];
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadii:cornerRadii];
}


- (VSAnimationSpecifier *)animationSpecifierForKey:(id)key
{
	VSAnimationSpecifier *animationSpecifier = [VSAnimationSpecifier new];

	animationSpecifier.duration = [self timeIntervalForKey:key withSubkey:@"Duration"];
	animationSpecifier.delay = [self timeIntervalForKey:key withSubkey:@"Delay"];
	animationSpecifier.curve = [self curveForKey:key withSubkey:@"Curve"];

	return animationSpecifier;
}


- (VSTextCaseTransform)textCaseTransformForKey:(id)key
{
	NSString *s = [self stringForKey:key];
	if (!s) {
		return VSTextCaseTransformNone;
    }

	if ([s caseInsensitiveCompare:@"lowercase"] == NSOrderedSame) {
		return VSTextCaseTransformLower;
	} else if ([s caseInsensitiveCompare:@"uppercase"] == NSOrderedSame) {
		return VSTextCaseTransformUpper;
    }

	return VSTextCaseTransformNone;
}


@end


@implementation VSTheme (Animations)


- (void)animateWithAnimationSpecifierKey:(NSString *)animationSpecifierKey animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    VSAnimationSpecifier *animationSpecifier = [self animationSpecifierForKey:animationSpecifierKey];

    [UIView animateWithDuration:animationSpecifier.duration delay:animationSpecifier.delay options:animationSpecifier.curve animations:animations completion:completion];
}

@end


@implementation VSAnimationSpecifier

@end
