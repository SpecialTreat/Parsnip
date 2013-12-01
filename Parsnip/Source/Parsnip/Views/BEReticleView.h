#import <UIKit/UIKit.h>
#import "BEDraggableImageView.h"


@interface BEReticleView : UIView<BEDraggableImageViewDelegate>

@property (unsafe_unretained, nonatomic, readonly) BEDraggableImageView *activeHandle;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGRect selectedFrame;
@property (nonatomic) CGRect selectedFrameBounds;
@property (nonatomic, readonly) CGRect maxSelectedFrameBounds;
@property (nonatomic) BOOL symmetrical;
@property (nonatomic) CGFloat handleSize;
@property (nonatomic) CGFloat maskAlpha;

- (CGRect)convertSelectedFrameToViewFrame:(CGRect)frame;
- (CGRect)convertViewFrameToSelectedFrame:(CGRect)frame;

- (void)beginDragImageView:(BEDraggableImageView *)view;
- (void)dragImageView:(BEDraggableImageView *)view;
- (void)endDragImageView:(BEDraggableImageView *)view;

@end
