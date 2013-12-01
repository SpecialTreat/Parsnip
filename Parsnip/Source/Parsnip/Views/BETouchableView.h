#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class BETouchableView;

@protocol BETouchableViewDelegate<NSObject>

- (void)touchableViewOnTouch:(BETouchableView *)view;

@end


@interface BETouchableView : UIView

@property (unsafe_unretained, nonatomic) id <BETouchableViewDelegate> delegate;
@property (nonatomic) NSArray *passthroughViews;
@property (nonatomic) BOOL touchForwardingDisabled;

@end
