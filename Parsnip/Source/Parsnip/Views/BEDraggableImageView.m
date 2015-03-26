//
//  BEDraggableImageView.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEDraggableImageView.h"

#import "UIView+Tools.h"


@implementation BEDraggableImageView
{
    UIImageView *imageView;
    CGPoint touchPoint;
}

@synthesize dragBounds = _dragBounds;
@synthesize delegate = _delegate;

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if(self) {
        imageView = [[UIImageView alloc] initWithImage:image];
        [self addSubview:imageView];
        
        self.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        self.dragBounds = CGRectNull;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (void)setDragBounds:(CGRect)dragBounds
{
    _dragBounds = [UIView alignRect:dragBounds];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    touchPoint = [[touches anyObject] locationInView:self];
    [_delegate beginDragImageView:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_delegate endDragImageView:self];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_delegate endDragImageView:self];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    CGPoint activePoint = [[touches anyObject] locationInView:self];
    CGPoint newPoint = CGPointMake(self.center.x + (activePoint.x - touchPoint.x),
                                   self.center.y + (activePoint.y - touchPoint.y));
    
    if(CGRectIsNull(self.dragBounds)) {
        self.dragBounds = self.superview.bounds;
    }
    
    // Constrain the horizontal position
    float midPointX = CGRectGetMidX(self.bounds);
    if (newPoint.x > (_dragBounds.origin.x + _dragBounds.size.width - midPointX)) {
        // Too far right
        newPoint.x = _dragBounds.origin.x + _dragBounds.size.width - midPointX;
    } else if (newPoint.x < (_dragBounds.origin.x + midPointX)) {
        // Too far left
        newPoint.x = _dragBounds.origin.x + midPointX;
    }
    
    // Constrain the vertical position
    float midPointY = CGRectGetMidY(self.bounds);
    if (newPoint.y > (_dragBounds.origin.y + _dragBounds.size.height - midPointY)) {
        // Too far down
        newPoint.y = _dragBounds.origin.y + _dragBounds.size.height - midPointY;
    } else if (newPoint.y < (_dragBounds.origin.y + midPointY)) {
        // Too far up
        newPoint.y = _dragBounds.origin.y + midPointY;
    }

    CGFloat deltaX = newPoint.x - self.center.x;
    CGFloat deltaY = newPoint.y - self.center.y;
    CGRect newFrame = [UIView alignRect:CGRectOffset(self.frame, deltaX, deltaY)];
    if(!CGRectEqualToRect(self.frame, newFrame)) {
        self.frame = newFrame;
        [_delegate dragImageView:self];
    }
}

@end
