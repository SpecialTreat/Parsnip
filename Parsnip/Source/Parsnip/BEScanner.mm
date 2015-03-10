#import "BEScanner.h"

#import <objc/message.h>
#import "allheaders.h"
#import "baseapi.h"
#import "environ.h"
#import "imageio.h"
#import "NSString+Tools.h"
#import "BEConstants.h"
#import "BETextDataDetector.h"
#import "BEThread.h"
#import "UIImage+Tesseract.h"
#import "GPUImage.h"
#import "ZBarSDK.h"


@implementation BEScanner

static NSString *tessdataPath;

+ (void)initialize
{
    tessdataPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
    setenv("TESSDATA_PREFIX", [tessdataPath UTF8String], 1);
}

- (void)ocr:(UIImage *)image completion:(void(^)(NSString *ocrText, UIImage *ocrImage, NSString *hocrText))completion
{
    [BEThread background:^{
        CGImageRef imageRef = image.CGImage;
        int width = (int)CGImageGetWidth(imageRef);
        int height = (int)CGImageGetHeight(imageRef);
        int bytesPerLine  = (int)CGImageGetBytesPerRow(imageRef);
        int bytesPerPixel = (int)CGImageGetBitsPerPixel(imageRef) / 8.0f;
        CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));

        tesseract::TessBaseAPI *tesseractEngine = new tesseract::TessBaseAPI();
        tesseractEngine->Init([tessdataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng", tesseract::OEM_TESSERACT_ONLY);

        tesseractEngine->SetImage(CFDataGetBytePtr(imageData), width, height, bytesPerPixel, bytesPerLine);

        Pix *pix = tesseractEngine->GetThresholdedImage();
        UIImage *ocrImage = [UIImage imageFrom1bppPix:pix];

        char* textChars = tesseractEngine->GetUTF8Text();
        NSString *ocrText = @(textChars);
        delete[] textChars;

        char* hocrChars = tesseractEngine->GetHOCRText(0);
        NSString *hocrText = @(hocrChars);
        delete[] hocrChars;

        delete tesseractEngine;
        CFRelease(imageData);
        
        pixFreeData(pix);
        free(pix);

        if(completion) {
            [BEThread main:^{
                completion(ocrText, ocrImage, hocrText);
            }];
        }
    }];
}

- (void)postOcr:(NSString *)text completion:(void(^)(NSString *postOcrText))completion
{
    [BEThread background:^{
        NSMutableArray *lines = [NSMutableArray array];
        NSString *trimmed = [text stringByTrimmingLeadingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for(NSString *s in [trimmed componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
            NSString *line = s;
            line = [self tryReplacement:@selector(replaceTilde:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replaceBrackets:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replacePipeWithUpperI:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replacePipeWith1:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replacePipeWithSlash:) inText:line strict:YES];
            line = [self tryReplacement:@selector(replacePipeWithLowerL:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replace0WithLowerO:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replace0WithUpperO:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replaceP0WithPO:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replaceROBoxWithPOBox:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replacePeriodInAddress:) inText:line strict:NO];
            line = [self tryReplacement:@selector(replaceLowerOWith0:) inText:line strict:YES];
            line = [self tryReplacement:@selector(replaceUpperOWith0:) inText:line strict:YES];
            [lines addObject:line];
        }
        NSString *postText = [lines componentsJoinedByString:@"\n"];
        if(completion) {
            [BEThread main:^{
                completion(postText);
            }];
        }
    }];
}

- (NSString *)simplifyVCard:(NSString *)vcard
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *lines = [vcard componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *name = nil;
    NSString *fullName = nil;
    for (NSString *line in lines) {
        NSString *s = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![s isEqualToString:@""] &&
            ![s isEqualToString:@"BEGIN:VCARD"] &&
            ![s isEqualToString:@"END:VCARD"] &&
            ![s hasPrefix:@"VERSION"] &&
            ![s hasPrefix:@"PHOTO"] &&
            ![s hasPrefix:@"LOGO"] &&
            ![s hasPrefix:@"XML"] &&
            ![s hasPrefix:@"UID"] &&
            ![s hasPrefix:@"TZ"] &&
            ![s hasPrefix:@"SOUND"] &&
            ![s hasPrefix:@"SORT-STRING"] &&
            ![s hasPrefix:@"REV"] &&
            ![s hasPrefix:@"RELATED"] &&
            ![s hasPrefix:@"PRODID"] &&
            ![s hasPrefix:@"PROFILE"] &&
            ![s hasPrefix:@"CLIENTPIDMAP"] &&
            ![s hasPrefix:@"CLASS"] &&
            ![s hasPrefix:@"ANNIVERSARY"] &&
            ![s hasPrefix:@"BDAY"] &&
            ![s hasPrefix:@"GENDER"] &&
            ![s hasPrefix:@"GEO"] &&
            ![s hasPrefix:@"KEY"] &&
            ![s hasPrefix:@"KIND"] &&
            ![s hasPrefix:@"MAILER"] &&
            ![s hasPrefix:@"MEMBER"] &&
            ![s hasPrefix:@"CALADRURI"] &&
            ![s hasPrefix:@"FBURL"]) {
            NSArray *parts = [s partition:@":"];
            if ([parts[0] hasPrefix:@"ADR"]) {
                NSString *part = [parts[2] stringByReplacingOccurrencesOfString:@";" withString:@" "];
                part = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                [result addObject:part];
            } else {
                NSString *part = [parts[2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"; "]];
                if ([parts[0] hasPrefix:@"NICKNAME"]) {
                    [result addObject:[NSString stringWithFormat:@"Nickname: %@", part]];
                } else if ([parts[0] isEqualToString:@"N"]) {
                    name = [part stringByReplacingOccurrencesOfString:@";" withString:@", "];
                } else if ([parts[0] isEqualToString:@"FN"]) {
                    fullName = part;
                } else {
                    [result addObject:part];
                }
            }
        }
    }
    if (fullName) {
        [result insertObject:fullName atIndex:0];
    } else if (name) {
        [result insertObject:name atIndex:0];
    }
    [result addObject:@""];
    return [result componentsJoinedByString:@"\n"];
}

- (NSDictionary *)zBarSymbolToDictionary:(ZBarSymbol *)symbol
{
    NSString *text = symbol.data;
    if (!text) {
        text = @"";
    }
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[@"Type"] = [NSNumber numberWithInt:(int)symbol.type];
    d[@"TypeName"] = symbol.typeName;
    d[@"ConfigMask"] = [NSNumber numberWithInt:symbol.configMask];
    d[@"ModifierMask"] = [NSNumber numberWithInt:symbol.modifierMask];
    d[@"Quality"] = [NSNumber numberWithInt:symbol.quality];
    d[@"Bounds"] = @{@"X": [NSNumber numberWithFloat:symbol.bounds.origin.x],
                     @"Y": [NSNumber numberWithFloat:symbol.bounds.origin.y],
                     @"Width": [NSNumber numberWithFloat:symbol.bounds.size.width],
                     @"Height": [NSNumber numberWithFloat:symbol.bounds.size.height]};
    d[@"Orientation"] = [NSString stringWithUTF8String:zbar_get_orientation_name(symbol.orientation)];
    if (symbol.components && symbol.components.count) {
        NSMutableArray *components = [NSMutableArray arrayWithCapacity:symbol.components.count];
        for (ZBarSymbol *component in symbol.components) {
            [components addObject:[self zBarSymbolToDictionary:component]];
        }
        d[@"Components"] = components;
    }

    NSMutableArray *vcards = nil;
    NSError *error = nil;
    NSRange range = NSMakeRange(0, text.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"BEGIN:VCARD.*?END:VCARD"
                                                                           options:NSRegularExpressionDotMatchesLineSeparators
                                                                             error:&error];
    NSRange vcardRange = [regex rangeOfFirstMatchInString:text options:0 range:range];
    while (vcardRange.location != NSNotFound) {
        if (!vcards) {
            vcards = [NSMutableArray array];
        }
        NSString *vcardText = [text substringWithRange:vcardRange];
        [vcards addObject:vcardText];
        NSString *simpleVCard = [self simplifyVCard:vcardText];

        text = [text stringByReplacingCharactersInRange:vcardRange withString:simpleVCard];

        NSUInteger location = vcardRange.location + simpleVCard.length;
        range = NSMakeRange(location, text.length - location);
        vcardRange = [regex rangeOfFirstMatchInString:text options:0 range:range];
    }
    if (vcards) {
        d[@"VCards"] = vcards;
    }
    d[@"Data"] = text;
    return d;
}

- (void)codeScan:(UIImage *)image completion:(void(^)(NSArray *codeScanData))completion
{
    [BEThread background:^{
        ZBarImageScanner *scanner = [[ZBarImageScanner alloc] init];

        CGImageRef cgImage = image.CGImage;
        int w = CGImageGetWidth(cgImage);
        int h = CGImageGetHeight(cgImage);

        CGSize size = CGSizeMake(w, h);

        // limit the maximum number of scan passes
        int density;
        if(size.width > 720) {
            density = (size.width / 240 + 1) / 2;
        } else {
            density = 1;
        }
        [scanner setSymbology:ZBAR_NONE config:ZBAR_CFG_X_DENSITY to:density];

        if(size.height > 720) {
            density = (size.height / 240 + 1) / 2;
        } else {
            density = 1;
        }
        [scanner setSymbology:ZBAR_NONE config:ZBAR_CFG_Y_DENSITY to:density];

        ZBarImage *zimg = [[ZBarImage alloc] initWithCGImage:cgImage];
        int nsyms = [scanner scanImage: zimg];

        NSMutableArray *array = nil;
        if (nsyms > 0) {
            array = [NSMutableArray arrayWithCapacity:nsyms];
            ZBarSymbolSet *results = scanner.results;
            results.filterSymbols = NO;
            for(ZBarSymbol *symbol in results) {
                [array addObject:[self zBarSymbolToDictionary:symbol]];
            }
        }

        if (completion) {
            [BEThread main:^{
                completion(array);
            }];

        }
    }];
}

- (void)preOcr:(UIImage *)image completion:(void(^)(UIImage *preOcrImage))completion
{
    [BEThread background:^{
        GPUImageBilateralFilter *bilateral = [[GPUImageBilateralFilter alloc] init];
        [bilateral useNextFrameForImageCapture];

        GPUImagePicture *imageSource = [[GPUImagePicture alloc] initWithImage:image];
        [imageSource addTarget:bilateral];
        [imageSource processImage];
        UIImage *preOcrImage = [bilateral imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
        if(completion) {
            [BEThread main:^{
                completion(preOcrImage);
            }];
        }
    }];
}

- (NSString *)tryReplacement:(SEL)selector inText:(NSString *)text strict:(BOOL)strict
{
    NSString *postText = objc_msgSend(self, selector, text);
    if(postText == text) {
        return text;
    }
    NSUInteger preCount = [BETextDataDetector detectDataTypesCount:text];
    NSUInteger postCount = [BETextDataDetector detectDataTypesCount:postText];
    if(postCount > preCount || (!strict && postCount == preCount)) {
        return postText;
    } else {
        return text;
    }
}

- (NSString *)replaceNumberSurrounded:(NSString *)find with:(NSString *)replace inText:(NSString *)text
{
    if([text rangeOfString:find].location != NSNotFound) {
        find = [NSString stringWithFormat:@"([0-9])%@([0-9])", find];
        replace = [NSString stringWithFormat:@"$1%@$2", replace];
        return [text replace:find with:replace];
    } else {
        return text;
    }
}

- (NSString *)replaceLowercaseSurrounded:(NSString *)find with:(NSString *)replace inText:(NSString *)text
{
    if([text rangeOfString:find].location != NSNotFound) {
        find = [NSString stringWithFormat:@"([a-z])%@([a-z])", find];
        replace = [NSString stringWithFormat:@"$1%@$2", replace];
        return [text replace:find with:replace];
    } else {
        return text;
    }
}

- (NSString *)replaceUppercaseSurrounded:(NSString *)find with:(NSString *)replace inText:(NSString *)text
{
    if([text rangeOfString:find].location != NSNotFound) {
        find = [NSString stringWithFormat:@"([A-Z])%@([A-Z])", find];
        replace = [NSString stringWithFormat:@"$1%@$2", replace];
        return [text replace:find with:replace];
    } else {
        return text;
    }
}

- (NSString *)replaceTilde:(NSString *)text
{
    if([text rangeOfString:@"~"].location != NSNotFound) {
        return [text stringByReplacingOccurrencesOfString:@"~" withString:@"-"];
    } else {
        return text;
    }
}

- (NSString *)replacePipeWithUpperI:(NSString *)text
{
    if([text rangeOfString:@"|"].location != NSNotFound) {
        NSString *pattern = @"^(\\s*)\\|(\\D)|(\\s)\\|(\\D)";
        return [text replace:pattern with:@"$1$3I$2$4"];
    } else {
        return text;
    }
}

- (NSString *)replacePipeWith1:(NSString *)text
{
    if([text rangeOfString:@"|"].location != NSNotFound) {
        NSString *pattern = @"^(\\s*)\\|(\\d|[\\-\\(\\)\\s]+\\d)|(\\s)\\|(\\d|[\\-\\(\\)\\s]+\\d)|(\\d|\\d[\\-\\(\\)\\s]+)\\|(.?)|(.?)\\|(\\d|[\\-\\(\\)\\s]+\\d)";
        return [text replace:pattern with:@"$1$3$5$71$2$4$6$8"];
    } else {
        return text;
    }
}

- (NSString *)replacePipeWithSlash:(NSString *)text
{
    if([text rangeOfString:@"|"].location != NSNotFound) {
        return [text stringByReplacingOccurrencesOfString:@"|" withString:@"/"];
    } else {
        return text;
    }
}

- (NSString *)replacePipeWithLowerL:(NSString *)text
{
    if([text rangeOfString:@"|"].location != NSNotFound) {
        return [text stringByReplacingOccurrencesOfString:@"|" withString:@"l"];
    } else {
        return text;
    }
}

- (NSString *)replace0WithLowerO:(NSString *)text
{
    return [self replaceLowercaseSurrounded:@"0" with:@"o" inText:text];
}

- (NSString *)replace0WithUpperO:(NSString *)text
{
    return [self replaceUppercaseSurrounded:@"0" with:@"O" inText:text];
}

- (NSString *)replaceP0WithPO:(NSString *)text
{
    return [text replace:@"(P)0|(P\\.)0" with:@"$1$2O"];
}

- (NSString *)replaceROBoxWithPOBox:(NSString *)text
{
    return [text replace:@"R[oO0].?\\s*[Bb][oO0][xX]" with:@"P.O. Box"];
}

- (NSString *)replacePeriodInAddress:(NSString *)text
{
    NSArray *states = [[BEConstants statesAbbr] arrayByAddingObjectsFromArray:[BEConstants states]];
    NSString *statesPattern = [states componentsJoinedByString:@"|"];
    NSString *pattern = [NSString stringWithFormat:@"\\.\\s+(%@)\\s+(\\d)", statesPattern];
    NSError *error;
    NSRange range = NSMakeRange(0, text.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if([regex numberOfMatchesInString:text options:0 range:range] > 0) {
        return [regex stringByReplacingMatchesInString:text options:0 range:range withTemplate:@", $1 $2"];
    } else {
        return text;
    }
}

- (NSString *)replaceLowerOWith0:(NSString *)text
{
    return [self replaceNumberSurrounded:@"o" with:@"0" inText:text];
}

- (NSString *)replaceUpperOWith0:(NSString *)text
{
    return [self replaceNumberSurrounded:@"O" with:@"0" inText:text];
}

- (NSString *)replaceBrackets:(NSString *)text
{
    NSUInteger closing = [text rangeOfString:@"]"].location;
    NSUInteger opening = [text rangeOfString:@"["].location;
    NSString *bracket = nil;
    if(closing != NSNotFound && opening == NSNotFound) {
        bracket = @"]";
    } else if(closing == NSNotFound && opening != NSNotFound) {
        bracket = @"[";
    }
    if(bracket) {
        NSString *pattern;

        pattern = [NSString stringWithFormat:@"(.?)%@([\\-\\(\\)\\s]+\\d|\\d)|(\\d|\\d[\\-\\(\\)\\s]+)%@(.?)", bracket, bracket];
        text = [text replace:pattern with:@"$1$31$2$4"];

        pattern = [NSString stringWithFormat:@"(.?)%@(\\D)|(\\D)%@(.?)", bracket, bracket];
        text = [text replace:pattern with:@"$1$3I$2$4"];

        if([text rangeOfString:bracket].location != NSNotFound) {
            return [text stringByReplacingOccurrencesOfString:bracket withString:@"1"];
        } else {
            return text;
        }
    } else {
        return text;
    }
}

@end
