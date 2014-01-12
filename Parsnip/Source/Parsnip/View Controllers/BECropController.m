#import "BECropController.h"

#import "BECroppableImageView.h"
#import "BENoteController.h"
#import "BENote.h"
#import "BEUI.h"
#import "UIViewController+Dialog.h"
#import "UIViewController+Tools.h"


@implementation BECropController
{
    UIBarButtonItem *okButton;
    BECroppableImageView *cropView;
    NSDate *imageDate;
    BOOL initialAppearance;

    void (^navigationControllerPushCompletion)(BOOL finished);
}

static CGFloat cropMaskAlpha;
static CGFloat cropZoomStep;
static CGFloat cropZoomMargin;
static CGFloat cropMaximumZoomScale;
static BOOL cropSymmetrical;
static NSString *cropTitle;

+ (void)initialize
{
    cropMaskAlpha = [BEUI.theme floatForKey:@"Crop.MaskAlpha" withDefault:0.5f];
    cropZoomStep = [BEUI.theme floatForKey:@"Crop.ZoomStep" withDefault:1.5f];
    cropZoomMargin = [BEUI.theme floatForKey:@"Crop.ZoomMargin" withDefault:16.0f];
    cropMaximumZoomScale = [BEUI.theme floatForKey:@"Crop.MaximumZoomScale" withDefault:5.0f];
    cropSymmetrical = [BEUI.theme boolForKey:@"Crop.Symmetrical" withDefault:NO];
    cropTitle = [BEUI.theme stringForKey:@"Crop.Title"];
}

@synthesize image = _image;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        initialAppearance = YES;
        self.title = cropTitle;
        self.manuallyAdjustsViewInsets = YES;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:self.frameForView];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect frame = self.view.bounds;
    cropView = [[BECroppableImageView alloc] initWithFrame:frame];
    cropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cropView.backgroundColor = [UIColor blackColor];
    cropView.maskAlpha = cropMaskAlpha;
    cropView.zoomStep = cropZoomStep;
    cropView.zoomMargin = cropZoomMargin;
    cropView.maximumZoomScale = cropMaximumZoomScale;
    cropView.symmetrical = cropSymmetrical;
    [self.view addSubview:cropView];

    okButton = [BEUI barButtonItemWithKey:@[@"NavigationBarOkButton", @"NavigationBarButton"] target:self action:@selector(onOkButtonTouch)];
    self.navigationItem.rightBarButtonItem = okButton;
    [self updateLeftBarButtonItemWithCancel:NO];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    UIEdgeInsets insets = self.insetsForView;
    if (!UIEdgeInsetsEqualToEdgeInsets(insets, cropView.contentInset)) {
        cropView.contentInset = insets;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    UIEdgeInsets insets = self.insetsForView;
    if (!UIEdgeInsetsEqualToEdgeInsets(insets, cropView.contentInset)) {
        cropView.contentInset = insets;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (initialAppearance) {
        initialAppearance = NO;
        cropView.contentInset = self.insetsForView;
        cropView.image = _image;
    }
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    imageDate = [NSDate date];
    cropView.image = image;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (navigationControllerPushCompletion) {
        navigationControllerPushCompletion(YES);
        navigationControllerPushCompletion = nil;
    }
}

- (void)onOkButtonTouch
{
    BENote *note = [[BENote alloc] init];
    note.rawImage = _image;
    note.rawImageTimestamp = imageDate;
    note.croppedImage = [cropView getCroppedImage];
    note.croppedImageTimestamp = [NSDate date];
    note.croppedImageFrame = cropView.cropFrame;
    note.croppedImageTransform = cropView.imageTransform;
    note.croppedImageOffset = cropView.imageOffset;
    note.croppedImageScale = cropView.imageScale;
    note.croppedImageRotation = cropView.imageRotation;

    BENoteController *noteController = [[BENoteController alloc] init];
    [noteController view];

    CGRect startFrame = [self.navigationController.view convertRect:cropView.selectedFrame fromView:cropView];

    UIImageView *transitionView = [[UIImageView alloc] initWithImage:note.croppedImage];
    transitionView.contentMode = UIViewContentModeScaleAspectFit;
    transitionView.frame = startFrame;

    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, startFrame.size.width, startFrame.size.height)];
    maskView.backgroundColor = [UIColor blackColor];
    maskView.alpha = 0.0f;
    [transitionView addSubview:maskView];

    NSObject<UINavigationControllerDelegate> *navigationControllerDelegate = self.navigationController.delegate;
    UINavigationController *navigationController = self.navigationController;
    navigationControllerPushCompletion = ^(BOOL finished) {
        [noteController scan:note];
        [transitionView removeFromSuperview];
        navigationController.delegate = navigationControllerDelegate;
    };

    CGRect frame = self.frameForView;
    [noteController layoutForImage:note.croppedImage inFrame:CGRectOffset(frame, 0.0f - frame.origin.x, 0.0f - frame.origin.y)];
    [self.navigationController.view addSubview:transitionView];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        CGRect finishFrame = [noteController frameForImage:note.croppedImage inFrame:frame];
        CGRect maskFrame = finishFrame;
        CGFloat maskRatio = note.croppedImage.size.width / note.croppedImage.size.height;
        CGFloat frameRatio = finishFrame.size.width / finishFrame.size.height;
        if (maskRatio < frameRatio) {
            CGFloat width = finishFrame.size.height * maskRatio;
            maskFrame = CGRectMake(finishFrame.origin.x + (finishFrame.size.width - width) / 2,
                                   0.0f,
                                   width,
                                   finishFrame.size.height);
        } else {
            maskFrame.origin.x = 0.0f;
            maskFrame.origin.y = 0.0f;
        }
        transitionView.frame = finishFrame;
        maskView.frame = maskFrame;
        maskView.alpha = noteController.scannerView.maskAlpha;
    } completion:nil];

    self.navigationController.delegate = self;
    [self.navigationController pushViewController:noteController animated:YES];
}

@end
