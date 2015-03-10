#import "BEGPUCameraView.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/CGImageProperties.h>
#import "GPUImage.h"
#import "BEDevice.h"
#import "BEUI.h"
#import "UIImage+Drawing.h"
#import "UIImage+Manipulation.h"


//static NSString *CAPTURE_QUALITY = AVCaptureSessionPresetPhoto;
//static NSString *CAPTURE_QUALITY = AVCaptureSessionPreset1280x720;
static NSString *CAPTURE_QUALITY;


#if TARGET_IPHONE_SIMULATOR


@implementation BEGPUCameraView
{
    UIImageView *preview;
    UIButton *toggleFlashButton;
    CGFloat toggleFlashButtonAlpha;
    CGFloat toggleFlashButtonWidth;
    CGFloat toggleFlashButtonHeight;
    UIEdgeInsets toggleFlashButtonMargin;
}

+ (void)initialize
{
    CAPTURE_QUALITY = AVCaptureSessionPresetHigh;
}

@synthesize torchEnabled = _torchEnabled;
@synthesize flashEnabled = _flashEnabled;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        toggleFlashButtonAlpha = [BEUI.theme floatForKey:@"CaptureToggleFlashButton.Alpha"];
        toggleFlashButtonWidth = [BEUI.theme floatForKey:@"CaptureToggleFlashButton.Width"];
        toggleFlashButtonHeight = [BEUI.theme floatForKey:@"CaptureToggleFlashButton.Height"];
        toggleFlashButtonMargin = [BEUI.theme edgeInsetsForKey:@"CaptureToggleFlashButton.Margin"];
        [self initSubviews];
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
    }
    return self;
}

- (void)initSubviews
{
    preview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BECameraView_Simulator.png"]];
//    preview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BECameraView_Simulator_r4.png"]];
//    preview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BECameraView_Simulator_iPad.png"]];
    preview.frame = self.bounds;
    preview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    toggleFlashButton = [[UIButton alloc] init];
    toggleFlashButton.exclusiveTouch = YES;
    toggleFlashButton.alpha = toggleFlashButtonAlpha;
    toggleFlashButton.selected = NO;
    UIImage *image = [BEUI.theme imageForKey:@"CaptureToggleFlashButton.Image"];
    [toggleFlashButton setBackgroundImage:image forState:UIControlStateNormal];
    [toggleFlashButton setBackgroundImage:image forState:UIControlStateHighlighted];
    UIImage *selectedImage = [BEUI.theme imageForKey:@"CaptureToggleFlashButton.SelectedImage"];
    [toggleFlashButton setBackgroundImage:selectedImage forState:UIControlStateSelected];
    [toggleFlashButton setBackgroundImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    toggleFlashButton.frame = CGRectMake(toggleFlashButtonMargin.left,
                                         toggleFlashButtonMargin.top,
                                         toggleFlashButtonWidth,
                                         toggleFlashButtonHeight);

    [self addSubview:preview];
    [self addSubview:toggleFlashButton];
}

- (void)startVideo {}

- (void)stopVideo {}

- (void)pauseVideo {}

- (void)resumeVideo {}

- (void)captureImage:(void(^)(UIImage *image))imageHandler
{
    imageHandler([UIImage imageNamed:@"BECameraView_SimulatorCropped.png"]);
//    imageHandler([UIImage imageNamed:@"BECameraView_Simulator.png"]);
//    imageHandler([UIImage imageNamed:@"BECameraView_Simulator_r4.png"]);
//    imageHandler([UIImage imageNamed:@"BECameraView_Simulator_iPad.png"]);
}

@end


#else


@implementation BEGPUCameraView
{
    GPUImageStillCamera *videoCamera;
    GPUImageView *videoView;
    GPUImageCropFilter *cropFilter;
    CGRect cropRegion;

    NSInteger videoCaptureWidth;
    NSInteger videoCaptureHeight;

    UIImageView *focusBox;
    UIView *focusBoxTouchView;
    
    UIButton *toggleFlashButton;
    CGFloat toggleFlashButtonAlpha;
    CGFloat toggleFlashButtonWidth;
    CGFloat toggleFlashButtonHeight;
    UIEdgeInsets toggleFlashButtonMargin;
    UIDeviceOrientation lastOrientation;
}

+ (void)initialize
{
    CAPTURE_QUALITY = AVCaptureSessionPresetHigh;
}

- (BOOL)torchEnabled
{
    return (videoCamera.inputCamera.torchMode == AVCaptureTorchModeOn);
}

- (BOOL)flashEnabled
{
    return videoCamera.inputCamera.flashActive;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        videoCaptureWidth = 0;
        videoCaptureHeight = 0;
        cropRegion = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        toggleFlashButtonAlpha = [BEUI.theme floatForKey:@"CaptureToggleFlashButton.Alpha"];
        toggleFlashButtonWidth = [BEUI.theme floatForKey:@"CaptureToggleFlashButton.Width"];
        toggleFlashButtonHeight = [BEUI.theme floatForKey:@"CaptureToggleFlashButton.Height"];
        toggleFlashButtonMargin = [BEUI.theme edgeInsetsForKey:@"CaptureToggleFlashButton.Margin"];
        [self initVideoCamera];
        [self initDeviceListeners];
        [self initSubviews];
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
    }
    return self;
}

- (void)initVideoCamera
{
    videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:CAPTURE_QUALITY cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [videoCamera.captureSession commitConfiguration];

    cropFilter = [[GPUImageCropFilter alloc] init];
    cropFilter.cropRegion = cropRegion;
    [videoCamera addTarget:cropFilter];

    AVCaptureInputPort *port = [videoCamera.captureSession.inputs.firstObject ports].firstObject;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(onCaptureInputPortFormatDescriptionDidChange:)
                               name:AVCaptureInputPortFormatDescriptionDidChangeNotification
                             object:port];
}

- (void)initSubviews
{
	videoView = [[GPUImageView alloc] initWithFrame:self.bounds];
    videoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [cropFilter addTarget:videoView];

    UIImage *focusBoxLight = [BEUI.theme imageForKey:@"FocusBoxLight"];
    UIImage *focusBoxDark = [BEUI.theme imageForKey:@"FocusBoxDark"];
    UIImage *focusBoxGlow = [BEUI.theme imageForKey:@"FocusBoxGlow"];

    focusBox = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 69.0f, 69.0f)];
	focusBox.hidden = YES;
    focusBox.animationImages = @[[focusBoxLight drawOverImage:focusBoxGlow], [focusBoxDark drawOverImage:focusBoxGlow]];
    focusBox.animationDuration = 0.25f;
    
    focusBoxTouchView = [[UIView alloc] initWithFrame:self.bounds];
    focusBoxTouchView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    UITapGestureRecognizer *focusBoxTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onFocusBoxTap:)];
    focusBoxTapRecognizer.numberOfTapsRequired = 1;
    focusBoxTapRecognizer.numberOfTouchesRequired = 1;
    [focusBoxTouchView addGestureRecognizer:focusBoxTapRecognizer];

    toggleFlashButton = [[UIButton alloc] init];
    toggleFlashButton.exclusiveTouch = YES;
    toggleFlashButton.alpha = toggleFlashButtonAlpha;
    toggleFlashButton.frame = [self getToggleFlashButtonFrame];
    toggleFlashButton.selected = NO;
    toggleFlashButton.hidden = (!videoCamera.inputCamera.hasFlash && !videoCamera.inputCamera.hasTorch);
    UIImage *image = [BEUI.theme imageForKey:@"CaptureToggleFlashButton.Image"];
    [toggleFlashButton setBackgroundImage:image forState:UIControlStateNormal];
    [toggleFlashButton setBackgroundImage:image forState:UIControlStateHighlighted];
    UIImage *selectedImage = [BEUI.theme imageForKey:@"CaptureToggleFlashButton.SelectedImage"];
    [toggleFlashButton setBackgroundImage:selectedImage forState:UIControlStateSelected];
    [toggleFlashButton setBackgroundImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    [toggleFlashButton addTarget:self action:@selector(onToggleFlashButtonTouch) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:videoView];
    [self addSubview:focusBox];
    [self addSubview:focusBoxTouchView];
    [self addSubview:toggleFlashButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    videoView.frame = self.bounds;
}

- (void)initDeviceListeners
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self 
                           selector:@selector(onDeviceOrientationDidChange:)
                               name:UIDeviceOrientationDidChangeNotification
                             object:nil];
}

 - (void)onDeviceMotion:(CMDeviceMotion*)motion
{
    float accelerationThreshold = 0.1f;
    CMAcceleration acceleration = motion.userAcceleration;

    float rotationThreshold = 1.0f;
    CMRotationRate rotation = motion.rotationRate;

    if(fabs(acceleration.x) > accelerationThreshold || 
       fabs(acceleration.y) > accelerationThreshold || 
       fabs(acceleration.z) > accelerationThreshold) {
        [BEDevice.motionManager stopDeviceMotionUpdates];
        [self setVideoCameraContinuousAutoFocus];
    } else if(fabs(rotation.x) > rotationThreshold || 
       fabs(rotation.y) > rotationThreshold || 
       fabs(rotation.z) > rotationThreshold) {
        [BEDevice.motionManager stopDeviceMotionUpdates];
        [self setVideoCameraContinuousAutoFocus];
    }
}

- (void)onDeviceOrientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation != lastOrientation && (
       orientation == UIDeviceOrientationPortraitUpsideDown || 
       orientation == UIDeviceOrientationLandscapeLeft || 
       orientation == UIDeviceOrientationLandscapeRight || 
       orientation == UIDeviceOrientationPortrait)) {
       
        [UIView animateWithDuration: 0.2 animations:^{
            toggleFlashButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
            lastOrientation = orientation;
            switch(orientation) {
                case UIDeviceOrientationPortraitUpsideDown:
                    toggleFlashButton.transform = CGAffineTransformMakeRotation(M_PI);
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    toggleFlashButton.transform = CGAffineTransformMakeRotation(M_PI/2);
                    break;
                case UIDeviceOrientationLandscapeRight:
                    toggleFlashButton.transform = CGAffineTransformMakeRotation(3*M_PI/2);
                    break;
                default:
                    toggleFlashButton.transform = CGAffineTransformMakeRotation(0);
                    break;
            }
            toggleFlashButton.frame = [self getToggleFlashButtonFrameForOrientation:orientation];
            
            [UIView animateWithDuration: 0.2 animations:^{
                toggleFlashButton.alpha = toggleFlashButtonAlpha;
            }];
        }];
    }
}


- (void)onCaptureInputPortFormatDescriptionDidChange:(NSNotification *)notification
{
    [self updateCropRegionWithCaptureSize];
}

- (void)onFocusBoxTap:(UITapGestureRecognizer*)recognizer
{
    CGPoint pointInView = [recognizer locationInView:focusBoxTouchView];
    CGPoint pointOfInterest = [self convertToPointOfInterestFromViewCoordinates:pointInView];

    if([videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [videoCamera.inputCamera isFocusPointOfInterestSupported]) {
        focusBox.center = pointInView;
        [self performSelectorOnMainThread:@selector(showFocusBox) withObject:nil waitUntilDone:NO];
        [self focusOnPointOfInterest:pointOfInterest];
        [self startMotionManager];
    }
}

- (void)focusOnPointOfInterest:(CGPoint)pointOfInterest
{
    NSError *error;
    if([videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [videoCamera.inputCamera isFocusPointOfInterestSupported]) {
        if([videoCamera.inputCamera lockForConfiguration:&error]) {
            [videoCamera.inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
            [videoCamera.inputCamera setFocusPointOfInterest:pointOfInterest];
            [videoCamera.inputCamera unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
}

- (void)onToggleFlashButtonTouch
{
    if(toggleFlashButton.selected) {
        [self disableTorch];
    } else {
        [self enableTorch];
    }
}

- (CGRect)getToggleFlashButtonFrame
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    return [self getToggleFlashButtonFrameForOrientation:orientation];
}

- (CGRect)getToggleFlashButtonFrameForOrientation:(UIDeviceOrientation)orientation
{
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    switch(orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            return CGRectMake(
                width - toggleFlashButtonWidth - toggleFlashButtonMargin.right,
                height - toggleFlashButtonHeight - toggleFlashButtonMargin.bottom,
                toggleFlashButtonWidth, 
                toggleFlashButtonHeight);
            break;
        case UIDeviceOrientationLandscapeLeft:
            return CGRectMake(
                width - toggleFlashButtonHeight - toggleFlashButtonMargin.right,
                toggleFlashButtonMargin.top,
                toggleFlashButtonHeight,
                toggleFlashButtonWidth);
            break;
        case UIDeviceOrientationLandscapeRight:
            return CGRectMake(
                toggleFlashButtonMargin.left,
                height - toggleFlashButtonWidth - toggleFlashButtonMargin.bottom,
                toggleFlashButtonHeight,
                toggleFlashButtonWidth);
            break;
        default:
            return CGRectMake(
                toggleFlashButtonMargin.left,
                toggleFlashButtonMargin.top,
                toggleFlashButtonWidth, 
                toggleFlashButtonHeight);
            break;
    }
}

- (void)setVideoCameraContinuousAutoFocus
{
    NSError *error;
    if([videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        if([videoCamera.inputCamera lockForConfiguration:&error]) {
            [videoCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [videoCamera.inputCamera unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
}

- (void)updateCropRegionWithCaptureSize
{
    AVCaptureInputPort *port = [videoCamera.captureSession.inputs.firstObject ports].firstObject;
    CMFormatDescriptionRef formatDescription = port.formatDescription;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    if (dimensions.width > 0 && dimensions.height > 0) {
        NSInteger width = 0;
        NSInteger height = 0;
        if (videoView.frame.size.height > videoView.frame.size.width) {
            height = MAX(dimensions.width, dimensions.height);
            width = MIN(dimensions.width, dimensions.height);
        } else {
            width = MAX(dimensions.width, dimensions.height);
            height = MIN(dimensions.width, dimensions.height);
        }
        if (width != videoCaptureWidth || height != videoCaptureHeight) {
            videoCaptureWidth = width;
            videoCaptureHeight = height;

            CGFloat imageWidth = (CGFloat)width;
            CGFloat imageHeight = (CGFloat)height;
            CGFloat previewWidth = videoView.frame.size.width;
            CGFloat previewHeight = videoView.frame.size.height;
            CGFloat widthRatio = previewWidth / imageWidth;
            CGFloat heightRatio = previewHeight / imageHeight;
            CGFloat cropX;
            CGFloat cropY;
            CGFloat cropWidth;
            CGFloat cropHeight;
            if(widthRatio > heightRatio) {
                cropX = 0;
                cropWidth = imageWidth;
                cropHeight = (previewHeight / previewWidth) * cropWidth;
                cropY = (imageHeight - cropHeight) / 2;
            } else {
                cropY = 0;
                cropHeight = imageHeight;
                cropWidth = (previewWidth / previewHeight) * cropHeight;
                cropX = (imageWidth - cropWidth) / 2;
            }

            CGFloat xPercent = cropX / imageWidth;
            CGFloat yPercent = cropY / imageHeight;
            CGFloat widthPercent = cropWidth / imageWidth;
            CGFloat heightPercent = cropHeight / imageHeight;

            cropRegion = CGRectMake(xPercent, yPercent, widthPercent, heightPercent);
            cropFilter.cropRegion = cropRegion;
        }
    }
}

- (void)startVideo
{
    [videoCamera startCameraCapture];
    [self updateCropRegionWithCaptureSize];
    [self focusOnPointOfInterest:CGPointMake(0.5, 0.5)];
    [self startMotionManager];
}

- (void)stopVideo
{
    [videoCamera stopCameraCapture];
}

- (void)pauseVideo
{
    [videoCamera pauseCameraCapture];
}

- (void)resumeVideo
{
    [videoCamera resumeCameraCapture];
}

- (void)startMotionManager
{
    if(BEDevice.motionManager.deviceMotionAvailable) {
        [BEDevice.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                                    withHandler:^(CMDeviceMotion *motion, NSError *error){
                                                        [self performSelectorOnMainThread:@selector(onDeviceMotion:) withObject:motion waitUntilDone:YES];
                                                    }];
    }
}

- (void)enableTorch
{
    NSError *error = nil;
    if(videoCamera.inputCamera.hasTorch && videoCamera.inputCamera.torchAvailable) {
        if([videoCamera.inputCamera lockForConfiguration:&error]) {
            videoCamera.inputCamera.torchMode = AVCaptureTorchModeOn;
            toggleFlashButton.selected = YES;
            [videoCamera.inputCamera unlockForConfiguration];
        }
    } else if(videoCamera.inputCamera.hasFlash && videoCamera.inputCamera.flashAvailable) {
        if([videoCamera.inputCamera lockForConfiguration:&error]) {
            videoCamera.inputCamera.flashMode = AVCaptureFlashModeOn;
            toggleFlashButton.selected = YES;
            [videoCamera.inputCamera unlockForConfiguration];
        }
    }
}

- (void)disableTorch
{
    NSError *error = nil;
    if(videoCamera.inputCamera.hasTorch && videoCamera.inputCamera.torchAvailable) {
        if([videoCamera.inputCamera lockForConfiguration:&error]) {
            videoCamera.inputCamera.torchMode = AVCaptureTorchModeOff;
            toggleFlashButton.selected = NO;
            [videoCamera.inputCamera unlockForConfiguration];
        }
    } else if(videoCamera.inputCamera.hasFlash && videoCamera.inputCamera.flashAvailable) {
        if([videoCamera.inputCamera lockForConfiguration:&error]) {
            videoCamera.inputCamera.flashMode = AVCaptureFlashModeOff;
            toggleFlashButton.selected = NO;
            [videoCamera.inputCamera unlockForConfiguration];
        }
    }
}

- (void)showFocusBox
{
    [focusBox startAnimating];
    focusBox.bounds = CGRectMake(0.0f, 0.0f, 100.f, 100.f);
    focusBox.hidden = NO;
    [UIView animateWithDuration:0.2f animations:^{
        focusBox.bounds = CGRectMake(0.0f, 0.0f, 69.f, 69.f);
    } completion:^(BOOL finished) {    
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            focusBox.alpha = 0.0f;
        } completion:^(BOOL finished) {
            focusBox.hidden = YES;
            focusBox.alpha = 1.0f;
            [focusBox stopAnimating];
        }];
    }];
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates 
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = videoView.frame.size;

    if (videoCamera.videoCaptureConnection.videoMirrored) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }

    if (videoView.fillMode == kGPUImageFillModeStretch) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [videoCamera.captureSession.inputs.lastObject ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;

                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;

                if (videoView.fillMode == kGPUImageFillModePreserveAspectRatio) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if (videoView.fillMode == kGPUImageFillModePreserveAspectRatioAndFill) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }

                }

                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }

    return pointOfInterest;
}

- (void)captureImage:(void(^)(UIImage *image))imageHandler
{
    [videoCamera capturePhotoAsImageProcessedUpToFilter:cropFilter withCompletionHandler:^(UIImage *image, NSError *error) {
        [self performSelectorOnMainThread:@selector(disableTorch) withObject:nil waitUntilDone:NO];
        imageHandler([image reorientToOrientation:UIImageOrientationUp]);
    }];
}

@end


#endif
