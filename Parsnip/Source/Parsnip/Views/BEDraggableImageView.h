//
//  BEDraggableImageView.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@protocol BEDraggableImageViewDelegate;


@interface BEDraggableImageView : UIControl

@property (nonatomic) CGRect dragBounds;
@property (unsafe_unretained, nonatomic) id<BEDraggableImageViewDelegate> delegate;

- (id)initWithImage:(UIImage *)image;

@end


@protocol BEDraggableImageViewDelegate
@optional
- (void)beginDragImageView:(BEDraggableImageView *)view;
- (void)dragImageView:(BEDraggableImageView *)view;
- (void)endDragImageView:(BEDraggableImageView *)view;
@end
