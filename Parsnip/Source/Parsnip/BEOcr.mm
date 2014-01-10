#import "BEOcr.h"

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


@implementation BEOcr

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
        UIImage *ocrImage = [UIImage imageFromPix:pix];

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

- (void)preOcr:(UIImage *)image completion:(void(^)(UIImage *preOcrImage))completion
{
    [BEThread background:^{
//        GPUImageGaussianBlurFilter *blur = [[GPUImageGaussianBlurFilter alloc] init];
//        blur.blurRadiusInPixels = 0.5;
//
//        GPUImageBrightnessFilter *brightness = [[GPUImageBrightnessFilter alloc] init];
//        brightness.brightness = 0.1;
//
//        GPUImageContrastFilter *contrast = [[GPUImageContrastFilter alloc] init];
//        contrast.contrast = 1.2;
//
//        GPUImageBilateralFilter *bilateral = [[GPUImageBilateralFilter alloc] init];
//
//        GPUImagePicture *imageSource = [[GPUImagePicture alloc] initWithImage:image];
//        [imageSource addTarget:blur];
//        [blur addTarget:brightness];
//        [brightness addTarget:contrast];
//        [contrast addTarget:bilateral];
//        [imageSource processImage];
//        UIImage *preOcrImage = [bilateral imageFromCurrentlyProcessedOutputWithOrientation:image.imageOrientation];

        if(completion) {
            [BEThread main:^{
                completion(image);
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
