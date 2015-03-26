//
//  BEThread.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <Foundation/Foundation.h>


@interface BEThread : NSObject

+ (void)background:(void(^)())block;
+ (void)main:(void(^)())block;

@end
