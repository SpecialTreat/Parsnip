#import "BECroppableImageView.h"

#import "BEReticleView.h"
#import "BEZoomableImageView.h"
#import "UIImage+Manipulation.h"
#import "UIView+Tools.h"


@implementation BECroppableImageView
{
    BEReticleView *reticleView;
    BEZoomableImageView *zoomableView;
}

@synthesize contentInset = _contentInset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _contentInset = UIEdgeInsetsZero;
        [self initSubviews];
        self.clipsToBounds = YES;
        self.autoresizesSubviews = NO;
    }
    return self;
}

- (void)initSubviews
{
    zoomableView = [[BEZoomableImageView alloc] initWithFrame:self.bounds];
    zoomableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    zoomableView.margin = 16.0f;
    zoomableView.zoomStep = 1.5f;
    zoomableView.doubleTapZoomMode = BEZoomModeStep;

    reticleView = [[BEReticleView alloc] initWithFrame:self.bounds];
    reticleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    reticleView.symmetrical = NO;

    [self addSubview:zoomableView];
    [self addSubview:reticleView];
}

- (void)layoutSubviews
{
    CGPoint before = reticleView.selectedFrame.origin;

    [super layoutSubviews];

    zoomableView.frame = self.bounds;
    [zoomableView layoutSubviews];

    reticleView.frame = self.bounds;
    [reticleView layoutSubviews];

    CGPoint after = reticleView.selectedFrame.origin;
    CGPoint offset = CGPointMake(after.x - before.x, after.y - before.y);
    if (!CGPointEqualToPoint(offset, CGPointZero)) {
        CGFloat scale = zoomableView.imageScale;
        CGFloat rotation = zoomableView.imageRotation;
        CGAffineTransform transform = zoomableView.imageView.transform;
        transform = CGAffineTransformRotate(transform, -rotation);
        transform = CGAffineTransformTranslate(transform, offset.x / scale, offset.y / scale);
        transform = CGAffineTransformRotate(transform, rotation);
        zoomableView.imageView.transform = transform;
    }
}

- (void)setMaskAlpha:(CGFloat)maskAlpha
{
    reticleView.maskAlpha = maskAlpha;
}

- (CGFloat)maskAlpha
{
    return reticleView.maskAlpha;
}

- (void)setZoomStep:(CGFloat)zoomStep
{
    zoomableView.zoomStep = zoomStep;
}

- (CGFloat)zoomStep
{
    return zoomableView.zoomStep;
}

- (void)setZoomMargin:(CGFloat)zoomMargin
{
    zoomableView.margin = zoomMargin;
}

- (CGFloat)zoomMargin
{
    return zoomableView.margin;
}

- (void)setMaximumZoomScale:(CGFloat)maximumZoomScale
{
    zoomableView.maximumZoomScale = maximumZoomScale;
}

- (CGFloat)maximumZoomScale
{
    return zoomableView.maximumZoomScale;
}

- (void)setSymmetrical:(BOOL)symmetrical
{
    reticleView.symmetrical = symmetrical;
}

- (BOOL)symmetrical
{
    return reticleView.symmetrical;
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    zoomableView.contentInset = contentInset;
    reticleView.contentInset = contentInset;
}

- (UIEdgeInsets)contentInset
{
    return _contentInset;
}

- (CGRect)selectedFrame
{
    return [reticleView convertSelectedFrameToViewFrame:reticleView.selectedFrame];
}

- (CGRect)cropFrame
{
    return reticleView.selectedFrame;
//    CGRect selectedFrame = reticleView.selectedFrame;
//    CGFloat centerX = _contentInset.left + ((self.bounds.size.width - _contentInset.left - _contentInset.right) / 2.0f);
//    CGFloat centerY = _contentInset.top + ((self.bounds.size.height - _contentInset.top - _contentInset.bottom) / 2.0f);
//    return CGRectMake(selectedFrame.origin.x - centerX,
//                      selectedFrame.origin.y - centerY,
//                      selectedFrame.size.width,
//                      selectedFrame.size.height);
}

- (CGPoint)imageOffset
{
    return zoomableView.imageOffset;
}

- (CGFloat)imageScale
{
    return zoomableView.imageScale;
}

- (CGFloat)imageRotation
{
    return zoomableView.imageRotation;
}

- (CGAffineTransform)imageTransform
{
    return zoomableView.imageTransform;
}

- (UIImage *)getCroppedImage
{
    CGPoint imageOffset = zoomableView.imageOffset;
    CGFloat imageScale = zoomableView.imageScale;
    CGFloat imageRotation = zoomableView.imageRotation;
    UIImage *zoomedImage = zoomableView.image;
    
    CGFloat offsetX = imageOffset.x / imageScale;
    CGFloat offsetY = imageOffset.y / imageScale;

    CGFloat canvasWidth = self.bounds.size.width / imageScale;
    CGFloat canvasHeight = self.bounds.size.height / imageScale;
    CGRect canvasBounds = CGRectMake(0, 0, canvasWidth, canvasHeight);
    
	CGFloat imageWidth = zoomedImage.size.width;
	CGFloat imageHeight = zoomedImage.size.height;
	CGRect imageBounds = CGRectMake(0, 0, imageWidth, imageHeight);
    
	UIGraphicsBeginImageContextWithOptions(canvasBounds.size, YES, 1.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, canvasBounds);
    
    CGContextTranslateCTM(context, (canvasWidth - imageWidth) / 2.0f, (canvasHeight - imageHeight) / 2.0f);
    
    CGContextTranslateCTM(context, offsetX, offsetY);
    
    CGContextTranslateCTM(context, (imageWidth / 2.0f), (imageHeight / 2.0f));
    CGContextRotateCTM(context, imageRotation);
    CGContextTranslateCTM(context, -(imageWidth / 2.0f), -(imageHeight / 2.0f));

    [zoomedImage drawInRect:imageBounds blendMode:kCGBlendModeNormal alpha:1.0f];
    
	UIImage *transformedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    CGRect cropFrame = self.cropFrame;
    CGRect transformedCropFrame = CGRectMake(
        (transformedImage.size.width / 2.0f) + (cropFrame.origin.x / imageScale),
        (transformedImage.size.height / 2.0f) + (cropFrame.origin.y / imageScale),
        cropFrame.size.width / imageScale,
        cropFrame.size.height / imageScale);

    return [transformedImage crop:transformedCropFrame];
}

- (UIImage *)image
{
    return zoomableView.image;
}

- (void)setImage:(UIImage *)value
{
    zoomableView.image = value;
    zoomableView.opaque = ![value hasAlpha];
    CGRect initialFrame = [self initalSelectedFrame:zoomableView.zoomFrame];
    reticleView.selectedFrame = [reticleView convertViewFrameToSelectedFrame:initialFrame];
}

- (CGRect)initalSelectedFrame:(CGRect)frame
{
    CGFloat width = MIN(frame.size.width, self.bounds.size.width) - 1.0f;
    CGFloat height = MIN(frame.size.height, self.bounds.size.height) - 1.0f;
    CGFloat x = MAX(frame.origin.x, ((self.bounds.size.width - width) / 2.0f)) + 0.5f;
    CGFloat y = MAX(frame.origin.y, ((self.bounds.size.height - height) / 2.0f)) + 0.5f;

    CGFloat scale = [UIScreen mainScreen].scale;
    CGRect alignedFrame;
    if(scale == 1.0f) {
        alignedFrame = CGRectMake(ceil(x), ceil(y), floor(width), floor(height));
    } else {
        alignedFrame = CGRectMake(ceil(x * scale) / scale,
                                  ceil(y * scale) / scale,
                                  floor(width * scale) / scale,
                                  floor(height * scale) / scale);
    }
    return alignedFrame;
}

@end
