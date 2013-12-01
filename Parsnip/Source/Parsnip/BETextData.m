#import "BETextData.h"

#import "NSString+Tools.h"
#import "BEThread.h"


const int MAX_DETECT_COUNT = 100;


@implementation BETextData

+ (const CFStringRef)addressBookLabelForPhoneNumber:(NSString *)phoneNumber defaultLabel:(const CFStringRef)label
{
    if([phoneNumber numberOfMatches:@"home\\s*fax" options:NSRegularExpressionCaseInsensitive]) {
        return kABPersonPhoneHomeFAXLabel;
    } else if([phoneNumber numberOfMatches:@"fax" options:NSRegularExpressionCaseInsensitive]) {
        return kABPersonPhoneWorkFAXLabel;
    } else if([phoneNumber numberOfMatches:@"iphone" options:NSRegularExpressionCaseInsensitive]) {
        return kABPersonPhoneIPhoneLabel;
    } else if([phoneNumber numberOfMatches:@"home" options:NSRegularExpressionCaseInsensitive]) {
        return kABHomeLabel;
    } else if([phoneNumber numberOfMatches:@"work" options:NSRegularExpressionCaseInsensitive]) {
        return kABWorkLabel;
    } else if([phoneNumber numberOfMatches:@"main" options:NSRegularExpressionCaseInsensitive]) {
        return kABPersonPhoneMainLabel;
    } else if([phoneNumber numberOfMatches:@"other" options:NSRegularExpressionCaseInsensitive]) {
        return kABOtherLabel;
    } else if([phoneNumber numberOfMatches:@"cell" options:NSRegularExpressionCaseInsensitive] ||
              [phoneNumber numberOfMatches:@"mobile" options:NSRegularExpressionCaseInsensitive]) {
        return kABPersonPhoneMobileLabel;
    }
    return label;
}

+ (ABRecordRef)createPersonWithDataTypes:(NSDictionary *)dataTypes
{
    ABRecordRef person = ABPersonCreate();
    for (NSString *dataType in dataTypes) {
        CFErrorRef error;
        if([dataType isEqualToString:@"PhoneNumber"]) {
            ABMutableMultiValueRef value = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            BOOL didAdd = NO;
            for(NSArray *data in dataTypes[dataType]) {
                CFStringRef label = (didAdd)? kABOtherLabel: kABPersonPhoneMainLabel;
                label = [BETextData addressBookLabelForPhoneNumber:data[0] defaultLabel:label];
                if(ABMultiValueAddValueAndLabel(value, (__bridge CFStringRef)data[1], label, nil)) {
                    didAdd = YES;
                }
            }
            if(didAdd) {
                ABRecordSetValue(person, kABPersonPhoneProperty, value, &error);
            }
            CFRelease(value);
        } else if([dataType isEqualToString:@"Address"]) {
            for(NSArray *data in dataTypes[dataType]) {
                ABMutableMultiValueRef value = ABMultiValueCreateMutable(kABDictionaryPropertyType);
                if(ABMultiValueAddValueAndLabel(value, (__bridge CFDictionaryRef)data[1], kABHomeLabel, nil)){
                    ABRecordSetValue(person, kABPersonAddressProperty, value, &error);
                }
                CFRelease(value);
            }
        } else if([dataType isEqualToString:@"Email"]) {
            ABMutableMultiValueRef value = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            BOOL didAdd = NO;
            for(NSArray *data in dataTypes[dataType]) {
                CFStringRef label = (didAdd)? kABOtherLabel: kABPersonPhoneMainLabel;
                NSString *email = ((NSURL *)data[1]).absoluteString;
                if([email hasPrefix:@"mailto"]) {
                    email = [email substringFromIndex:7];
                }
                if(ABMultiValueAddValueAndLabel(value, (__bridge CFStringRef)email, label, nil)) {
                    didAdd = YES;
                }
            }
            if(didAdd) {
                ABRecordSetValue(person, kABPersonEmailProperty, value, &error);
            }
            CFRelease(value);
        } else if([dataType isEqualToString:@"URL"]) {
            ABMutableMultiValueRef value = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            BOOL didAdd = NO;
            for(NSArray *data in dataTypes[dataType]) {
                NSString *url = ((NSURL *)data[1]).absoluteString;
                if(ABMultiValueAddValueAndLabel(value, (__bridge CFStringRef)url, kABPersonHomePageLabel, nil)) {
                    didAdd = YES;
                }
            }
            if(didAdd) {
                ABRecordSetValue(person, kABPersonURLProperty, value, &error);
            }
            CFRelease(value);
        }
    }
    return person;
}

+ (NSDictionary *)detectDataTypes:(NSString *)text
{
    return [BETextData detectDataTypes:text stripEmpty:NO];
}

+ (NSDictionary *)detectDataTypes:(NSString *)text stripEmpty:(BOOL)stripEmpty
{
    if(stripEmpty) {
        text = [text stripEmptyLines];
    }
    NSTextCheckingType types = (NSTextCheckingTypeDate |
                                NSTextCheckingTypeAddress |
                                NSTextCheckingTypeLink |
                                // NSTextCheckingTypeTransitInformation |
                                NSTextCheckingTypePhoneNumber);
    NSRange range = NSMakeRange(0, text.length);
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:types error:&error];
    __block NSDictionary *dataTypes = @{@"Date": [NSMutableArray array],
                                        @"Address": [NSMutableArray array],
                                        @"URL": [NSMutableArray array],
                                        @"Email": [NSMutableArray array],
                                        @"PhoneNumber": [NSMutableArray array],
                                        @"TransitInformation": [NSMutableArray array]};

    __block NSUInteger count = 0;
    [detector enumerateMatchesInString:text
                               options:0
                                 range:range
                            usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                                NSString *matchText = [text substringWithRange:match.range];
                                if(match.resultType == NSTextCheckingTypeDate) {
                                    if(![matchText numberOfMatches:@"^\\d{1,2}\\s*[hH]"]) {
                                        NSArray *components;
                                        if(match.timeZone) {
                                            components = @[matchText, match.date, [NSNumber numberWithDouble:match.duration], match.timeZone];
                                        } else {
                                            components = @[matchText, match.date, [NSNumber numberWithDouble:match.duration], [NSTimeZone defaultTimeZone]];
                                        }
                                        [dataTypes[@"Date"] addObject:components];
                                    }
                                } else if(match.resultType == NSTextCheckingTypeAddress) {
                                    [dataTypes[@"Address"] addObject:@[matchText, match.addressComponents]];
                                } else if(match.resultType == NSTextCheckingTypeLink) {
                                    if([match.URL.scheme isEqualToString:@"mailto"]) {
                                        [dataTypes[@"Email"] addObject:@[matchText, match.URL]];
                                    } else {
                                        [dataTypes[@"URL"] addObject:@[matchText, match.URL]];
                                    }
                                } else if(match.resultType == NSTextCheckingTypePhoneNumber) {
                                    NSString *phoneNumber = [match.phoneNumber replace:@"[^0-9+\\-\\.]" with:@""];
                                    [dataTypes[@"PhoneNumber"] addObject:@[matchText, phoneNumber]];
                                } else if(match.resultType == NSTextCheckingTypeTransitInformation) {
                                    [dataTypes[@"TransitInformation"] addObject:@[matchText, match.components]];
                                }
                                if(++count >= MAX_DETECT_COUNT) {
                                    *stop = YES;
                                }
                            }];
    return dataTypes;
}

+ (void)detectDataTypes:(NSString *)text stripEmpty:(BOOL)stripEmpty completion:(void(^)(NSDictionary *dataTypes))completion
{
    [BEThread background:^{
        NSDictionary *dataTypes = [BETextData detectDataTypes:text stripEmpty:stripEmpty];
        if(completion) {
            [BEThread main:^{
                completion(dataTypes);
            }];
        }
    }];
}

+ (NSUInteger)detectDataTypesCount:(NSString *)text
{
    return [BETextData detectDataTypesCount:text stripEmpty:NO];
}


+ (NSUInteger)detectDataTypesCount:(NSString *)text stripEmpty:(BOOL)stripEmpty
{
    if(stripEmpty) {
        text = [text stripEmptyLines];
    }
    NSTextCheckingType types = (NSTextCheckingTypeDate |
                                NSTextCheckingTypeAddress |
                                NSTextCheckingTypeLink |
                                // NSTextCheckingTypeTransitInformation |
                                NSTextCheckingTypePhoneNumber);
    NSRange range = NSMakeRange(0, text.length);
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:types error:&error];
    return [detector numberOfMatchesInString:text options:0 range:range];
}

@end
