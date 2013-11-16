#import <UIKit/UIKit.h>
#import "PreenDraggableImageView.h"


@interface PreenReticleView : UIView<PreenDraggableImageViewDelegate>

@property (unsafe_unretained, nonatomic, readonly) PreenDraggableImageView *activeHandle;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGRect selectedFrame;
@property (nonatomic) CGRect selectedFrameBounds;
@property (nonatomic, readonly) CGRect maxSelectedFrameBounds;
@property (nonatomic) BOOL symmetrical;
@property (nonatomic) CGFloat handleSize;
@property (nonatomic) CGFloat maskAlpha;

- (CGRect)convertSelectedFrameToViewFrame:(CGRect)frame;
- (CGRect)convertViewFrameToSelectedFrame:(CGRect)frame;

- (void)beginDragImageView:(PreenDraggableImageView *)view;
- (void)dragImageView:(PreenDraggableImageView *)view;
- (void)endDragImageView:(PreenDraggableImageView *)view;

@end
