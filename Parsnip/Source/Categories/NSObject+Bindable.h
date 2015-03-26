//
//  NSObject+Bindable.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <Foundation/Foundation.h>


@interface NSObject (Bindable)

@property (readonly) NSArray *properties;

- (void)bind:(NSObject *)instance;
- (void)unbind:(NSObject *)instance;

@end
