//
//  BEPopoverController.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEPopoverController.h"
#import "BEAppDelegate.h"


@implementation BEPopoverController
{
	BETouchableView *_maskView;
    CGRect anchorRect;
    UIPopoverArrowDirection permittedArrowDirections;
    BOOL customContentViewInsets;
}

@synthesize contentViewController = _contentViewController;
@synthesize delegate = _delegate;
@synthesize passthroughViews = _passthroughViews;
@synthesize popoverArrowDirection = _popoverArrowDirection;
@synthesize popoverArrowOffset = _popoverArrowOffset;
@synthesize popoverBackgroundViewClass = _popoverBackgroundViewClass;
@synthesize popoverContentSize = _popoverContentSize;
@synthesize popoverVisible = _popoverVisible;
@synthesize backgroundView = _backgroundView;
@synthesize maskView = _maskView;
@synthesize parentView = _parentView;
@synthesize view = _view;
@synthesize maskAlpha = _maskAlpha;
@synthesize contentViewInsets = _contentViewInsets;
@synthesize shadowColor = _shadowColor;
@synthesize shadowOffset = _shadowOffset;
@synthesize shadowOpacity = _shadowOpacity;
@synthesize shadowRadius = _shadowRadius;

- (id)init
{
    return [self initWithContentViewController:nil];
}

- (id)initWithContentViewController:(UIViewController *)viewController
{
    self = [super init];
	if (self) {
        customContentViewInsets = NO;
		self.contentViewController = viewController;
        self.popoverLayoutMargins = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        self.maskAlpha = 0.0f;
        self.shadowColor = [UIColor blackColor];
        self.shadowOffset = CGSizeMake(0.0f, 3.0f);
        self.shadowOpacity = 0.5f;
        self.shadowRadius = 10.f;
	}
	return self;
}

- (void)dealloc
{
    _maskView.delegate = nil;
    self.delegate = nil;
}

- (void)setContentViewController:(UIViewController *)viewController
{
	if (viewController != _contentViewController) {
		_contentViewController = viewController;
		_popoverContentSize = CGSizeZero;
	}
}

- (void)setPassthroughViews:(NSArray *)array
{
	if (array) {
		_passthroughViews = [[NSArray alloc] initWithArray:array];
	} else {
        _passthroughViews = nil;
    }
    _maskView.passthroughViews = _passthroughViews;
}

- (void)setContentViewInsets:(UIEdgeInsets)contentViewInsets
{
    _contentViewInsets = contentViewInsets;
    customContentViewInsets = YES;
}

- (UIColor *)shadowColor
{
    return _shadowColor;
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    _shadowColor = shadowColor;
    _backgroundView.layer.shadowColor = shadowColor.CGColor;
}

- (CGSize)shadowOffset
{
    return _shadowOffset;
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    _shadowOffset = shadowOffset;
    _backgroundView.layer.shadowOffset = shadowOffset;
}

- (CGFloat)shadowOpacity
{
    return _shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity
{
    _shadowOpacity = shadowOpacity;
    _backgroundView.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowRadius
{
    return _shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    _shadowRadius = shadowRadius;
    _backgroundView.layer.shadowRadius = shadowRadius;
}

- (void)setMaskAlpha:(CGFloat)maskAlpha
{
    _maskAlpha = maskAlpha;
    _maskView.alpha = maskAlpha;
}

- (UIView *)parentView
{
    if (_parentView) {
        return _parentView;
    } else {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (window.subviews.count > 0) {
            return [window.subviews objectAtIndex:0];
        } else {
            return window;
        }
    }
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
	[self dismissPopoverAnimated:animated userInitiated:NO];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
			   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
							   animated:(BOOL)animated
{
	UIView *parentView = self.parentView;
	UIView *itemView = item.customView;
	if (!itemView && [item respondsToSelector:@selector(view)]) {
		itemView = [item performSelector:@selector(view)];
	}

	UIView *superview = itemView.superview;
	NSArray *subviews = superview.subviews;

	NSUInteger indexOfView = [subviews indexOfObject:itemView];
	NSUInteger subviewCount = subviews.count;

    CGRect rect = CGRectZero;
	if (subviewCount > 0 && indexOfView != NSNotFound) {
		UIView *button = [parentView.subviews objectAtIndex:indexOfView];
		rect = [button convertRect:button.bounds toView:parentView];
	}

	return [self presentPopoverFromRect:rect inView:parentView permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentPopoverFromRect:(CGRect)rect
						inView:(UIView *)view
	  permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
					  animated:(BOOL)animated
{
	[self dismissPopoverAnimated:NO];

    UINavigationController *navigationController = BEAppDelegate.topNavigationController;
    if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        navigationController.interactivePopGestureRecognizer.enabled = NO;
    }

	[_contentViewController view];

	if (CGSizeEqualToSize(_popoverContentSize, CGSizeZero)) {
		self.popoverContentSize = _contentViewController.contentSizeForViewInPopover;
	}

    UIEdgeInsets contentViewInsets = _contentViewInsets;
    if (!customContentViewInsets) {
        contentViewInsets = [self.popoverBackgroundViewClass contentViewInsets];
    }

    self.parentView = view;
    anchorRect = rect;
    permittedArrowDirections = arrowDirections;

	_view = [[UIView alloc] initWithFrame:self.parentView.bounds];
	_view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _view.clipsToBounds = YES;
	[self.parentView addSubview:_view];

	_maskView = [[BETouchableView alloc] initWithFrame:self.parentView.bounds];
	_maskView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	_maskView.backgroundColor = [UIColor blackColor];
    _maskView.alpha = self.maskAlpha;
	_maskView.delegate = self;
    _maskView.passthroughViews = _passthroughViews;
	[_view addSubview:_maskView];

    self.backgroundView = [[self.popoverBackgroundViewClass alloc] init];
    self.backgroundView.layer.shadowRadius = _shadowRadius;
    self.backgroundView.layer.shadowOpacity = _shadowOpacity;
    self.backgroundView.layer.shadowOffset = _shadowOffset;
    self.backgroundView.layer.shadowColor = _shadowColor.CGColor;
    [self updateBackgroundViewAndArrow];
	[_view addSubview:self.backgroundView];

    CGFloat arrowHeight = [self.popoverBackgroundViewClass arrowHeight];
    switch (self.popoverArrowDirection) {
        case UIPopoverArrowDirectionUp: {
            _contentViewController.view.frame = CGRectMake(contentViewInsets.left,
                                                           contentViewInsets.top + arrowHeight,
                                                           self.backgroundView.bounds.size.width - contentViewInsets.left - contentViewInsets.right,
                                                           self.backgroundView.bounds.size.height - contentViewInsets.top - contentViewInsets.bottom - arrowHeight);
            break;
        }
        case UIPopoverArrowDirectionDown: {
            _contentViewController.view.frame = CGRectMake(contentViewInsets.left,
                                                           contentViewInsets.top,
                                                           self.backgroundView.bounds.size.width - contentViewInsets.left - contentViewInsets.right,
                                                           self.backgroundView.bounds.size.height - contentViewInsets.top - contentViewInsets.bottom - arrowHeight);
            break;
        }
        case UIPopoverArrowDirectionLeft: {
            _contentViewController.view.frame = CGRectMake(contentViewInsets.left + arrowHeight,
                                                           contentViewInsets.top,
                                                           self.backgroundView.bounds.size.width - contentViewInsets.left - contentViewInsets.right - arrowHeight,
                                                           self.backgroundView.bounds.size.height - contentViewInsets.top - contentViewInsets.bottom);
            break;
        }
        case UIPopoverArrowDirectionRight: {
            _contentViewController.view.frame = CGRectMake(contentViewInsets.left,
                                                           contentViewInsets.top,
                                                           self.backgroundView.bounds.size.width - contentViewInsets.left - contentViewInsets.right - arrowHeight,
                                                           self.backgroundView.bounds.size.height - contentViewInsets.top - contentViewInsets.bottom);
            break;
        }
        default: {
            break;
        }
    }
	[self.backgroundView addSubview:_contentViewController.view];

    [_contentViewController viewWillAppear:animated];
	[self.backgroundView becomeFirstResponder];
	_popoverVisible = YES;
	if (animated) {
		_view.alpha = 0.0f;
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            _view.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [_contentViewController viewDidAppear:animated];
        }];

	} else {
        [_contentViewController viewDidAppear:animated];
	}
}

- (void)touchableViewOnTouch:(BETouchableView *)view
{
	if (_popoverVisible) {
		if (!_delegate || [_delegate popoverControllerShouldDismissPopover:self]) {
			[self dismissPopoverAnimated:YES userInitiated:YES];
		}
	}
}

- (Class)popoverBackgroundViewClass
{
    if(_popoverBackgroundViewClass) {
        return _popoverBackgroundViewClass;
    } else {
        return UIPopoverBackgroundView.class;
    }
}

- (CGRect)displayBounds
{
    return CGRectMake(self.popoverLayoutMargins.left,
                      self.popoverLayoutMargins.top,
                      self.parentView.bounds.size.width - self.popoverLayoutMargins.left - self.popoverLayoutMargins.right,
                      self.parentView.bounds.size.height - self.popoverLayoutMargins.top - self.popoverLayoutMargins.bottom);
}

- (BOOL)isPopoverVisible
{
    if (!_popoverVisible) {
        return NO;
    }
    UIView *superview = self.backgroundView;
    BOOL foundWindowAsSuperView = NO;
    while ((superview = superview.superview) != nil) {
        if ([superview isKindOfClass:[UIWindow class]]) {
            foundWindowAsSuperView = YES;
            break;
        }
    }
    return foundWindowAsSuperView;
}

- (void)setBackgroundView:(UIPopoverBackgroundView *)backgroundView
{
	if (_backgroundView != backgroundView) {
		_backgroundView = backgroundView;
	}
}

- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated
{
	if (self.backgroundView) {
        [_contentViewController viewWillDisappear:animated];
		_popoverVisible = NO;
		[self.backgroundView resignFirstResponder];


        void (^dismissCompleted)() = ^()
        {
            [_contentViewController viewDidDisappear:animated];
			[self.backgroundView removeFromSuperview];
			self.backgroundView = nil;
            [_maskView removeFromSuperview];
            _maskView = nil;
			[_view removeFromSuperview];
			_view = nil;

            UINavigationController *navigationController = BEAppDelegate.topNavigationController;
            if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
                navigationController.interactivePopGestureRecognizer.enabled = YES;
            }

            if (userInitiated) {
                [_delegate popoverControllerDidDismissPopover:self];
            }
        };

		if (animated) {
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
                _view.alpha = 0.0;
            } completion:^(BOOL finished) {
                dismissCompleted();
            }];


		} else {
            dismissCompleted();
		}
	}
}

- (void)updateBackgroundViewAndArrow
{
    UIEdgeInsets contentViewInsets = _contentViewInsets;
    CGRect displayBounds = self.displayBounds;
    CGSize desiredContentSize = CGSizeMake(self.popoverContentSize.width + contentViewInsets.left + contentViewInsets.right,
                                           self.popoverContentSize.height + contentViewInsets.top + contentViewInsets.bottom);

    CGFloat arrowHeight = [_popoverBackgroundViewClass arrowHeight];
    CGFloat arrowBase = [_popoverBackgroundViewClass arrowBase];

	UIPopoverArrowDirection bestArrowDirection = UIPopoverArrowDirectionUnknown;
    CGFloat bestArrowOffset = 0.0f;
    CGRect bestBackgroundFrame = CGRectZero;
    CGFloat smallestArrowDelta = arrowBase / 2.0f;
	CGFloat biggestArea = 0.0f;

	UIPopoverArrowDirection arrowDirection = UIPopoverArrowDirectionUp;
	while (arrowDirection <= UIPopoverArrowDirectionRight) {
		if ((permittedArrowDirections & arrowDirection)) {

            CGSize actualContentSize = CGSizeZero;
            CGRect backgroundFrame = CGRectZero;
            CGFloat arrowOffset = 0.0f;
            CGPoint anchorPoint = CGPointZero;
            CGPoint arrowPoint = CGPointZero;
            CGRect arrowRect = CGRectZero;

			switch (arrowDirection) {
				case UIPopoverArrowDirectionUp: {
					anchorPoint = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMaxY(anchorRect));
                    arrowRect = CGRectMake(anchorPoint.x - (arrowBase / 2.0f), anchorPoint.y, arrowBase, arrowHeight);

                    if ((arrowRect.origin.x + arrowBase) > (displayBounds.origin.x + displayBounds.size.width)) {
                        arrowRect.origin.x = (displayBounds.origin.x + displayBounds.size.width) - arrowBase;
                    } else if (arrowRect.origin.x < displayBounds.origin.x) {
                        arrowRect.origin.x = displayBounds.origin.x;
                    }

                    arrowPoint = CGPointMake(arrowRect.origin.x + (arrowRect.size.width / 2.0f), arrowRect.origin.y);

                    actualContentSize = CGSizeMake(MAX(0.0f, MIN(desiredContentSize.width,
                                                                 displayBounds.size.width)),
                                                   MAX(0.0f, MIN(desiredContentSize.height,
                                                                 (displayBounds.origin.y + displayBounds.size.height) -
                                                                 (arrowRect.origin.y + arrowRect.size.height))));

                    CGFloat leftAvailableSpace = (arrowPoint.x - displayBounds.origin.x);
                    CGFloat rightAvailableSpace = (displayBounds.origin.x + displayBounds.size.width) - arrowPoint.x;
                    CGFloat requiredSpace = (actualContentSize.width / 2.0f);
                    if (leftAvailableSpace < requiredSpace) {
                        arrowOffset = leftAvailableSpace - requiredSpace;
                    } else if (rightAvailableSpace < requiredSpace) {
                        arrowOffset = requiredSpace - rightAvailableSpace;
                    } else {
                        arrowOffset = 0.0f;
                    }

                    backgroundFrame = CGRectMake(arrowPoint.x - arrowOffset - requiredSpace,
                                                 arrowPoint.y,
                                                 actualContentSize.width,
                                                 actualContentSize.height + arrowHeight);
                    
					break;
                }
				case UIPopoverArrowDirectionDown: {
					anchorPoint = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMinY(anchorRect));
                    arrowRect = CGRectMake(anchorPoint.x - (arrowBase / 2.0f), anchorPoint.y - arrowHeight, arrowBase, arrowHeight);

                    if ((arrowRect.origin.x + arrowBase) > (displayBounds.origin.x + displayBounds.size.width)) {
                        arrowRect.origin.x = (displayBounds.origin.x + displayBounds.size.width) - arrowBase;
                    } else if (arrowRect.origin.x < displayBounds.origin.x) {
                        arrowRect.origin.x = displayBounds.origin.x;
                    }

                    arrowPoint = CGPointMake(arrowRect.origin.x + (arrowRect.size.width / 2.0f), arrowRect.origin.y + arrowHeight);

                    actualContentSize = CGSizeMake(MAX(0.0f, MIN(desiredContentSize.width,
                                                                 displayBounds.size.width)),
                                                   MAX(0.0f, MIN(desiredContentSize.height,
                                                                 arrowRect.origin.y - displayBounds.origin.y)));

                    CGFloat leftAvailableSpace = (arrowPoint.x - displayBounds.origin.x);
                    CGFloat rightAvailableSpace = (displayBounds.origin.x + displayBounds.size.width) - arrowPoint.x;
                    CGFloat requiredSpace = (actualContentSize.width / 2.0f);
                    if (leftAvailableSpace < requiredSpace) {
                        arrowOffset = leftAvailableSpace - requiredSpace;
                    } else if (rightAvailableSpace < requiredSpace) {
                        arrowOffset = requiredSpace - rightAvailableSpace;
                    } else {
                        arrowOffset = 0.0f;
                    }

                    backgroundFrame = CGRectMake(arrowPoint.x - arrowOffset - requiredSpace,
                                                 arrowPoint.y - arrowHeight - actualContentSize.height,
                                                 actualContentSize.width,
                                                 actualContentSize.height + arrowHeight);
                    
					break;
                }
				case UIPopoverArrowDirectionRight: {
					anchorPoint = CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMidY(anchorRect));
                    arrowRect = CGRectMake(anchorPoint.x - arrowHeight, anchorPoint.y - (arrowBase / 2.0f), arrowHeight, arrowBase);

                    if ((arrowRect.origin.y + arrowBase) > (displayBounds.origin.y + displayBounds.size.height)) {
                        arrowRect.origin.y = (displayBounds.origin.y + displayBounds.size.height) - arrowBase;
                    } else if (arrowRect.origin.y < displayBounds.origin.y) {
                        arrowRect.origin.y = displayBounds.origin.y;
                    }

                    arrowPoint = CGPointMake(arrowRect.origin.x + arrowHeight, arrowRect.origin.y + (arrowRect.size.height / 2.0f));

                    actualContentSize = CGSizeMake(MAX(0.0f, MIN(desiredContentSize.width,
                                                                 arrowRect.origin.x - displayBounds.origin.x)),
                                                   MAX(0.0f, MIN(desiredContentSize.height,
                                                                 displayBounds.size.height)));

                    CGFloat topAvailableSpace = (arrowPoint.y - displayBounds.origin.y);
                    CGFloat bottomAvailableSpace = (displayBounds.origin.y + displayBounds.size.height) - arrowPoint.y;
                    CGFloat requiredSpace = (actualContentSize.height / 2.0f);
                    if (topAvailableSpace < requiredSpace) {
                        arrowOffset = topAvailableSpace - requiredSpace;
                    } else if (bottomAvailableSpace < requiredSpace) {
                        arrowOffset = requiredSpace - bottomAvailableSpace;
                    } else {
                        arrowOffset = 0.0f;
                    }

                    backgroundFrame = CGRectMake(arrowPoint.x - arrowHeight - actualContentSize.width,
                                                 arrowPoint.y - arrowOffset - requiredSpace,
                                                 actualContentSize.width + arrowHeight,
                                                 actualContentSize.height);
                    
					break;
                }
				case UIPopoverArrowDirectionLeft: {
					anchorPoint = CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMidY(anchorRect));
                    arrowRect = CGRectMake(anchorPoint.x, anchorPoint.y - (arrowBase / 2.0f), arrowHeight, arrowBase);

                    if ((arrowRect.origin.y + arrowBase) > (displayBounds.origin.y + displayBounds.size.height)) {
                        arrowRect.origin.y = (displayBounds.origin.y + displayBounds.size.height) - arrowBase;
                    } else if (arrowRect.origin.y < displayBounds.origin.y) {
                        arrowRect.origin.y = displayBounds.origin.y;
                    }

                    arrowPoint = CGPointMake(arrowRect.origin.x, arrowRect.origin.y + (arrowRect.size.height / 2.0f));

                    actualContentSize = CGSizeMake(MAX(0.0f, MIN(desiredContentSize.width,
                                                                 (displayBounds.origin.x + displayBounds.size.width) -
                                                                 (arrowRect.origin.x + arrowRect.size.width))),
                                                   MAX(0.0f, MIN(desiredContentSize.height,
                                                                 displayBounds.size.height)));

                    CGFloat topAvailableSpace = (arrowPoint.y - displayBounds.origin.y);
                    CGFloat bottomAvailableSpace = (displayBounds.origin.y + displayBounds.size.height) - arrowPoint.y;
                    CGFloat requiredSpace = (actualContentSize.height / 2.0f);
                    if (topAvailableSpace < requiredSpace) {
                        arrowOffset = topAvailableSpace - requiredSpace;
                    } else if (bottomAvailableSpace < requiredSpace) {
                        arrowOffset = requiredSpace - bottomAvailableSpace;
                    } else {
                        arrowOffset = 0.0f;
                    }

                    backgroundFrame = CGRectMake(arrowPoint.x,
                                                 arrowPoint.y - arrowOffset - requiredSpace,
                                                 actualContentSize.width + arrowHeight,
                                                 actualContentSize.height);
                    
					break;
                }
                default: {
                    break;
                }
			}

			CGFloat area = actualContentSize.width * actualContentSize.height;

            CGFloat xDistance = arrowPoint.x - anchorPoint.x;
            CGFloat yDistance = arrowPoint.y - anchorPoint.y;
            CGFloat arrowDelta = sqrt((xDistance * xDistance) + (yDistance * yDistance));
			if (area > biggestArea || (area == biggestArea && (arrowDelta < smallestArrowDelta))) {
				biggestArea = area;
				smallestArrowDelta = arrowDelta;
                bestArrowOffset = arrowOffset;
                bestArrowDirection = arrowDirection;
                bestBackgroundFrame = backgroundFrame;
			}
		}

		arrowDirection <<= 1;
	}

    _popoverArrowDirection = bestArrowDirection;
    _popoverArrowOffset = bestArrowOffset;

    self.backgroundView.frame = bestBackgroundFrame;
    self.backgroundView.arrowOffset = bestArrowOffset;
    self.backgroundView.arrowDirection = bestArrowDirection;
}

@end
