//
//  NSObject+Bindable.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "NSObject+Bindable.h"

#import <objc/runtime.h>


#define SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(code)                    \
    _Pragma("clang diagnostic push")                                    \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    code;                                                               \
    _Pragma("clang diagnostic pop")                                     \


#define SUPPRESS_UNDECLARED_SELECTOR_WARNING(code)            \
_Pragma("clang diagnostic push")                              \
_Pragma("clang diagnostic ignored \"-Wundeclared-selector\"") \
code;                                                         \
_Pragma("clang diagnostic pop")                               \


@implementation NSObject (Bindable)

- (void)bind:(NSObject *)instance
{
    if(!instance) {
        return;
    }
    for(NSDictionary *spec in [self getBindablePropertySpecs:instance]) {
        [instance addObserver:self forKeyPath:spec[@"property"] options:[spec[@"options"] intValue] context:nil];
    }
}

- (void)unbind:(NSObject *)instance
{
    if(!instance) {
        return;
    }
    for(NSDictionary *spec in [self getBindablePropertySpecs:instance]) {
        [instance removeObserver:self forKeyPath:spec[@"property"] context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithDictionary:change];
    args[@"instance"] = object;
    if(change[NSKeyValueChangeNotificationIsPriorKey]) {
        SEL onBeforeChangeSelector = [object onBeforeChangeSelector:keyPath];
        if([self respondsToSelector:onBeforeChangeSelector]) {
            SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(
                [self performSelectorOnMainThread:onBeforeChangeSelector withObject:args waitUntilDone:YES];
            );
        }
    } else {
        SEL onChangeSelector = [object onChangeSelector:keyPath];
        if([self respondsToSelector:onChangeSelector]) {
            SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(
                [self performSelectorOnMainThread:onChangeSelector withObject:args waitUntilDone:YES];
            );
        }
    }
}

- (SEL)onChangeSelector:(NSString *)property
{
    return [self selectorForProperty:property withEvent:@"Change"];
}

- (SEL)onBeforeChangeSelector:(NSString *)property
{
    return [self selectorForProperty:property withEvent:@"BeforeChange"];
}

- (SEL)selectorForProperty:(NSString *)property withEvent:(NSString *)event
{
    NSString *cls = NSStringFromClass([self class]);
    NSString *firstLetter = [[property substringToIndex:1] capitalizedString];
    property = [property stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
    NSString *selectorName = [NSString stringWithFormat:@"on%@%@%@:", cls, property, event];
    return NSSelectorFromString(selectorName);
}

- (NSArray *)getBindablePropertySpecs:(NSObject *)instance
{
    NSMutableArray *bindProperties;
    SUPPRESS_UNDECLARED_SELECTOR_WARNING(
        SEL bindPropertiesSelector = @selector(bindProperties);
    );
    if([instance respondsToSelector:bindPropertiesSelector]) {
        SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(
            bindProperties = [instance performSelector:bindPropertiesSelector];
        );
    } else {
        NSArray *properties = instance.properties;
        bindProperties = [NSMutableArray arrayWithCapacity:properties.count];
        for (NSString *property in properties) {
            if(![property hasPrefix:@"_"]) {
                [bindProperties addObject:property];
            }
        }
    }

    NSMutableArray *bindablePropertySpecs = [NSMutableArray array];
    for(NSString *property in bindProperties) {
        SEL onChangeSelector = [instance onChangeSelector:property];
        SEL onBeforeChangeSelector = [instance onBeforeChangeSelector:property];
        BOOL respondsToOnChangeSelector = [self respondsToSelector:onChangeSelector];
        BOOL respondsToOnBeforeChangeSelector = [self respondsToSelector:onBeforeChangeSelector];

        if(respondsToOnChangeSelector || respondsToOnBeforeChangeSelector) {
            NSKeyValueObservingOptions options = (NSKeyValueObservingOptionInitial |
                                                  NSKeyValueObservingOptionNew |
                                                  NSKeyValueObservingOptionOld);
            if(respondsToOnBeforeChangeSelector) {
                options = options | NSKeyValueObservingOptionPrior;
            }
            [bindablePropertySpecs addObject:@{@"property":property, @"options":[NSNumber numberWithInt:options]}];
        }
    }
    return bindablePropertySpecs;
}

- (NSArray *)properties
{
    Class cls = [self class];
    u_int count;
    objc_property_t* propertyList = class_copyPropertyList(cls, &count);
    NSMutableArray* properties = [NSMutableArray arrayWithCapacity:count];
    for(int i = 0; i < count; i++) {
        [properties addObject:@(property_getName(propertyList[i]))];
    }
    free(propertyList);
    return properties;
}

@end
