#import "UIDevice+Tools.h"

#import "NSString+Tools.h"


static NSString * const kGoogleChromeHTTPScheme = @"googlechrome:";
static NSString * const kGoogleChromeHTTPSScheme = @"googlechromes:";
static NSString * const kGoogleMapsScheme = @"comgooglemaps:";


@implementation UIDevice (Tools)

+ (BOOL)isIOS7
{
    return [[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending;
}

+ (BOOL)isIpad
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (BOOL)isGoogleMapsInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kGoogleMapsScheme]];
}

+ (BOOL)isChromeInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kGoogleChromeHTTPScheme]];
}

+ (BOOL)openInMaps:(NSString *)address
{
    NSString *parameters = [UIDevice urlParametersFromAddress:address];
    NSString *url;
    if([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] == NSOrderedAscending) {
        url = [NSString stringWithFormat:@"http://maps.google.com/?q=%@", parameters];
    } else {
        url = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@", parameters];
    }
    return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

+ (BOOL)openInGoogleMaps:(NSString *)address
{
    NSString *parameters = [UIDevice urlParametersFromAddress:address];
    NSString *url = [NSString stringWithFormat:@"%@://?q=%@", kGoogleMapsScheme, parameters];
    return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

+ (BOOL)openInChrome:(NSURL *)url
{
    return [UIDevice openInChrome:url createNewTab:NO];
}

+ (BOOL)openInChrome:(NSURL *)url createNewTab:(BOOL)createNewTab
{
    NSURL *chromeSimpleURL = [NSURL URLWithString:kGoogleChromeHTTPScheme];
    if([[UIApplication sharedApplication] canOpenURL:chromeSimpleURL]) {
        NSString *scheme = [url.scheme lowercaseString];

        // Replace the URL Scheme with the Chrome equivalent.
        NSString *chromeScheme = nil;
        if([scheme isEqualToString:@"http"]) {
            chromeScheme = kGoogleChromeHTTPScheme;
        } else if([scheme isEqualToString:@"https"]) {
            chromeScheme = kGoogleChromeHTTPSScheme;
        }

        // Proceed only if a valid Google Chrome URI Scheme is available.
        if (chromeScheme) {
            NSString *absoluteString = [url absoluteString];
            NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
            NSString *urlNoScheme =
            [absoluteString substringFromIndex:rangeForScheme.location + 1];
            NSString *chromeURLString =
            [chromeScheme stringByAppendingString:urlNoScheme];
            NSURL *chromeURL = [NSURL URLWithString:chromeURLString];

            // Open the URL with Google Chrome.
            return [[UIApplication sharedApplication] openURL:chromeURL];
        }
    }
    return NO;
}

+ (NSString *)urlParametersFromAddress:(NSString *)address
{
    NSArray *components = [address componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *encodedComponents = [NSMutableArray arrayWithCapacity:components.count];
    for(NSString *component in components) {
        [encodedComponents addObject:[component urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    }
    return [encodedComponents componentsJoinedByString:@"+"];
}

@end
