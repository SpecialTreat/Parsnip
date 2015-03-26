//
//  BETouchableView.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BETouchableView.h"


@implementation BETouchableView
{
    BOOL isTestingSuperView;
}

@synthesize delegate = _delegate;
@synthesize passthroughViews = _passthroughViews;
@synthesize touchForwardingDisabled = _touchForwardingDisabled;

- (void)dealloc
{
    self.delegate = nil;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if (isTestingSuperView) {
		return nil;
	} else if (_touchForwardingDisabled) {
		return self;
	} else {
		UIView *hitView = [super hitTest:point withEvent:event];

		if (hitView == self) {
			isTestingSuperView = YES;
			UIView *superHitView = [self.superview hitTest:point withEvent:event];
			isTestingSuperView = NO;

			if ([self isPassthroughView:superHitView]) {
				hitView = superHitView;
			}
		}

		return hitView;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self.delegate touchableViewOnTouch:self];
}

- (BOOL)isPassthroughView:(UIView *)view
{
	if (!view) {
		return NO;
	}

	if ([_passthroughViews containsObject:view]) {
		return YES;
	}

	return [self isPassthroughView:view.superview];
}

@end
