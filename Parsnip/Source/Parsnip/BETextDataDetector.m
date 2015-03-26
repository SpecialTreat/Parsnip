//
//  BETextDataDetector.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BETextDataDetector.h"

#import "NSString+Tools.h"
#import "BETextData.h"
#import "BEThread.h"


const int MAX_DETECT_COUNT = 100;

@implementation BETextDataDetector

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
            for(BETextData *textData in dataTypes[dataType]) {
                CFStringRef label = (didAdd)? kABOtherLabel: kABPersonPhoneMainLabel;
                label = [BETextDataDetector addressBookLabelForPhoneNumber:textData.matchedText defaultLabel:label];
                if(ABMultiValueAddValueAndLabel(value, (__bridge CFStringRef)textData.components[0], label, nil)) {
                    didAdd = YES;
                }
            }
            if(didAdd) {
                ABRecordSetValue(person, kABPersonPhoneProperty, value, &error);
            }
            CFRelease(value);
        } else if([dataType isEqualToString:@"Address"]) {
            for(BETextData *textData in dataTypes[dataType]) {
                ABMutableMultiValueRef value = ABMultiValueCreateMutable(kABDictionaryPropertyType);
                if(ABMultiValueAddValueAndLabel(value, (__bridge CFDictionaryRef)textData.components[0], kABHomeLabel, nil)){
                    ABRecordSetValue(person, kABPersonAddressProperty, value, &error);
                }
                CFRelease(value);
            }
        } else if([dataType isEqualToString:@"Email"]) {
            ABMutableMultiValueRef value = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            BOOL didAdd = NO;
            for(BETextData *textData in dataTypes[dataType]) {
                CFStringRef label = (didAdd)? kABOtherLabel: kABPersonPhoneMainLabel;
                NSString *email = ((NSURL *)textData.components[0]).absoluteString;
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
            for(BETextData *textData in dataTypes[dataType]) {
                NSString *url = ((NSURL *)textData.components[0]).absoluteString;
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
    return [BETextDataDetector detectDataTypes:text stripEmpty:NO];
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
                                        @"TransitInformation": [NSMutableArray array],
                                        @"Text": [NSMutableArray array]};
    __block NSMutableDictionary *matches = [NSMutableDictionary dictionary];

    __block NSUInteger count = 0;
    __block NSUInteger endPoint = 0;
    [detector enumerateMatchesInString:text
                               options:0
                                 range:range
                            usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                if (match.range.location > endPoint) {
                                    NSRange textSectionRange = NSMakeRange(endPoint, match.range.location - endPoint);
                                    NSString *textSection = [text substringWithRange:textSectionRange];
                                    NSString *trimmedTextSection = [textSection stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                    if (trimmedTextSection && trimmedTextSection.length > 0) {
                                        BETextData *textData = [[BETextData alloc] initWithMatchedText:textSection range:textSectionRange];
                                        textData.dataType = @"Text";
                                        [dataTypes[@"Text"] addObject:textData];
                                    }
                                }
                                endPoint = match.range.location + match.range.length;
                                NSString *matchText = [text substringWithRange:match.range];
                                if (!matches[matchText]) {
                                    BETextData *textData = [[BETextData alloc] initWithMatchedText:matchText range:match.range];
                                    matches[matchText] = textData;
                                    if(match.resultType == NSTextCheckingTypeDate) {
                                        if(![matchText numberOfMatches:@"^\\d{1,2}\\s*[hH]"]) {
                                            NSArray *components;
                                            if(match.timeZone) {
                                                components = @[match.date, [NSNumber numberWithDouble:match.duration], match.timeZone];
                                            } else {
                                                components = @[match.date, [NSNumber numberWithDouble:match.duration], [NSTimeZone defaultTimeZone]];
                                            }
                                            textData.dataType = @"Date";
                                            textData.components = components;
                                            [dataTypes[@"Date"] addObject:textData];
                                        }
                                    } else if(match.resultType == NSTextCheckingTypeAddress) {
                                        textData.dataType = @"Address";
                                        textData.components = @[match.addressComponents];
                                        [dataTypes[@"Address"] addObject:textData];
                                    } else if(match.resultType == NSTextCheckingTypeLink) {
                                        if([match.URL.scheme isEqualToString:@"mailto"]) {
                                            textData.dataType = @"Email";
                                            textData.components = @[match.URL];
                                            [dataTypes[@"Email"] addObject:textData];
                                        } else {
                                            textData.dataType = @"URL";
                                            textData.components = @[match.URL];
                                            [dataTypes[@"URL"] addObject:textData];
                                        }
                                    } else if(match.resultType == NSTextCheckingTypePhoneNumber) {
                                        textData.dataType = @"PhoneNumber";
                                        textData.components = @[[match.phoneNumber replace:@"[^0-9+\\-\\.]" with:@""]];
                                        [dataTypes[@"PhoneNumber"] addObject:textData];
                                    } else if(match.resultType == NSTextCheckingTypeTransitInformation) {
                                        textData.dataType = @"TransitInformation";
                                        textData.components = @[match.components];
                                        [dataTypes[@"TransitInformation"] addObject:textData];
                                    }
                                    if(++count >= MAX_DETECT_COUNT) {
                                        *stop = YES;
                                    }
                                }
                            }];
    return dataTypes;
}

+ (void)detectDataTypes:(NSString *)text stripEmpty:(BOOL)stripEmpty completion:(void(^)(NSDictionary *dataTypes))completion
{
    [BEThread background:^{
        NSDictionary *dataTypes = [BETextDataDetector detectDataTypes:text stripEmpty:stripEmpty];
        if(completion) {
            [BEThread main:^{
                completion(dataTypes);
            }];
        }
    }];
}

+ (NSUInteger)detectDataTypesCount:(NSString *)text
{
    return [BETextDataDetector detectDataTypesCount:text stripEmpty:NO];
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
