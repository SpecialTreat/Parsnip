//
//  VSThemeLoader.m
//  Q Branch LLC
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSThemeLoader.h"
#import "VSTheme.h"


@interface VSThemeLoader ()

@property (nonatomic, strong, readwrite) VSTheme *defaultTheme;
@property (nonatomic, strong, readwrite) NSDictionary *themes;

@end


@implementation VSThemeLoader

- (id)init
{
	self = [super init];
    
	if (self) {
        NSString *themesFilePath = [[NSBundle mainBundle] pathForResource:@"DB5" ofType:@"plist"];
        NSDictionary *themesPlist = [NSDictionary dictionaryWithContentsOfFile:themesFilePath];
        NSMutableDictionary *themes = [NSMutableDictionary dictionary];

        for (NSString *themeName in themesPlist) {
            VSTheme *theme = [[VSTheme alloc] initWithDictionary:themesPlist[themeName]];
            if ([[themeName lowercaseString] isEqualToString:@"default"]) {
                _defaultTheme = theme;
            }
            theme.name = themeName;
            [themes setObject:theme forKey:themeName];
        }

        for (NSString *themeName in themes) {
            VSTheme *theme = themes[themeName];
            if (theme != _defaultTheme) {
                theme.parentTheme = _defaultTheme;
            }
        }
        
        _themes = themes;
    }
	
	return self;
}


- (VSTheme *)themeNamed:(NSString *)themeName
{
    return _themes[themeName];
}

@end

