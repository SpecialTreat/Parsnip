//
//  BEReticleView.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEReticleView.h"

#import <QuartzCore/QuartzCore.h>
#import "UIView+Tools.h"


const CGFloat HANDLE_WIDTH = 29.0f;
const CGFloat HANDLE_HEIGHT = 29.0f;
const CGFloat HANDLE_SPACER = 2.0f;
const CGFloat HANDLE_OFFSET = 13.0f;
const CGFloat HANDLE_GAP = 1.0f;
const CGFloat HANDLE_SIZE = 54.0f;
const CGFloat MIN_HANDLE_X = -6.0f;
const CGFloat MIN_HANDLE_Y = -6.0f;


@implementation BEReticleView
{
    UIView *topMask;
    UIView *leftMask;
    UIView *rightMask;
    UIView *bottomMask;
    UIView *innerMask;
    
    BEDraggableImageView *topLeft;
    BEDraggableImageView *topRight;
    BEDraggableImageView *bottomRight;
    BEDraggableImageView *bottomLeft;
}

@synthesize contentInset = _contentInset;
@synthesize symmetrical = _symmetrical;
@synthesize selectedFrame = _selectedFrame;
@synthesize selectedFrameBounds = _selectedFrameBounds;
@synthesize maxSelectedFrameBounds = _maxSelectedFrameBounds;
@synthesize activeHandle = _activeHandle;
@synthesize handleSize = _handleSize;
@synthesize maskAlpha = _maskAlpha;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _activeHandle = nil;
        _selectedFrame = CGRectZero;
        _selectedFrameBounds = CGRectZero;
        _contentInset = UIEdgeInsetsZero;

        self.handleSize = HANDLE_SIZE;
        self.maskAlpha = 0.33f;
        self.symmetrical = YES;
        
        [self initSubviews];

        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)initSubviews
{
    topMask = [[UIView alloc] init];
    topMask.backgroundColor = [UIColor blackColor];
    topMask.alpha = self.maskAlpha;
    topMask.opaque = NO;

    leftMask = [[UIView alloc] init];
    leftMask.backgroundColor = [UIColor blackColor];
    leftMask.alpha = self.maskAlpha;
    leftMask.opaque = NO;

    rightMask = [[UIView alloc] init];
    rightMask.backgroundColor = [UIColor blackColor];
    rightMask.alpha = self.maskAlpha;
    rightMask.opaque = NO;

    bottomMask = [[UIView alloc] init];
    bottomMask.backgroundColor = [UIColor blackColor];
    bottomMask.alpha = self.maskAlpha;
    bottomMask.opaque = NO;

    innerMask = [[UIView alloc] init];
    innerMask.backgroundColor = [UIColor clearColor];
    innerMask.layer.borderColor = [UIColor whiteColor].CGColor;
    innerMask.layer.borderWidth = 1.0f;
    innerMask.opaque = NO;
    
    topLeft = [[BEDraggableImageView alloc] initWithImage:[UIImage imageNamed:@"HandleTopLeft.png"]];
    topLeft.exclusiveTouch = YES;
    topLeft.delegate = self;
    
    topRight = [[BEDraggableImageView alloc] initWithImage:[UIImage imageNamed:@"HandleTopRight.png"]];
    topRight.exclusiveTouch = YES;
    topRight.delegate = self;

    bottomLeft = [[BEDraggableImageView alloc] initWithImage:[UIImage imageNamed:@"HandleBottomLeft.png"]];
    bottomLeft.exclusiveTouch = YES;
    bottomLeft.delegate = self;
    
    bottomRight = [[BEDraggableImageView alloc] initWithImage:[UIImage imageNamed:@"HandleBottomRight.png"]];
    bottomRight.exclusiveTouch = YES;
    bottomRight.delegate = self;

    [self addSubview:topMask];
    [self addSubview:leftMask];
    [self addSubview:rightMask];
    [self addSubview:bottomMask];
    [self addSubview:innerMask];
    [self addSubview:topLeft];
    [self addSubview:topRight];
    [self addSubview:bottomLeft];
    [self addSubview:bottomRight];

    [self layoutSubviews];
}

- (void)dealloc
{
    topLeft.delegate = nil;
    topRight.delegate = nil;
    bottomLeft.delegate = nil;
    bottomRight.delegate = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateMaxSelectedFrameBounds];
    self.selectedFrameBounds = _maxSelectedFrameBounds;
//    if (CGRectEqualToRect(_selectedFrameBounds, CGRectZero)) {
//        self.selectedFrameBounds = _maxSelectedFrameBounds;
//    } else {
//        self.selectedFrameBounds = _selectedFrameBounds;
//    }
}

- (void)setMaskAlpha:(CGFloat)maskAlpha
{
    _maskAlpha = maskAlpha;
    topMask.alpha = maskAlpha;
    leftMask.alpha = maskAlpha;
    rightMask.alpha = maskAlpha;
    bottomMask.alpha = maskAlpha;
}

- (void)setSymmetrical:(BOOL)value
{
    _symmetrical = value;
    [self updateDragBounds];
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    [self layoutSubviews];
}

- (void)setSelectedFrameBounds:(CGRect)frameBounds
{
    _selectedFrameBounds = [UIView alignRect:CGRectIntersection(frameBounds, _maxSelectedFrameBounds)];
    self.selectedFrame = _selectedFrame;
}

- (void)setSelectedFrame:(CGRect)frame
{
    CGFloat minX = _selectedFrameBounds.origin.x - frame.origin.x;
    if (minX > 0.0f) {
        frame.origin.x += minX;
    }

    CGFloat maxX = ((_selectedFrameBounds.origin.x + _selectedFrameBounds.size.width) -
                    (frame.origin.x + frame.size.width));
    if (maxX < 0.0f) {
        frame.origin.x += maxX;
    }

    CGFloat minY = _selectedFrameBounds.origin.y - frame.origin.y;
    if (minY > 0.0f) {
        frame.origin.y += minY;
    }

    CGFloat maxY = ((_selectedFrameBounds.origin.y + _selectedFrameBounds.size.height) -
                    (frame.origin.y + frame.size.height));
    if (maxY < 0.0f) {
        frame.origin.y += maxY;
    }

    _selectedFrame = CGRectIntersection(frame, _selectedFrameBounds);
    [self layoutHandles];
    [self updateDragBounds];
    [self layoutMask];
}

- (void)updateMaxSelectedFrameBounds
{
    CGFloat width = self.bounds.size.width - (2 * (HANDLE_OFFSET + MIN_HANDLE_X)) - _contentInset.left - _contentInset.right;
    CGFloat height = self.bounds.size.height - (2 * (HANDLE_OFFSET + MIN_HANDLE_Y)) - _contentInset.top - _contentInset.bottom;
    _maxSelectedFrameBounds = CGRectMake(- width / 2.0f, - height / 2.0f, width, height);
}

- (CGRect)convertSelectedFrameToViewFrame:(CGRect)frame
{
    CGFloat centerX = _contentInset.left + ((self.bounds.size.width - _contentInset.left - _contentInset.right) / 2.0f);
    CGFloat centerY = _contentInset.top + ((self.bounds.size.height - _contentInset.top - _contentInset.bottom) / 2.0f);
    return CGRectOffset(frame, centerX, centerY);
}

- (CGRect)convertViewFrameToSelectedFrame:(CGRect)frame
{
    CGFloat centerX = _contentInset.left + ((self.bounds.size.width - _contentInset.left - _contentInset.right) / 2.0f);
    CGFloat centerY = _contentInset.top + ((self.bounds.size.height - _contentInset.top - _contentInset.bottom) / 2.0f);
    return CGRectOffset(frame, 0.0f - centerX, 0.0f - centerY);
}

- (void)layoutHandles
{
    CGRect coordinates = [self convertSelectedFrameToViewFrame:_selectedFrame];

    topLeft.frame = CGRectMake(coordinates.origin.x - HANDLE_OFFSET,
                               coordinates.origin.y - HANDLE_OFFSET,
                               HANDLE_WIDTH,
                               HANDLE_HEIGHT);

    topRight.frame = CGRectMake(coordinates.origin.x + coordinates.size.width + HANDLE_OFFSET - HANDLE_WIDTH,
                                coordinates.origin.y - HANDLE_OFFSET,
                                HANDLE_WIDTH,
                                HANDLE_HEIGHT);

    bottomRight.frame = CGRectMake(coordinates.origin.x + coordinates.size.width + HANDLE_OFFSET - HANDLE_WIDTH,
                                   coordinates.origin.y + coordinates.size.height + HANDLE_OFFSET - HANDLE_HEIGHT,
                                   HANDLE_WIDTH,
                                   HANDLE_HEIGHT);
    
    bottomLeft.frame = CGRectMake(coordinates.origin.x - HANDLE_OFFSET,
                                  coordinates.origin.y + coordinates.size.height + HANDLE_OFFSET - HANDLE_HEIGHT,
                                  HANDLE_WIDTH, 
                                  HANDLE_HEIGHT);
}

- (void)layoutMask
{
    CGRect coordinates = [self convertSelectedFrameToViewFrame:_selectedFrame];

    CGRect innerMaskRect = coordinates;
    innerMaskRect.origin.x = innerMaskRect.origin.x - 1.0f;
    innerMaskRect.origin.y = innerMaskRect.origin.y - 1.0f;
    innerMaskRect.size.width = innerMaskRect.size.width + 2.0f;
    innerMaskRect.size.height = innerMaskRect.size.height + 2.0f;
    innerMask.frame = innerMaskRect;

    CGRect frame = self.bounds;
    // Add a little extra space to account for in-call status bar
    frame.size.width += 40.0f;
    frame.size.height += 40.0f;
    CGRect topFrame, leftFrame, rightFrame, bottomFrame;
    CGRectDivide(frame, &leftFrame, &frame, coordinates.origin.x, CGRectMinXEdge);
    CGRectDivide(frame, &frame, &rightFrame, coordinates.size.width, CGRectMinXEdge);
    CGRectDivide(frame, &topFrame, &frame, coordinates.origin.y, CGRectMinYEdge);
    CGRectDivide(frame, &frame, &bottomFrame, coordinates.size.height, CGRectMinYEdge);
    topMask.frame = topFrame;
    leftMask.frame = leftFrame;
    rightMask.frame = rightFrame;
    bottomMask.frame = bottomFrame;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGFloat xOffset = _handleSize - HANDLE_WIDTH;
    CGFloat yOffset = _handleSize - HANDLE_HEIGHT;
    CGPoint handlePoint;
    CGFloat x;
    CGFloat y;
    
    handlePoint = [topLeft convertPoint:point fromView:self];
    x = handlePoint.x + xOffset;
    y = handlePoint.y + yOffset;
    if(x > 0 && x < _handleSize && y > 0 && y < _handleSize) {
        return topLeft;
    }
    
    handlePoint = [bottomRight convertPoint:point fromView:self];
    x = handlePoint.x;
    y = handlePoint.y;
    if(x > 0 && x < _handleSize && y > 0 && y < _handleSize) {
        return bottomRight;
    }
    
    handlePoint = [topRight convertPoint:point fromView:self];
    x = handlePoint.x;
    y = handlePoint.y + yOffset;
    if(x > 0 && x < _handleSize && y > 0 && y < _handleSize) {
        return topRight;
    }
    
    handlePoint = [bottomLeft convertPoint:point fromView:self];
    x = handlePoint.x + xOffset;
    y = handlePoint.y;
    if(x > 0 && x < _handleSize && y > 0 && y < _handleSize) {
        return bottomLeft;
    }
    
    return nil;
}

- (void)updateDragBounds
{
    CGRect coordinateBounds = [self convertSelectedFrameToViewFrame:_selectedFrameBounds];

    CGFloat minDragX = coordinateBounds.origin.x - HANDLE_OFFSET;
    CGFloat minDragY = coordinateBounds.origin.y - HANDLE_OFFSET;
    CGFloat maxDragX = coordinateBounds.origin.x + coordinateBounds.size.width + HANDLE_OFFSET;
    CGFloat maxDragY = coordinateBounds.origin.y + coordinateBounds.size.height + HANDLE_OFFSET;

    if(_symmetrical) {
        CGFloat centerX = coordinateBounds.origin.x + (coordinateBounds.size.width / 2.0f);
        CGFloat centerY = coordinateBounds.origin.y + (coordinateBounds.size.height / 2.0f);
        CGFloat dragX = centerX - HANDLE_SPACER + (HANDLE_GAP / 2);
        CGFloat dragY = centerY - HANDLE_SPACER + (HANDLE_GAP / 2);
        CGFloat dragWidth = ((maxDragX - minDragX) / 2.0f) + HANDLE_SPACER - (HANDLE_GAP / 2);
        CGFloat dragHeight = ((maxDragY - minDragY) / 2.0f) + HANDLE_SPACER - (HANDLE_GAP / 2);
        
        topLeft.dragBounds = CGRectMake(minDragX, minDragY, dragWidth, dragHeight);
        topRight.dragBounds = CGRectMake(dragX, minDragY, dragWidth, dragHeight);
        bottomRight.dragBounds = CGRectMake(dragX, dragY, dragWidth, dragHeight);
        bottomLeft.dragBounds = CGRectMake(minDragX, dragY, dragWidth, dragHeight);
    } else {
        CGFloat topLeftX = minDragX;
        CGFloat topLeftY = minDragY;
        CGFloat topLeftWidth = topRight.frame.origin.x - minDragX + (2 * HANDLE_SPACER) - HANDLE_GAP;
        CGFloat topLeftHeight = bottomLeft.frame.origin.y - minDragY + (2 * HANDLE_SPACER) - HANDLE_GAP;
        topLeft.dragBounds = CGRectMake(topLeftX, topLeftY, topLeftWidth, topLeftHeight);
        
        CGFloat topRightX = topLeft.frame.origin.x + HANDLE_WIDTH - (2 * HANDLE_SPACER) + HANDLE_GAP;
        CGFloat topRightY = minDragY;
        CGFloat topRightWidth = maxDragX - topRightX;
        CGFloat topRightHeight = bottomRight.frame.origin.y - minDragY + (2 * HANDLE_SPACER) - HANDLE_GAP;
        topRight.dragBounds = CGRectMake(topRightX, topRightY, topRightWidth, topRightHeight);
        
        CGFloat bottomRightX = bottomLeft.frame.origin.x + HANDLE_WIDTH - (2 * HANDLE_SPACER) + HANDLE_GAP;
        CGFloat bottomRightY = topRight.frame.origin.y + HANDLE_HEIGHT - (2 * HANDLE_SPACER) + HANDLE_GAP;
        CGFloat bottomRightWidth = maxDragX - bottomRightX;
        CGFloat bottomRightHeight = maxDragY - bottomRightY;
        bottomRight.dragBounds = CGRectMake(bottomRightX, bottomRightY, bottomRightWidth, bottomRightHeight);
        
        CGFloat bottomLeftX = minDragX;
        CGFloat bottomLeftY = topLeft.frame.origin.y + HANDLE_HEIGHT - (2 * HANDLE_SPACER) + HANDLE_GAP;
        CGFloat bottomLeftWidth = bottomRight.frame.origin.x - minDragX + (2 * HANDLE_SPACER) - HANDLE_GAP;
        CGFloat bottomLeftHeight = maxDragY - bottomLeftY;
        bottomLeft.dragBounds = CGRectMake(bottomLeftX, bottomLeftY, bottomLeftWidth, bottomLeftHeight);
    }
}

- (void)beginDragImageView:(BEDraggableImageView *)view
{
    _activeHandle = view;
}

- (void)endDragImageView:(BEDraggableImageView *)view
{
    _activeHandle = nil;
}

- (void)dragImageView:(BEDraggableImageView *)view
{
    if(view == topLeft) {
        [self onTopLeftDrag:view];
    } else if(view == topRight) {
        [self onTopRightDrag:view];
    } else if(view == bottomRight) {
        [self onBottomRightDrag:view];
    } else if(view == bottomLeft) {
        [self onBottomLeftDrag:view];
    }
}

- (void)onTopLeftDrag:(BEDraggableImageView *)view
{
    CGFloat x = topLeft.frame.origin.x + HANDLE_OFFSET;
    CGFloat y = topLeft.frame.origin.y + HANDLE_OFFSET;
    if(_symmetrical) {
        CGFloat availableWidth = self.bounds.size.width - _contentInset.left - _contentInset.right;
        CGFloat availableHeight = self.bounds.size.height - _contentInset.top - _contentInset.bottom;
        CGFloat width = availableWidth - (2.0f * (x - _contentInset.left));
        CGFloat height = availableHeight - (2.0f * (y - _contentInset.top));
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(x, y, width, height)];
    } else {
        CGRect coordinates = [self convertSelectedFrameToViewFrame:_selectedFrame];
        CGFloat width = coordinates.size.width + (coordinates.origin.x - x);
        CGFloat height = coordinates.size.height + (coordinates.origin.y - y);
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(x, y, width, height)];
    }
}

- (void)onTopRightDrag:(BEDraggableImageView *)view
{
    CGFloat x = topRight.frame.origin.x + HANDLE_WIDTH - HANDLE_OFFSET;
    CGFloat y = topRight.frame.origin.y + HANDLE_OFFSET;
    if(_symmetrical) {
        x = self.bounds.size.width - x + _contentInset.left;
        CGFloat availableWidth = self.bounds.size.width - _contentInset.left - _contentInset.right;
        CGFloat availableHeight = self.bounds.size.height - _contentInset.top - _contentInset.bottom;
        CGFloat width = availableWidth - (2.0f * (x - _contentInset.left));
        CGFloat height = availableHeight - (2.0f * (y - _contentInset.top));
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(x, y, width, height)];
    } else {
        CGRect coordinates = [self convertSelectedFrameToViewFrame:_selectedFrame];
        CGFloat width = x - coordinates.origin.x;
        CGFloat height = coordinates.size.height + (coordinates.origin.y - y);
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(coordinates.origin.x, y, width, height)];
    }
}

- (void)onBottomLeftDrag:(BEDraggableImageView *)view
{
    CGFloat x = bottomLeft.frame.origin.x + HANDLE_OFFSET;
    CGFloat y = bottomLeft.frame.origin.y + HANDLE_HEIGHT - HANDLE_OFFSET;
    if(_symmetrical) {
        y = self.bounds.size.height - y + _contentInset.top;
        CGFloat availableWidth = self.bounds.size.width - _contentInset.left - _contentInset.right;
        CGFloat availableHeight = self.bounds.size.height - _contentInset.top - _contentInset.bottom;
        CGFloat width = availableWidth - (2.0f * (x - _contentInset.left));
        CGFloat height = availableHeight - (2.0f * (y - _contentInset.top));
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(x, y, width, height)];
    } else {
        CGRect coordinates = [self convertSelectedFrameToViewFrame:_selectedFrame];
        CGFloat width = coordinates.size.width + (coordinates.origin.x - x);
        CGFloat height = y - coordinates.origin.y;
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(x, coordinates.origin.y, width, height)];
    }
}

- (void)onBottomRightDrag:(BEDraggableImageView *)view
{
    CGFloat x = bottomRight.frame.origin.x + HANDLE_WIDTH - HANDLE_OFFSET;
    CGFloat y = bottomRight.frame.origin.y + HANDLE_HEIGHT - HANDLE_OFFSET;
    if(_symmetrical) {
        x = self.bounds.size.width - x + _contentInset.left;
        y = self.bounds.size.height - y + _contentInset.top;
        CGFloat availableWidth = self.bounds.size.width - _contentInset.left - _contentInset.right;
        CGFloat availableHeight = self.bounds.size.height - _contentInset.top - _contentInset.bottom;
        CGFloat width = availableWidth - (2.0f * (x - _contentInset.left));
        CGFloat height = availableHeight - (2.0f * (y - _contentInset.top));
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(x, y, width, height)];
    } else {
        CGRect coordinates = [self convertSelectedFrameToViewFrame:_selectedFrame];
        CGFloat width = x - coordinates.origin.x;
        CGFloat height = y - coordinates.origin.y;
        self.selectedFrame = [self convertViewFrameToSelectedFrame:CGRectMake(coordinates.origin.x, coordinates.origin.y, width, height)];
    }
}

@end
