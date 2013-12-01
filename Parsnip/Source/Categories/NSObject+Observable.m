#import "NSObject+Observable.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


NSString *const OBSERVER_COUNTS_KEY = @"NSObject+Observable__observerCounts";


@implementation NSObject (Observable)

- (void)setObserverCounts:(NSMutableDictionary *)observerCounts
{
	objc_setAssociatedObject(self, &OBSERVER_COUNTS_KEY, observerCounts, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary *)observerCounts
{
    NSMutableDictionary *observerCounts = objc_getAssociatedObject(self, &OBSERVER_COUNTS_KEY);
    if(!observerCounts) {
        observerCounts = [NSMutableDictionary dictionary];
        [self setObserverCounts:observerCounts];
    }
	return observerCounts;
}

- (void)mainThreadPostNotification:(NSNotification *)notification
{
    if([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } else {
        [self performSelectorOnMainThread:@selector(mainThreadPostNotification:) withObject:notification waitUntilDone:NO];
    }
}

- (void)mainThreadAddObserver:(NSDictionary *)args
{
    if([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] addObserver:args[@"target"]
                                                 selector:NSSelectorFromString(args[@"selector"])
                                                     name:args[@"event"]
                                                   object:self];
    } else {
        [self performSelectorOnMainThread:@selector(mainThreadAddObserver:) withObject:args waitUntilDone:NO];
    }
}

- (void)mainThreadRemoveObserver:(NSDictionary *)args
{
    if([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] removeObserver:args[@"target"] name:args[@"event"] object:self];
    } else {
        [self performSelectorOnMainThread:@selector(mainThreadRemoveObserver:) withObject:args waitUntilDone:NO];
    }
}

- (void)fire:(NSString *)event
{
    [self fire:event args:nil];
}

- (void)fire:(NSString *)event args:(NSDictionary *)args
{
    if([self.observerCounts objectForKey:event]) {
        [self mainThreadPostNotification:[NSNotification notificationWithName:event object:self userInfo:args]];
    }
}

- (void)on:(NSString *)event target:(id)target action:(SEL)selector
{
    NSNumber *eventCount = [self.observerCounts objectForKey:event];
    if(!eventCount) {
        eventCount = [NSNumber numberWithInt:1];
    } else {
        eventCount = [NSNumber numberWithInt:[eventCount intValue] + 1];
    }
    [self.observerCounts setObject:eventCount forKey:event];
    [self mainThreadAddObserver:@{@"target":target, @"selector":NSStringFromSelector(selector), @"event":event}];
}

- (void)un:(NSString *)event target:(id)target
{
    NSNumber *eventCount = [self.observerCounts objectForKey:event];
    if(eventCount) {
        if([eventCount intValue] <= 1) {
            [self.observerCounts removeObjectForKey:event];
        } else {
            eventCount = [NSNumber numberWithInt:[eventCount intValue] - 1];
            [self.observerCounts setObject:eventCount forKey:event];
        }
    }
    [self mainThreadRemoveObserver:@{@"target":target, @"event":event}];
}

@end
