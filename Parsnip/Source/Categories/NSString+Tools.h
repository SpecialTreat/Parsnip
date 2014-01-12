#import <Foundation/Foundation.h>


@interface NSString (Tools)

+ (BOOL)isEmpty:(NSString *)string;
+ (NSString *)uuid;

@property (nonatomic, readonly) NSString *firstLine;

- (NSString *)camelCaseToUnderscore;
- (NSString *)underscoreToCamelCase;
- (NSUInteger)numberOfMatches:(NSString *)regexPattern;
- (NSUInteger)numberOfMatches:(NSString *)regexPattern options:(NSRegularExpressionOptions)options;
- (NSArray *)partition:(NSString *)delimiter;
- (NSString *)removeRepeats:(NSString *)repeatedString;
- (NSString *)replace:(NSString *)regexPattern with:(NSString *)regexTemplate;
- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)set;
- (NSString *)stripEmptyLines;
- (NSArray *)stripEmptyLines:(NSInteger)count;
- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;

@end
