#import <UIKit/UIKit.h>


@interface PreenScannerView : UIView

@property (nonatomic, readonly) BOOL isAnimating;
@property (nonatomic, assign) CGFloat maskAlpha;
@property (nonatomic, assign) CGFloat sweepDuration;
@property (nonatomic, assign) CGFloat fadeDuration;

- (void)hide;
- (void)hide:(BOOL)animate;
- (void)hide:(BOOL)animate completion:(void(^)(BOOL finished))completion;
- (void)show;
- (void)show:(BOOL)animate;
- (void)show:(BOOL)animate completion:(void(^)(BOOL finished))completion;

@end
