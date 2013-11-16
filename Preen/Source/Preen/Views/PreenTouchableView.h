#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class PreenTouchableView;

@protocol PreenTouchableViewDelegate<NSObject>

- (void)touchableViewOnTouch:(PreenTouchableView *)view;

@end


@interface PreenTouchableView : UIView

@property (unsafe_unretained, nonatomic) id <PreenTouchableViewDelegate> delegate;
@property (nonatomic) NSArray *passthroughViews;
@property (nonatomic) BOOL touchForwardingDisabled;

@end
