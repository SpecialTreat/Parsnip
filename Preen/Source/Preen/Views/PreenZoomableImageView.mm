#import "PreenZoomableImageView.h"


@implementation PreenZoomableImageView
{
    UIImageView *_imageView;

    CGFloat maximumZoomBounce;
    CGFloat minimumZoomBounce;

    CGFloat scaleToFill;
    CGFloat scaleToFit;
    
    CGFloat totalRotation;
    
    CGFloat currentRotation;
    CGFloat currentPinchScale;
    CGPoint currentRotatePoint;
    CGPoint currentPanPoint;
    CGPoint currentTapAndHoldPoint;

    UITapGestureRecognizer *doubleTapRecognizer;
    UILongPressGestureRecognizer *tapAndHoldRecognizer;
    UIPinchGestureRecognizer *pinchRecognizer;
    UIRotationGestureRecognizer *rotationRecognizer;
    UIPanGestureRecognizer *panRecognizer;
}

@synthesize doubleTapZoomMode = _doubleTapZoomMode;
@synthesize contentInset = _contentInset;
@synthesize imageView = _imageView;
@synthesize margin = _margin;
@synthesize maximumZoomScale = _maximumZoomScale;
@synthesize minimumZoomScale = _minimumZoomScale;
@synthesize zoomStep = _zoomStep;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        currentRotation = 0.0f;
        totalRotation = 0.0f;
        scaleToFill = 1.0f;
        scaleToFit = 1.0f;
        _contentInset = UIEdgeInsetsZero;
        _doubleTapZoomMode = PreenZoomModeActualSize;
        
        self.autoresizesSubviews = NO;
        
        self.margin = 0.0f;
        self.zoomStep = 1.25f;
        self.maximumZoomScale = 1.0f;
        
        doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
        doubleTapRecognizer.delegate = self;
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:doubleTapRecognizer];

        tapAndHoldRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAndHoldRecognizer:)];
        tapAndHoldRecognizer.delegate = self;
        tapAndHoldRecognizer.allowableMovement = self.bounds.size.height;
        tapAndHoldRecognizer.minimumPressDuration = 0.0f;
        tapAndHoldRecognizer.numberOfTapsRequired = 1;
        tapAndHoldRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:tapAndHoldRecognizer];
        [tapAndHoldRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        
        pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
        pinchRecognizer.delegate = self;
        [self addGestureRecognizer:pinchRecognizer];

        rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(onRotate:)];
        rotationRecognizer.delegate = self;
        [self addGestureRecognizer:rotationRecognizer];

        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        panRecognizer.delegate = self;
        panRecognizer.minimumNumberOfTouches = 1;
        panRecognizer.maximumNumberOfTouches = 2;
        [self addGestureRecognizer:panRecognizer];
    }
    return self;
}

- (void)dealloc
{
    doubleTapRecognizer.delegate = nil;
    tapAndHoldRecognizer.delegate = nil;
    pinchRecognizer.delegate = nil;
    rotationRecognizer.delegate = nil;
    panRecognizer.delegate = nil;
}

- (BOOL)doubleTapEnabled
{
    return doubleTapRecognizer.enabled;
}

- (void)setDoubleTapEnabled:(BOOL)doubleTapEnabled
{
    doubleTapRecognizer.enabled = doubleTapEnabled;
}

- (BOOL)panEnabled
{
    return panRecognizer.enabled;
}

- (void)setPanEnabled:(BOOL)panEnabled
{
    panRecognizer.enabled = panEnabled;
}

- (BOOL)pinchEnabled
{
    return pinchRecognizer.enabled;
}

- (void)setPinchEnabled:(BOOL)pinchEnabled
{
    pinchRecognizer.enabled = pinchEnabled;
}

- (BOOL)rotationEnabled
{
    return rotationRecognizer.enabled;
}

- (void)setRotationEnabled:(BOOL)rotationEnabled
{
    rotationRecognizer.enabled = rotationEnabled;
}

- (BOOL)tapAndHoldEnabled
{
    return tapAndHoldRecognizer.enabled;
}

- (void)setTapAndHoldEnabled:(BOOL)tapAndHoldEnabled
{
    tapAndHoldRecognizer.enabled = tapAndHoldEnabled;
}

- (CGFloat)imageRotation
{
    return totalRotation;
}

- (CGFloat)imageScale
{
    CGAffineTransform transform = _imageView.transform;
    return sqrt((transform.a * transform.a) + (transform.c * transform.c));
}

- (CGPoint)imageOffset
{
    return CGPointMake(_imageView.transform.tx, _imageView.transform.ty);
}

- (CGAffineTransform)imageTransform
{
    return _imageView.transform;
}

- (UIImage *)image
{
    return _imageView.image;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat minimumZoomScale = [self minimumZoomScaleForCurrentBoundsWithMargin:self.margin];
    if (minimumZoomScale != self.minimumZoomScale) {
        self.minimumZoomScale = minimumZoomScale;
        scaleToFill = [self zoomScaleWithMargin:0.0f contentMode:UIViewContentModeScaleAspectFill];
        scaleToFit = [self zoomScaleWithMargin:0.0f contentMode:UIViewContentModeScaleAspectFit];
    }

    CGPoint imageViewCenter = CGPointMake(_contentInset.left + ((self.bounds.size.width - _contentInset.left - _contentInset.right) / 2.0f),
                                          _contentInset.top + ((self.bounds.size.height - _contentInset.top - _contentInset.bottom) / 2.0f));
    if (!CGPointEqualToPoint(_imageView.center, imageViewCenter)) {
        _imageView.center = imageViewCenter;
    }
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    [self layoutSubviews];
}

- (void)setImage:(UIImage *)image
{
    // clear the previous _imageView
    [_imageView removeFromSuperview];
    _imageView.image = nil;
    _imageView = nil;
    
    // make a new UIImageView for the new image
    _imageView = [[UIImageView alloc] initWithImage:image];
    [self insertSubview:_imageView atIndex:0];
    
    self.minimumZoomScale = [self minimumZoomScaleForCurrentBoundsWithMargin:self.margin];

    scaleToFill = [self zoomScaleWithMargin:0.0f contentMode:UIViewContentModeScaleAspectFill];
    scaleToFit = [self zoomScaleWithMargin:0.0f contentMode:UIViewContentModeScaleAspectFit];

    CGFloat scale = [self zoomScaleWithMargin:self.margin];
    _imageView.center = CGPointMake(_contentInset.left + ((self.bounds.size.width - _contentInset.left - _contentInset.right) / 2.0f),
                                    _contentInset.top + ((self.bounds.size.height - _contentInset.top - _contentInset.bottom) / 2.0f));
    _imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
    totalRotation = 0.0f;
}

- (void)setMinimumZoomScale:(CGFloat)value
{
    _minimumZoomScale = value;
    minimumZoomBounce = value * 0.5f;
}

- (void)setMaximumZoomScale:(CGFloat)value
{
    _maximumZoomScale = value;
    maximumZoomBounce = value * 3.0f;
}

- (CGRect)zoomFrame
{
    return _imageView.frame;
}

- (CGFloat)zoomScaleWithMargin:(CGFloat)margin
{
    return [self zoomScaleWithMargin:margin contentMode:UIViewContentModeScaleAspectFit];
}

- (CGFloat)zoomScaleWithMargin:(CGFloat)margin contentMode:(UIViewContentMode)contentMode
{
    CGSize boundsSize = CGSizeMake(self.bounds.size.width - (margin * 2.0f) - self.contentInset.left - self.contentInset.right,
                                   self.bounds.size.height - (margin * 2.0f) - self.contentInset.top - self.contentInset.bottom);
    CGSize imageSize = _imageView.bounds.size;


    CGFloat widthScale = boundsSize.width / imageSize.width;
    CGFloat heightScale = boundsSize.height / imageSize.height;
    if (contentMode == UIViewContentModeScaleAspectFill) {
        return MAX(widthScale, heightScale);
    } else {
        return MIN(widthScale, heightScale);
    }
}

- (CGFloat)minimumZoomScaleForCurrentBoundsWithMargin:(CGFloat)margin
{
    CGSize boundsSize = CGSizeMake(self.bounds.size.width - (margin * 2.0f) - self.contentInset.left - self.contentInset.right,
                                   self.bounds.size.height - (margin * 2.0f) - self.contentInset.top - self.contentInset.bottom);
    CGSize imageSize = _imageView.bounds.size;
    
    CGFloat widthXScale = boundsSize.width / imageSize.width;
    CGFloat widthYScale = boundsSize.width / imageSize.height;
    CGFloat heightXScale = boundsSize.height / imageSize.width;
    CGFloat heightYScale = boundsSize.height / imageSize.height;
    CGFloat minimumZoomScale = MIN(MIN(widthXScale, widthYScale), MIN(heightXScale, heightYScale));

    if (minimumZoomScale > self.maximumZoomScale) {
        minimumZoomScale = self.maximumZoomScale;
    }

    return minimumZoomScale;
}

- (void)constrainScaleForRecognizer:(UIGestureRecognizer *)recognizer aboutPoint:(CGPoint)point
{
    CGFloat totalScale = self.imageScale;
    if(totalScale < _minimumZoomScale || totalScale > _maximumZoomScale) {
        recognizer.enabled = NO;
        if (CGPointEqualToPoint(point, CGPointZero)) {
            point = CGPointMake(_contentInset.left + ((self.bounds.size.width - _contentInset.left - _contentInset.right) / 2.0f),
                                _contentInset.top + ((self.bounds.size.height - _contentInset.top - _contentInset.bottom) / 2.0f));
            point = [_imageView convertPoint:point fromView:self];
        }
        CGFloat duration = UINavigationControllerHideShowBarDuration;
        CGFloat offsetX = (_imageView.bounds.size.width / 2.0f) - point.x;
        CGFloat offsetY = (_imageView.bounds.size.height / 2.0f) - point.y;
        CGFloat newScale = 1.0f;

        if(totalScale < _minimumZoomScale) {
            duration = UINavigationControllerHideShowBarDuration / 2.0f;
            newScale = _minimumZoomScale / totalScale;
        } else {
            newScale = _maximumZoomScale / totalScale;
        }
        CGAffineTransform translateTransform = CGAffineTransformTranslate(_imageView.transform, -offsetX, -offsetY);
        CGAffineTransform scaleTransform = CGAffineTransformScale(translateTransform, newScale, newScale);
        CGAffineTransform transform = CGAffineTransformTranslate(scaleTransform, offsetX, offsetY);
        [UIView animateWithDuration:duration animations:^{
            _imageView.transform = transform;
        } completion:^(BOOL finished) {
            recognizer.enabled = YES;
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ((gestureRecognizer == panRecognizer && otherGestureRecognizer == tapAndHoldRecognizer) ||
        (gestureRecognizer == tapAndHoldRecognizer && otherGestureRecognizer == panRecognizer) ||
        (gestureRecognizer == doubleTapRecognizer && otherGestureRecognizer == tapAndHoldRecognizer) ||
        (gestureRecognizer == tapAndHoldRecognizer && otherGestureRecognizer == doubleTapRecognizer)) {
        return NO;
    }
    return YES;
}

- (void)onDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGPoint tapPoint = [recognizer locationInView:_imageView];

    if (_doubleTapZoomMode != PreenZoomModeStep) {
        CGFloat scale = scaleToFit;
        CGPoint offset = self.imageOffset;
        if (ABS(offset.x) < 0.00001 && ABS(offset.y) < 0.00001 && self.imageScale == scaleToFit) {
            if (_doubleTapZoomMode == PreenZoomModeActualSize) {
                scale = 1.0f;
                offset.x = tapPoint.x - (_imageView.bounds.size.width / 2.0f);
                offset.y = tapPoint.y - (_imageView.bounds.size.height / 2.0f);
            } else {
                scale = scaleToFill;
            }
        }
        scale = scale / self.imageScale;
        CGFloat offsetX = offset.x / self.imageScale;
        CGFloat offsetY = offset.y / self.imageScale;
        CGAffineTransform translateTransform = CGAffineTransformTranslate(_imageView.transform, -offsetX, -offsetY);
        transform = CGAffineTransformScale(translateTransform, scale, scale);
    } else {
        CGFloat offsetX = (_imageView.bounds.size.width / 2.0f) - tapPoint.x;
        CGFloat offsetY = (_imageView.bounds.size.height / 2.0f) - tapPoint.y;
        CGAffineTransform translateTransform = CGAffineTransformTranslate(_imageView.transform, -offsetX, -offsetY);
        CGAffineTransform scaleTransform = CGAffineTransformScale(translateTransform, self.zoomStep, self.zoomStep);
        transform = CGAffineTransformTranslate(scaleTransform, offsetX, offsetY);
    }

    recognizer.enabled = NO;
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        _imageView.transform = transform;
    } completion:^(BOOL finished) {
        recognizer.enabled = YES;
        [self constrainScaleForRecognizer:recognizer aboutPoint:tapPoint];
    }];
}

- (void)onTapAndHoldRecognizer:(UILongPressGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        currentTapAndHoldPoint = [recognizer locationInView:self];
    } else if(recognizer.state == UIGestureRecognizerStateEnded) {
        [self constrainScaleForRecognizer:recognizer aboutPoint:CGPointZero];
    } else {
        CGPoint tapAndHoldPoint = [recognizer locationInView:self];
        CGFloat deltaY = currentTapAndHoldPoint.y - tapAndHoldPoint.y;
        CGFloat yPercent = (deltaY / self.bounds.size.height);
        CGFloat deltaScale = yPercent * ((_maximumZoomScale - _minimumZoomScale) / 2.0f);
        currentTapAndHoldPoint = tapAndHoldPoint;

        CGFloat totalScale = self.imageScale;

        if((totalScale >= minimumZoomBounce || deltaScale > 0.0f) &&
           (totalScale <= maximumZoomBounce || deltaScale < 0.0f)) {

            CGFloat desiredScale = totalScale - (totalScale * deltaScale);
            if (desiredScale < _minimumZoomScale && deltaScale < 0.0f) {
                CGFloat amountOver = ABS(desiredScale - _minimumZoomScale);
                CGFloat availableAmountOver = ABS(minimumZoomBounce - _minimumZoomScale);
                CGFloat percentOver = MAX(0.0f, (1.0f - (amountOver / availableAmountOver)));
                deltaScale = deltaScale * percentOver;

            } else if (desiredScale > _maximumZoomScale && deltaScale > 0.0f) {
                CGFloat amountOver = ABS(desiredScale - _maximumZoomScale);
                CGFloat availableAmountOver = ABS(maximumZoomBounce - _maximumZoomScale);
                CGFloat percentOver = MAX(0.0f, (1.0f - (amountOver / availableAmountOver)));
                deltaScale = deltaScale * percentOver;
            }

            CGFloat scale = 1.0f - deltaScale;
            CGAffineTransform transform = CGAffineTransformInvert(_imageView.transform);
            _imageView.transform = CGAffineTransformInvert(CGAffineTransformScale(transform, scale, scale));
        }
    }
}

- (void)onPinch:(UIPinchGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        currentPinchScale = recognizer.scale;
    } else if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint pinchPoint = [recognizer locationInView:_imageView];
        [self constrainScaleForRecognizer:recognizer aboutPoint:pinchPoint];
    } else {
        CGFloat recognizerScale = recognizer.scale;
        CGFloat deltaScale = currentPinchScale - recognizerScale;

        CGFloat scale = 1.0f - deltaScale;
        CGFloat totalScale = self.imageScale;

        if((totalScale >= minimumZoomBounce || scale > 1.0f) &&
           (totalScale <= maximumZoomBounce || scale < 1.0f)) {

            CGFloat desiredScale = scale * totalScale;

            if (desiredScale < _minimumZoomScale && scale < 1.0f) {
                CGFloat amountOver = ABS(desiredScale - _minimumZoomScale);
                CGFloat availableAmountOver = ABS(minimumZoomBounce - _minimumZoomScale);
                CGFloat percentOver = MAX(0.0f, (1.0f - (amountOver / availableAmountOver)));
                CGFloat adjustedDeltaScale = deltaScale * percentOver;
                scale = 1.0f - adjustedDeltaScale;
                CGFloat adjustedScale = currentPinchScale - adjustedDeltaScale;
                currentPinchScale = adjustedScale;
                recognizer.scale = adjustedScale;

            } else if (desiredScale > _maximumZoomScale && scale > 1.0f) {
                CGFloat amountOver = ABS(desiredScale - _maximumZoomScale);
                CGFloat availableAmountOver = ABS(maximumZoomBounce - _maximumZoomScale);
                CGFloat percentOver = MAX(0.0f, (1.0f - (amountOver / availableAmountOver)));
                CGFloat adjustedDeltaScale = deltaScale * percentOver;
                scale = 1.0f - adjustedDeltaScale;
                CGFloat adjustedScale = currentPinchScale - adjustedDeltaScale;
                currentPinchScale = adjustedScale;
                recognizer.scale = adjustedScale;

            } else {
                currentPinchScale = recognizerScale;
            }

            CGPoint pinchPoint = [recognizer locationInView:_imageView];
            CGFloat offsetX = (_imageView.bounds.size.width / 2.0f) - pinchPoint.x;
            CGFloat offsetY = (_imageView.bounds.size.height / 2.0f) - pinchPoint.y;
            CGAffineTransform translateTransform = CGAffineTransformTranslate(_imageView.transform, -offsetX, -offsetY);
            CGAffineTransform scaleTransform = CGAffineTransformScale(translateTransform, scale, scale);
            _imageView.transform = CGAffineTransformTranslate(scaleTransform, offsetX, offsetY);
        } else {
            recognizer.scale = currentPinchScale;
        }
    }
}

- (void)onPan:(UIPanGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        currentPanPoint = [recognizer translationInView:self];
    } else {
        CGFloat totalScale = self.imageScale;
        CGPoint panPoint = [recognizer translationInView:self];
        CGPoint deltaPoint = CGPointMake((currentPanPoint.x - panPoint.x) / totalScale,
                                         (currentPanPoint.y - panPoint.y) / totalScale);
        deltaPoint = CGPointApplyAffineTransform(deltaPoint, CGAffineTransformMakeRotation(-totalRotation));

        currentPanPoint = panPoint;
        _imageView.transform = CGAffineTransformTranslate(_imageView.transform, -deltaPoint.x, -deltaPoint.y);
    }
}

- (void)onRotate:(UIRotationGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        currentRotatePoint = [recognizer locationInView:_imageView];
    } else if(recognizer.state == UIGestureRecognizerStateEnded) {
        currentRotation = 0.0f;
    } else {
        currentRotatePoint = [recognizer locationInView:_imageView];
        CGFloat rotation = 0.0f - (currentRotation - recognizer.rotation);
        totalRotation += rotation;
        CGFloat offsetX = (_imageView.bounds.size.width / 2.0f) - currentRotatePoint.x;
        CGFloat offsetY = (_imageView.bounds.size.height / 2.0f) - currentRotatePoint.y;
        
        CGAffineTransform translateTransform = CGAffineTransformTranslate(_imageView.transform, -offsetX, -offsetY);
        CGAffineTransform rotateTransform = CGAffineTransformRotate(translateTransform, rotation);
        _imageView.transform = CGAffineTransformTranslate(rotateTransform, offsetX, offsetY);
        
        currentRotation = recognizer.rotation;
    }
}

@end