//
//  BETextData.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BETextData.h"


@implementation BETextData

@synthesize components = _components;
@synthesize dataType = _dataType;
@synthesize matchedText = _matchedText;
@synthesize range = _range;

- (id)initWithMatchedText:(NSString *)matchedText range:(NSRange)range
{
    self = [super init];
    if (self) {
        self.matchedText = matchedText;
        self.range = range;
    }
    return self;
}

@end
