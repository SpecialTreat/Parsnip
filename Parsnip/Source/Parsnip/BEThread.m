//
//  BEThread.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEThread.h"


@implementation BEThread

+ (void)background:(void(^)())block
{
    if(block) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                block();
            }
            @catch (NSException *exception) {
                NSLog(@"Background thread: %@", exception);
            }
        });
    }
}

+ (void)main:(void(^)())block
{
    if(block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                block();
            }
            @catch (NSException *exception) {
                NSLog(@"Main thread: %@", exception);
            }
        });
    }
}

@end
