#import <UIKit/UIKit.h>


@protocol PreenDraggableImageViewDelegate;


@interface PreenDraggableImageView : UIControl

@property (nonatomic) CGRect dragBounds;
@property (unsafe_unretained, nonatomic) id<PreenDraggableImageViewDelegate> delegate;

- (id)initWithImage:(UIImage *)image;

@end


@protocol PreenDraggableImageViewDelegate
@optional
- (void)beginDragImageView:(PreenDraggableImageView *)view;
- (void)dragImageView:(PreenDraggableImageView *)view;
- (void)endDragImageView:(PreenDraggableImageView *)view;
@end
