//
//  BETextData.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <Foundation/Foundation.h>


@interface BETextData : NSObject

@property (nonatomic, retain) NSArray *components;
@property (nonatomic, retain) NSString *dataType;
@property (nonatomic, retain) NSString *matchedText;
@property (nonatomic) NSRange range;

- (id)initWithMatchedText:(NSString *)matchedText range:(NSRange)range;

@end
