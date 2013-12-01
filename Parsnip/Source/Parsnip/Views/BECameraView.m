#import "BECameraView.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/CGImageProperties.h>
#import "BEDevice.h"
#import "BEUI.h"
#import "UIImage+Drawing.h"
#import "UIImage+Manipulation.h"


//static NSString *CAPTURE_QUALITY = AVCaptureSessionPresetPhoto;
//static NSString *CAPTURE_QUALITY = AVCaptureSessionPreset1280x720;
static NSString *CAPTURE_QUALITY;


#if TARGET_IPHONE_SIMULATOR


@implementation BECameraView
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

- (void)captureImage:(void(^)(UIImage *image))imageHandler
{
//    imageHandler([UIImage imageNamed:@"BECameraView_SimulatorCropped.png"]);
    imageHandler([UIImage imageNamed:@"BECameraView_Simulator.png"]);
}

@end


#else


@implementation BECameraView
{
    AVCaptureSession *captureSession;
    AVCaptureDevice *captureDevice;
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureVideoPreviewLayer *preview;
    
    UIImageView *focusBox;
    UIView *focusBoxTouchView;
    
    UIButton *toggleFlashButton;
    CGFloat toggleFlashButtonAlpha;
    CGFloat toggleFlashButtonWidth;
    CGFloat toggleFlashButtonHeight;
    UIEdgeInsets toggleFlashButtonMargin;
    UIDeviceOrientation lastOrientation;
}

- (BOOL)torchEnabled
{
    return (captureDevice.torchMode == AVCaptureTorchModeOn);
}

- (BOOL)flashEnabled
{
    return captureDevice.flashActive;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
    if(captureSession) {
      [captureSession stopRunning];
    }
    captureSession = [[AVCaptureSession alloc] init];
    if([captureSession canSetSessionPreset:CAPTURE_QUALITY]) {
        captureSession.sessionPreset = CAPTURE_QUALITY;
    }
    
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];	
	if(captureDevice) {
		NSError *error;
		AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
		if(!error) {
			if([captureSession canAddInput:videoIn]) {
				[captureSession addInput:videoIn];
            } else {
				NSLog(@"Couldn't add video input");
            }
		} else {
			NSLog(@"Couldn't create video input");
        }
	} else {
		NSLog(@"Couldn't create video capture device");
    }
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [stillImageOutput setOutputSettings:@{AVVideoCodecKey: AVVideoCodecJPEG}];
  
//    AVCaptureConnection *videoConnection = nil;
//    for(AVCaptureConnection *connection in stillImageOutput.connections) {
//        for(AVCaptureInputPort *port in [connection inputPorts]) {
//            if([[port mediaType] isEqual:AVMediaTypeVideo] ) {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection) { 
//            break;
//        }
//    }

    [captureSession addOutput:stillImageOutput];
}

- (void)initSubviews
{
	preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
	[preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    preview.frame = self.bounds;

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
    toggleFlashButton.alpha = 0.0f;
    toggleFlashButton.selected = NO;
    toggleFlashButton.hidden = (!captureDevice.hasFlash && !captureDevice.hasTorch);
    UIImage *image = [BEUI.theme imageForKey:@"CaptureToggleFlashButton.Image"];
    [toggleFlashButton setBackgroundImage:image forState:UIControlStateNormal];
    [toggleFlashButton setBackgroundImage:image forState:UIControlStateHighlighted];
    UIImage *selectedImage = [BEUI.theme imageForKey:@"CaptureToggleFlashButton.SelectedImage"];
    [toggleFlashButton setBackgroundImage:selectedImage forState:UIControlStateSelected];
    [toggleFlashButton setBackgroundImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    [toggleFlashButton addTarget:self action:@selector(onToggleFlashButtonTouch) forControlEvents:UIControlEventTouchUpInside];
    
    [self.layer addSublayer:preview];
    [self addSubview:focusBox];
    [self addSubview:focusBoxTouchView];
    [self addSubview:toggleFlashButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    preview.frame = self.bounds;
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
        [self setVideoCameraAutoFocus];
    } else if(fabs(rotation.x) > rotationThreshold || 
       fabs(rotation.y) > rotationThreshold || 
       fabs(rotation.z) > rotationThreshold) {
        [BEDevice.motionManager stopDeviceMotionUpdates];
        [self setVideoCameraAutoFocus];
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

- (void)onFocusBoxTap:(UITapGestureRecognizer*)recognizer
{
    CGPoint pointInView = [recognizer locationInView:focusBoxTouchView];
    CGPoint pointOfInterest = [self convertToPointOfInterestFromViewCoordinates:pointInView];
    NSError *error;
    if([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [captureDevice isFocusPointOfInterestSupported]) {
        focusBox.center = pointInView;
        [self performSelectorOnMainThread:@selector(showFocusBox) withObject:nil waitUntilDone:NO];
        if([captureDevice lockForConfiguration:&error]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [captureDevice setFocusPointOfInterest:pointOfInterest];
            [captureDevice unlockForConfiguration];
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

- (void)setVideoCameraAutoFocus
{
    NSError *error;
    if([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        if([captureDevice lockForConfiguration:&error]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [captureDevice unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
}

- (void)startVideo
{
    [captureSession startRunning];
}

- (void)stopVideo
{
    [captureSession stopRunning];
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
    if(captureDevice.hasTorch && captureDevice.torchAvailable) {
        if([captureDevice lockForConfiguration:&error]) {
            captureDevice.torchMode = AVCaptureTorchModeOn;
            toggleFlashButton.selected = YES;
            [captureDevice unlockForConfiguration];
        }
    } else if(captureDevice.hasFlash && captureDevice.flashAvailable) {
        if([captureDevice lockForConfiguration:&error]) {
            captureDevice.flashMode = AVCaptureFlashModeOn;
            toggleFlashButton.selected = YES;
            [captureDevice unlockForConfiguration];
        }
    }
}

- (void)disableTorch
{
    NSError *error = nil;
    if(captureDevice.hasTorch && captureDevice.torchAvailable) {
        if([captureDevice lockForConfiguration:&error]) {
            captureDevice.torchMode = AVCaptureTorchModeOff;
            toggleFlashButton.selected = NO;
            [captureDevice unlockForConfiguration];
        }
    } else if(captureDevice.hasFlash && captureDevice.flashAvailable) {
        if([captureDevice lockForConfiguration:&error]) {
            captureDevice.flashMode = AVCaptureFlashModeOff;
            toggleFlashButton.selected = NO;
            [captureDevice unlockForConfiguration];
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
            
            [self startMotionManager];
        }];
    }];
    
    if(BEDevice.motionManager.deviceMotionAvailable) {
        [BEDevice.motionManager startDeviceMotionUpdates];
    }
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates 
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = preview.frame.size;

    AVCaptureVideoPreviewLayer *videoPreviewLayer = preview;

    if (preview.connection.videoMirrored) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }

    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [captureSession.inputs.lastObject ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;

                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;

                if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
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
                } else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
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
	AVCaptureConnection *videoConnection = nil;
	for(AVCaptureConnection *connection in stillImageOutput.connections) {
		for(AVCaptureInputPort *port in [connection inputPorts]) {
			if([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if(videoConnection) {
          break;
        }
	}
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        [self performSelectorOnMainThread:@selector(disableTorch) withObject:nil waitUntilDone:NO];
        // CFDictionaryRef exifAttachments = (CFDictionaryRef)CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        CGFloat previewWidth = preview.bounds.size.width;
        CGFloat previewHeight = preview.bounds.size.height;
        switch (deviceOrientation) {
            case UIDeviceOrientationLandscapeLeft:
                image = [image rotate:-90.0f];
                previewHeight = preview.bounds.size.width;
                previewWidth = preview.bounds.size.height;
                break;
            case UIDeviceOrientationLandscapeRight:
                image = [image rotate:90.0f];
                previewHeight = preview.bounds.size.width;
                previewWidth = preview.bounds.size.height;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                image = [image rotate:180.0f];
                break;
            default:
                break;
        }
        image = [image reorientToOrientation:UIImageOrientationUp];
        
        CGFloat imageWidth = image.size.width;
        CGFloat imageHeight = image.size.height;
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
        if (cropHeight != imageHeight || cropWidth != imageWidth) {
            imageHandler([image crop:CGRectMake(cropX, cropY, cropWidth, cropHeight)]);
        } else {
            imageHandler(image);
        }
    }];
}

@end


#endif
