#import "UIColor+Tools.h"


@implementation UIColor (Tools)

+ (UIColor *)hex:(NSString *)hex
{
    return [UIColor hex:hex normalize:YES];
}

+ (UIColor *)hex:(NSString *)hex normalize:(BOOL)normalize
{
	NSString *string;
    if (normalize) {
        string = [UIColor normalizeHex:hex];
    } else {
        string = hex;
    }

	unsigned int r, g, b;
	NSRange range;
	range.length = 2;
    range.location = 0;
	[[NSScanner scannerWithString:[string substringWithRange:range]] scanHexInt:&r];
	range.location = 2;
	[[NSScanner scannerWithString:[string substringWithRange:range]] scanHexInt:&g];
	range.location = 4;
	[[NSScanner scannerWithString:[string substringWithRange:range]] scanHexInt:&b];

    if ([string length] == 8) {
        unsigned int a;
        range.location = 6;
        [[NSScanner scannerWithString:[string substringWithRange:range]] scanHexInt:&a];
        return [UIColor colorWithRed:((float)r / 255.0f)
                               green:((float)g / 255.0f)
                                blue:((float)b / 255.0f)
                               alpha:((float)a / 255.0f)];
    } else {
        return [UIColor colorWithRed:((float)r / 255.0f)
                               green:((float)g / 255.0f)
                                blue:((float)b / 255.0f)
                               alpha:1.0f];
    }
}

+ (NSString *)normalizeHex:(NSString *)hex
{
	NSString *string = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

	if ([string hasPrefix:@"0X"]) {
        string = [string substringFromIndex:2];
    }
	if ([string hasPrefix:@"#"]) {
        string = [string substringFromIndex:1];
    }
    
    if (string.length == 3 || string.length == 4) {
        NSString *s1 = [string substringWithRange:NSMakeRange(0, 1)];
        NSString *s2 = [string substringWithRange:NSMakeRange(1, 1)];
        NSString *s3 = [string substringWithRange:NSMakeRange(2, 1)];
        if (string.length == 3) {
            string = [NSString stringWithFormat:@"%@%@%@%@%@%@", s1, s1, s2, s2, s3, s3];
        } else {
            NSString *s4 = [string substringWithRange:NSMakeRange(3, 1)];
            string = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@", s1, s1, s2, s2, s3, s3, s4, s4];
        }
    } else if (string.length != 6 && string.length != 8) {
        return @"000000";
    }

    return string;
}

@end
