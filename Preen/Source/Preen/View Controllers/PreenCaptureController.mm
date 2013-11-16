#import "PreenCaptureController.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <QuartzCore/QuartzCore.h>
#import "JASidePanelController.h"
#import "PreenCameraView.h"
#import "PreenCropController.h"
#import "PreenNoteSheetController.h"
#import "PreenNoteController.h"
#import "PreenPopoverBackgroundView.h"
#import "PreenUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIImage+Drawing.h"
#import "UIImage+Manipulation.h"
#import "UIViewController+JASidePanel.h"
#import "UIViewController+Tools.h"
#import "UIImagePickerController+AutoRotation.h"


@implementation PreenCaptureController
{
    PreenCameraView *cameraView;

    UIToolbar *toolbar;
    UIBarButtonItem *cameraButton;
    UIBarButtonItem *backButton;
    UIBarButtonItem *libraryButton;
}

@synthesize popover = _popover;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.manuallyAdjustsViewInsets = YES;
    }
    return self;
}

- (void)loadView
{
    CGRect frame = self.frameForView;
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect frame = self.view.bounds;
    CGFloat toolbarHeight = [PreenUI.theme floatForKey:@"CaptureToolbar.Height"];
    UIEdgeInsets cameraMargin = [PreenUI.theme edgeInsetsForKey:@"CaptureCamera.Margin"];
	cameraView = [[PreenCameraView alloc] initWithFrame:CGRectMake(cameraMargin.left,
                                                                   cameraMargin.top,
                                                                   frame.size.width - (cameraMargin.left + cameraMargin.right),
                                                                   frame.size.height - (cameraMargin.top + cameraMargin.bottom))];
    cameraView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    cameraButton = [PreenUI barButtonItemWithKey:@[@"CaptureToolbarCameraButton", @"CaptureToolbarButton"] target:self action:@selector(captureImage)];
    backButton = [PreenUI barButtonItemWithKey:@[@"CaptureToolbarBackButton", @"CaptureToolbarButton", @"NavigationBarBackButton", @"NavigationBarButton"] target:self action:@selector(showInfoView)];
    libraryButton = [PreenUI barButtonItemWithKey:@[@"CaptureToolbarPhotoLibraryButton", @"CaptureToolbarButton", @"NavigationBarPhotoLibraryButton", @"NavigationBarButton"] target:self action:@selector(pickImage)];
    libraryButton.customView.hidden = ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];

    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - toolbarHeight, frame.size.width, toolbarHeight)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    toolbar.clipsToBounds = [PreenUI.theme boolForKey:@"CaptureToolbar.ClipsToBounds" withDefault:YES];
    [toolbar setBackgroundImage:[PreenUI.theme imageForKey:@"CaptureToolbar.BackgroundImage"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    toolbar.items = @[backButton, [UIBarButtonItem spacer], cameraButton, [UIBarButtonItem spacer], libraryButton];

    [self.view addSubview:cameraView];
    [self.view addSubview:toolbar];

    [self initDeviceListeners];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [cameraView startVideo];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    // [cameraView stopVideo];
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

- (void)onDeviceOrientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [UIView animateWithDuration: 0.5 animations:^{
        switch(orientation) {
            case UIDeviceOrientationPortraitUpsideDown:
                cameraButton.customView.transform = CGAffineTransformMakeRotation(M_PI);
                break;

            case UIDeviceOrientationLandscapeLeft:
                cameraButton.customView.transform = CGAffineTransformMakeRotation(M_PI / 2);
                break;

            case UIDeviceOrientationLandscapeRight:
                cameraButton.customView.transform = CGAffineTransformMakeRotation(3 * M_PI / 2);
                break;

            default:
                cameraButton.customView.transform = CGAffineTransformMakeRotation(0);
                break;
        }
    }];
}

- (void)popoverControllerDidDismissPopover:(PreenPopoverController *)popoverController
{
    self.popover = nil;
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    [PreenUI styleStatusBar];
    [PreenUI styleNavigationBar:navigationController.navigationBar];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
    image = [image reorientToOrientation:UIImageOrientationUp];

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [picker dismissViewControllerAnimated:NO completion:nil];
        [self.popover dismissPopoverAnimated:YES];
        picker.delegate = nil;
        self.popover.delegate = nil;
        self.popover = nil;
        [self presentCropViewController:image animated:YES completion:nil];
    } else {
        PreenCropController *viewController = [[PreenCropController alloc] init];
        viewController.image = image;
        [picker pushViewController:viewController animated:YES];
    }
}

- (void)pickImage
{
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [PreenUI styleNavigationBar:picker.navigationBar];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if(!self.popover) {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
            self.popover.popoverBackgroundViewClass = [PreenPopoverBackgroundViewDefaultContentAppearance class];
            self.popover.delegate = self;
            [self.popover presentPopoverFromBarButtonItem:libraryButton
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
        }
    } else {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)captureImage
{
    cameraButton.enabled = NO;
    [self showFlash];
    [self dismissPopover:NO];
    [cameraView captureImage:^(UIImage *image) {
        PreenCropController *viewController = [self presentCropViewController:image];
        [viewController showFlash];
        cameraButton.enabled = YES;
        [self hideFlash];
        [viewController hideFlash:YES completion:nil];
    }];
}

- (void)dismissPopover
{
    [self dismissPopover:YES];
}

- (void)dismissPopover:(BOOL)animated
{
    if(self.popover) {
        [self.popover dismissPopoverAnimated:animated];
        self.popover = nil;
    }
}

- (void)showInfoView
{
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (void)hideInfoView
{
    [self.sidePanelController showCenterPanelAnimated:YES];
}

- (PreenCropController *)presentCropViewController:(UIImage *)image
{
    return [self presentCropViewController:image animated:NO completion:nil];
}

- (PreenCropController *)presentCropViewController:(UIImage *)image
                                              animated:(BOOL)flag
                                            completion:(void (^)())completion
{
    PreenCropController *cropController = [[PreenCropController alloc] init];
    cropController.image = image;
    [self presentNavigableViewController:cropController animated:flag completion:completion];
    return cropController;
}

@end
