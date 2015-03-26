//
//  NSObject+Reflection.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "NSObject+Reflection.h"

#import <objc/message.h>
#import <objc/runtime.h>


@implementation NSObject (Reflection)

- (NSString *)selectorNameToPropertyName:(NSString *)selectorName
{
    if ([selectorName rangeOfString:@"set"].location == 0) {
        NSString *property = [selectorName substringWithRange:NSMakeRange(3, selectorName.length - 4)];
        NSString *firstLetter = [[property substringToIndex:1] lowercaseString];
        return [property stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
    } else {
        return selectorName;
    }
}

- (NSString *)selectorToPropertyName:(SEL)selector
{
    return [self selectorNameToPropertyName:NSStringFromSelector(selector)];
}

- (BOOL)isPropertyPrimitive:(NSString *)propertyName
{
    objc_property_t property = class_getProperty(self.class, [propertyName UTF8String]);
    NSString *propertyAttrs = @(property_getAttributes(property));
    NSString *t = [propertyAttrs substringWithRange:NSMakeRange(1, 1)];
    return ![@"@" isEqualToString:t];
}

- (NSString *)encodedTypeOfProperty:(NSString *)propertyName
{
    objc_property_t property = class_getProperty(self.class, [propertyName UTF8String]);
    NSString *propertyAttrs = @(property_getAttributes(property));
    NSError *error;
    NSString *pattern = @"^T(.+?),";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:propertyAttrs options:0 range:NSMakeRange(0, propertyAttrs.length)];
    return [propertyAttrs substringWithRange:[result rangeAtIndex:1]];
}

- (NSString *)typeOfProperty:(NSString *)propertyName
{
    NSError *error;
    objc_property_t property = class_getProperty(self.class, [propertyName UTF8String]);
    NSString *propertyAttrs = @(property_getAttributes(property));
    NSString *t = [propertyAttrs substringWithRange:NSMakeRange(1, 1)];
    if([@"c" isEqualToString:t]) {
        return @"char";
    } else if([@"i" isEqualToString:t]) {
        return @"int";
    } else if([@"s" isEqualToString:t]) {
        return @"short";
    } else if([@"l" isEqualToString:t]) {
        return @"long";
    } else if([@"q" isEqualToString:t]) {
        return @"long long";
    } else if([@"C" isEqualToString:t]) {
        return @"unsigned char";
    } else if([@"I" isEqualToString:t]) {
        return @"unsigned int";
    } else if([@"S" isEqualToString:t]) {
        return @"unsigned short";
    } else if([@"L" isEqualToString:t]) {
        return @"unsigned long";
    } else if([@"Q" isEqualToString:t]) {
        return @"unsigned long long";
    } else if([@"f" isEqualToString:t]) {
        return @"float";
    } else if([@"d" isEqualToString:t]) {
        return @"double";
    } else if([@"B" isEqualToString:t]) {
        return @"bool";
    } else if([@"v" isEqualToString:t]) {
        return @"void";
    } else if([@"*" isEqualToString:t]) {
        return @"char *";
    } else if([@"#" isEqualToString:t]) {
        return @"Class";  // "#": A class object (Class)
    } else if([@":" isEqualToString:t]) {
        return @"SEL";  // ":": A method selector (SEL)
    } else if([@"[" isEqualToString:t]) {
        return @"array";  // "[array type]": An array
    } else if([@"{" isEqualToString:t]) {
        // "{name=type...}": A structure
        NSString *pattern = @"^T\\{(.+?)=";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        NSTextCheckingResult *result = [regex firstMatchInString:propertyAttrs options:0 range:NSMakeRange(0, propertyAttrs.length)];
        return [propertyAttrs substringWithRange:[result rangeAtIndex:1]];
    } else if([@"(" isEqualToString:t]) {
        return @"union";  // "(name=type...)": A union
    } else if([@"b" isEqualToString:t]) {
        return @"bit field";  // "bnum": A bit field of num bits
    } else if([@"^" isEqualToString:t]) {
        return @"pointer";  // "^type": A pointer to type
    } else if([@"@" isEqualToString:t]) {
        // "@": An object (whether statically typed or typed id)
        NSString *pattern = @"^T@\"(.+?)\"";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        NSTextCheckingResult *result = [regex firstMatchInString:propertyAttrs options:0 range:NSMakeRange(0, propertyAttrs.length)];
        return [propertyAttrs substringWithRange:[result rangeAtIndex:1]];
    } else {
        return @"unknown";  // "?": An unknown type (among other things, this code is used for function pointers)
    }
}

@end
