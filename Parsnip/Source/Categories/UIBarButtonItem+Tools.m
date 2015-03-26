//
//  UIBarButtonItem+Tools.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "UIBarButtonItem+Tools.h"

#import "UIView+Tools.h"


@implementation UIBarButtonItem (Tools)

+ (UIBarButtonItem *)spacer
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

+ (UIBarButtonItem *)spacer:(CGFloat)margin
{

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = margin;
    return spacer;
}

- (UIView *)internalView
{
	UIView *view = self.customView;
	if (!view && [self respondsToSelector:@selector(view)]) {
        view = [self performSelector:@selector(view)];
	}
    return view;
}

- (UIBarButtonItem *)visualClone
{
    UIView *customView;
    if (self.customView && [self.customView isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)self.customView;
        if ([button imageForState:UIControlStateNormal]) {
            customView = [[UIImageView alloc] initWithImage:[button imageForState:UIControlStateNormal]];
        } else if ([button backgroundImageForState:UIControlStateNormal]) {
            customView = [[UIImageView alloc] initWithImage:[button backgroundImageForState:UIControlStateNormal]];
        } else {
            customView = [[UIImageView alloc] initWithImage:button.imageView.image];
        }
    } else {
        customView = self.internalView.visualClone;
    }
    return [[UIBarButtonItem alloc] initWithCustomView:customView];
}

@end
