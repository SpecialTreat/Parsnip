#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, PreenZoomMode) {
    PreenZoomModeActualSize,
    PreenZoomModeFill,
    PreenZoomModeStep,
};


@interface PreenZoomableImageView : UIView<UIGestureRecognizerDelegate>

@property (unsafe_unretained, nonatomic) UIImage *image;
@property (nonatomic, readonly) CGRect zoomFrame;

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) CGFloat imageRotation;
@property (nonatomic, readonly) CGFloat imageScale;
@property (nonatomic, readonly) CGPoint imageOffset;
@property (nonatomic, readonly) CGAffineTransform imageTransform;

@property (nonatomic) BOOL allowPanEnabled;
@property (nonatomic) PreenZoomMode doubleTapZoomMode;
@property (nonatomic) BOOL doubleTapEnabled;
@property (nonatomic) BOOL panEnabled;
@property (nonatomic) BOOL pinchEnabled;
@property (nonatomic) BOOL rotationEnabled;
@property (nonatomic) BOOL tapAndHoldEnabled;

@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGFloat margin;
@property (nonatomic) CGFloat maximumZoomScale;
@property (nonatomic) CGFloat minimumZoomScale;
@property (nonatomic) CGFloat zoomStep;

- (CGFloat)minimumZoomScaleForCurrentBoundsWithMargin:(CGFloat)margin;

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end