#import "NSString+Tools.h"


@implementation NSString (Formatting)

+ (BOOL)isEmpty:(NSString *)string
{
    if (!string || [[NSNull null] isEqual:string]) {
        return YES;
    }
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([string isEqualToString:@""]) {
        return YES;
    }
    return NO;
}

+ (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidRef));
    CFRelease(uuidRef);
    return uuidString;
}

- (NSString *)firstLine
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSRange range = [trimmed rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
    if(range.location != NSNotFound) {
        return [trimmed substringWithRange:NSMakeRange(0, range.location)];
    } else {
        return trimmed;
    }
}

- (NSString *)camelCaseToUnderscore
{
    NSString *s;
    NSError *error;
    NSRegularExpression *firstCapRegex = [NSRegularExpression regularExpressionWithPattern:@"(.)([A-Z][a-z]+)" options:0 error:&error];
    NSRegularExpression *allCapRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-z0-9])([A-Z])" options:0 error:&error];
    s = [firstCapRegex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@"$1_$2"];
    s = [allCapRegex stringByReplacingMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@"$1_$2"];
    return [s lowercaseString];
}

- (NSString *)underscoreToCamelCase
{
    NSArray *components = [self componentsSeparatedByString:@"_"];
    NSMutableArray *camelCaseComponents = [NSMutableArray arrayWithCapacity:components.count];
    for(NSString *s in components) {
        if(s.length) {
            NSString *firstLetter = [[s substringToIndex:1] uppercaseString];
            [camelCaseComponents addObject:[s stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter]];
        }
    }
    return [camelCaseComponents componentsJoinedByString:@""];
}

- (NSUInteger)numberOfMatches:(NSString *)regexPattern
{
    return [self numberOfMatches:regexPattern options:0];
}

- (NSUInteger)numberOfMatches:(NSString *)regexPattern options:(NSRegularExpressionOptions)options
{
    NSError *error;
    NSRange range = NSMakeRange(0, self.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:options error:&error];
    return [regex numberOfMatchesInString:self options:0 range:range];
}

- (NSArray *)partition:(NSString *)delimiter
{
    NSRange match = [self rangeOfString:delimiter];
    if (match.location == NSNotFound) {
        return @[self, @"", @""];
    } else {
        NSString *left = [self substringWithRange: NSMakeRange(0, match.location)];
        NSString *right = [self substringWithRange: NSMakeRange(match.location + match.length, (self.length - match.location) - match.length)];
        return @[left, delimiter, right];
    }
}

- (NSString *)removeRepeats:(NSString *)repeatedString
{
    NSString *repeat = [NSString stringWithFormat:@"%@%@", repeatedString, repeatedString];
    NSString *result = self;
    NSRange range = [result rangeOfString:repeat];
    while (range.location != NSNotFound) {
        result = [result stringByReplacingOccurrencesOfString:repeat withString:repeatedString];
        range = [result rangeOfString:repeat];
    }
    return result;
}

- (NSString *)replace:(NSString *)regexPattern with:(NSString *)regexTemplate
{
    NSError *error;
    NSRange range = NSMakeRange(0, self.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&error];
    if([regex numberOfMatchesInString:self options:0 range:range] > 0) {
        return [regex stringByReplacingMatchesInString:self options:0 range:range withTemplate:regexTemplate];
    } else {
        return self;
    }
}

- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)set
{
    NSInteger i = 0;
    while(i < self.length && [set characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    return [self substringFromIndex:i];
}

- (NSString *)stripEmptyLines
{
    NSArray *lines = [self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *nonEmptyLines = [NSMutableArray arrayWithCapacity:lines.count];
    for(NSString *line in lines) {
        if([line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) {
            [nonEmptyLines addObject:line];
        }
    }
    return [nonEmptyLines componentsJoinedByString:@"\n"];
}

- (NSArray *)stripEmptyLines:(NSInteger)count
{
    NSArray *lines = [self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *nonEmptyLines = [NSMutableArray arrayWithCapacity:count];
    for (NSString *line in lines) {
        if (nonEmptyLines.count >= count) {
            break;
        } else {
            if([line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) {
                [nonEmptyLines addObject:line];
            }
        }
    }
    return nonEmptyLines;
}

- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end
