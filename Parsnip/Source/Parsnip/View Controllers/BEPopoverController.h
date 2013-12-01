#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BETouchableView.h"


@class BEPopoverController;

@protocol BEPopoverControllerDelegate<NSObject>

- (void)popoverControllerDidDismissPopover:(BEPopoverController *)popoverController;
- (BOOL)popoverControllerShouldDismissPopover:(BEPopoverController *)popoverController;

@end


@interface BEPopoverController : NSObject<BETouchableViewDelegate>

@property (nonatomic, retain) UIViewController *contentViewController;
@property (nonatomic, assign) id <BEPopoverControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *passthroughViews;
@property (nonatomic, readonly) UIPopoverArrowDirection popoverArrowDirection;
@property (nonatomic, readonly) CGFloat popoverArrowOffset;
@property (nonatomic, readwrite, retain) Class popoverBackgroundViewClass;
@property (nonatomic) CGSize popoverContentSize;
@property (nonatomic, readwrite) UIEdgeInsets popoverLayoutMargins;
@property (nonatomic, readonly, getter=isPopoverVisible) BOOL popoverVisible;
@property (nonatomic, readonly) UIPopoverBackgroundView *backgroundView;
@property (nonatomic) UIView *parentView;
@property (nonatomic) CGFloat maskAlpha;
@property (nonatomic, readonly) CGRect displayBounds;
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) UIView *maskView;
@property (nonatomic, readwrite) UIEdgeInsets contentViewInsets;
@property (nonatomic, readwrite) UIColor *shadowColor;
@property (nonatomic, readwrite) CGSize shadowOffset;
@property (nonatomic, readwrite) CGFloat shadowOpacity;
@property (nonatomic, readwrite) CGFloat shadowRadius;

- (id)initWithContentViewController:(UIViewController *)contentViewController;
- (void)dismissPopoverAnimated:(BOOL)animated;
- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
			   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
							   animated:(BOOL)animated;
- (void)presentPopoverFromRect:(CGRect)rect
						inView:(UIView *)view
	  permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
					  animated:(BOOL)animated;

@end
