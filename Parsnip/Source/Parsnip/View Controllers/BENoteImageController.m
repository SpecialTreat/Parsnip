#import "BENoteImageController.h"

#import "BEUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIColor+Tools.h"
#import "UIDevice+Tools.h"
#import "UIViewController+Tools.h"
#import "UIImage+Drawing.h"


typedef enum _NoteImageState {
    NoteImageStateUnknown = 0,
    NoteImageStateNormal,
    NoteImageStateSpotlight,
    NoteImageStateOcr
} NoteImageState;


@implementation BENoteImageController
{
    BOOL isNoteRendered;
    NoteImageState imageState;

    UIScrollView *_scrollView;
    UIImageView *_imageView;

    UITapGestureRecognizer *tapRecognizer;
    UITapGestureRecognizer *doubleTapRecognizer;
    UILongPressGestureRecognizer *tapAndHoldRecognizer;
    CGPoint currentTapAndHoldPoint;

    UIView *toolbarContainer;
    UIToolbar *_toolbar;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *spotlightButton;
    UIBarButtonItem *ocrButton;
    UIBarButtonItem *normalButton;

    UIView *_cropViewContainer;
    UIImageView *_cropView;
    UIView *spotlightMask;
    UIView *_spotlightView;
    UIImageView *ocrView;
}

static CGFloat noteImageMaskAlpha;
static CGFloat noteImageMaximumZoomScale;
static CGFloat noteImageToolbarHeight;
static CGFloat spotlightBorderWidth;

+ (void)initialize
{
    noteImageToolbarHeight = [BEUI.theme floatForKey:@"NavigationBarBlack.Height"];
    noteImageMaximumZoomScale = [BEUI.theme floatForKey:@"NoteImage.MaximumZoomScale" withDefault:4.0f];
    noteImageMaskAlpha = [BEUI.theme floatForKey:@"NoteImage.MaskAlpha" withDefault:0.5f];
    spotlightBorderWidth = [BEUI.theme floatForKey:@"NoteImage.SpotlightBorderWidth" withDefault:1.0f];
}

@synthesize note = _note;
@synthesize scrollView = _scrollView;
@synthesize imageView = _imageView;
@synthesize cropViewContainer = _cropViewContainer;
@synthesize cropView = _cropView;
@synthesize spotlightView = _spotlightView;
@synthesize toolbar = _toolbar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isNoteRendered = NO;
        imageState = NoteImageStateUnknown;
        self.manuallyAdjustsViewInsets = YES;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (UIDevice.isIOS7) {
        return UIStatusBarStyleLightContent;
    } else {
        return BEUI.preferredStatusBarStyle;
    }
}

- (UIEdgeInsets)scrollContentInset
{
    UIEdgeInsets insets = [self insetsForViewNavigationBarHidden:YES statusBarHidden:NO];
    insets.top += noteImageToolbarHeight;
    return insets;
}

- (CGRect)scrollContentFrame
{
    CGRect frame = [self boundsForViewNavigationBarHidden:YES statusBarHidden:YES];
    CGFloat statusBarHeight = self.statusBarHeight;
    CGFloat statusBarInset = (UIDevice.isIOS7)? MIN(20.0f, statusBarHeight): statusBarHeight;
    frame.origin.y = (statusBarInset + noteImageToolbarHeight);
    frame.size.height -= (statusBarHeight + noteImageToolbarHeight);
    return frame;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[self frameForViewNavigationBarHidden:YES statusBarHidden:NO]];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.clipsToBounds = YES;
    _scrollView.scrollEnabled = YES;
    _scrollView.alwaysBounceHorizontal = YES;
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.contentInset = self.scrollContentInset;

    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onScrollViewTap:)];
    tapRecognizer.delegate = self;
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [_scrollView addGestureRecognizer:tapRecognizer];

    doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onScrollViewDoubleTap:)];
    doubleTapRecognizer.delegate = self;
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [_scrollView addGestureRecognizer:doubleTapRecognizer];

    tapAndHoldRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onScrollViewTapAndHold:)];
    tapAndHoldRecognizer.delegate = self;
    tapAndHoldRecognizer.allowableMovement = self.view.bounds.size.height;
    tapAndHoldRecognizer.minimumPressDuration = 0.0f;
    tapAndHoldRecognizer.numberOfTapsRequired = 1;
    tapAndHoldRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapAndHoldRecognizer];

    [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    [tapRecognizer requireGestureRecognizerToFail:tapAndHoldRecognizer];

    [tapAndHoldRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];

    UIEdgeInsets insets = [self insetsForViewNavigationBarHidden:YES statusBarHidden:NO];

    CGRect toolbarContainerFrame = CGRectMake(0, 0, self.view.bounds.size.width, noteImageToolbarHeight);
    CGRect toolbarFrame = toolbarContainerFrame;

    if (UIDevice.isIOS7) {
        toolbarFrame.origin.y = insets.top;
        toolbarContainerFrame.size.height += insets.top;
    } else {
        toolbarContainerFrame.origin.y = insets.top;
    }

    toolbarContainer = [[UIView alloc] initWithFrame:toolbarContainerFrame];
    toolbarContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    toolbarContainer.backgroundColor = [BEUI.theme colorForKey:@"NavigationBarBlack.BackgroundColor"];

    _toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _toolbar.clipsToBounds = YES;
    [_toolbar setBackgroundImage:[UIImage clearImage] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];

    doneButton = [BEUI barButtonItemWithKey:@[@"NavigationBarBlackDoneButton", @"NavigationBarBlackButton"] target:self action:@selector(onDoneButtonItemTouch)];
    spotlightButton = [BEUI barButtonItemWithKey:@[@"NavigationBarNormalImageButton", @"NavigationBarBlackButton"] target:self action:@selector(onSpotlightButton)];
    normalButton = [BEUI barButtonItemWithKey:@[@"NavigationBarOcrImageButton", @"NavigationBarBlackButton"] target:self action:@selector(onNormalButton)];
    ocrButton = [BEUI barButtonItemWithKey:@[@"NavigationBarSpotlightImageButton", @"NavigationBarBlackButton"] target:self action:@selector(onOcrButton)];

    _toolbar.items = @[doneButton, [UIBarButtonItem spacer], ocrButton];

    [self.view addSubview:_scrollView];
    [toolbarContainer addSubview:_toolbar];
    [self.view addSubview:toolbarContainer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (_note && !isNoteRendered) {
        self.note = _note;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGRect toolbarContainerFrame = CGRectMake(0, 0, self.view.bounds.size.width, noteImageToolbarHeight);
    CGRect toolbarFrame = toolbarContainerFrame;
    UIEdgeInsets insets = [self insetsForViewNavigationBarHidden:YES statusBarHidden:NO];

    if (UIDevice.isIOS7) {
        toolbarFrame.origin.y = insets.top;
        toolbarContainerFrame.size.height += insets.top;
    } else {
        toolbarContainerFrame.origin.y = insets.top;
    }

    if (!CGRectEqualToRect(toolbarContainer.frame, toolbarContainerFrame)) {
        toolbarContainer.frame = toolbarContainerFrame;
    }

    if (!CGRectEqualToRect(_toolbar.frame, toolbarFrame)) {
        _toolbar.frame = toolbarFrame;
    }

    _scrollView.contentInset = self.scrollContentInset;

    CGFloat minimumZoomScale = [self minimumZoomScaleForCurrentBoundsWithMargin:0.0f];
    if (minimumZoomScale != _scrollView.minimumZoomScale) {
        BOOL shouldZoom = (_scrollView.zoomScale <= _scrollView.minimumZoomScale || _scrollView.zoomScale <= minimumZoomScale);
        _scrollView.minimumZoomScale = minimumZoomScale;
        if (shouldZoom) {
            [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
        }
    }
    [self centerScrollViewContents];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)dealloc
{
    tapAndHoldRecognizer.delegate = nil;
    doubleTapRecognizer.delegate = nil;
    tapRecognizer.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)onDoneButtonItemTouch
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSpotlightButton
{
    imageState = NoteImageStateSpotlight;
    _toolbar.items = @[doneButton, [UIBarButtonItem spacer], ocrButton];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        _cropView.alpha = 1.0f;
        ocrView.alpha = 0.0f;
        spotlightMask.alpha = noteImageMaskAlpha;
        _spotlightView.alpha = 1.0f;
    }];
}

- (void)onOcrButton
{
    imageState = NoteImageStateOcr;
    if (!ocrView.image) {
        ocrView.image = _note.ocrImage;
    }
    _toolbar.items = @[doneButton, [UIBarButtonItem spacer], normalButton];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        ocrView.alpha = 1.0f;
        spotlightMask.alpha = noteImageMaskAlpha;
    } completion:^(BOOL finished) {
        _spotlightView.alpha = 0.0f;
    }];
}

- (void)onNormalButton
{
    imageState = NoteImageStateNormal;
    _toolbar.items = @[doneButton, [UIBarButtonItem spacer], spotlightButton];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        _cropView.alpha = 0.0f;
        ocrView.alpha = 0.0f;
        spotlightMask.alpha = 0.0f;
        _spotlightView.alpha = 0.0f;
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ((gestureRecognizer == _scrollView.panGestureRecognizer && otherGestureRecognizer == tapAndHoldRecognizer) ||
        (gestureRecognizer == tapAndHoldRecognizer && otherGestureRecognizer == _scrollView.panGestureRecognizer) ||
        (gestureRecognizer == doubleTapRecognizer && otherGestureRecognizer == tapAndHoldRecognizer) ||
        (gestureRecognizer == tapAndHoldRecognizer && otherGestureRecognizer == doubleTapRecognizer)) {
        return NO;
    }
    return YES;
}

- (void)setNote:(BENote *)note
{
    _note = note;
    if (self.isViewLoaded) {
        isNoteRendered = YES;

        if (_imageView) {
            [_imageView removeFromSuperview];
            _imageView = nil;
        }

        if (_cropViewContainer) {
            [_cropViewContainer removeFromSuperview];
            _cropViewContainer = nil;
        }

        if (ocrView) {
            [ocrView removeFromSuperview];
            ocrView = nil;
        }

        if (_cropView) {
            [_cropView removeFromSuperview];
            _cropView = nil;
        }

        if (spotlightMask) {
            [spotlightMask removeFromSuperview];
            spotlightMask = nil;
        }

        UIEdgeInsets contentInset = _scrollView.contentInset;
        CGRect contentFrame = CGRectMake(contentInset.left,
                                         contentInset.top,
                                         _scrollView.bounds.size.width - contentInset.left - contentInset.right,
                                         _scrollView.bounds.size.height - contentInset.top - contentInset.bottom);

        _imageView = [[UIImageView alloc] initWithImage:_note.rawImage];
        _imageView.frame = CGRectMake(0, 0, _note.rawImage.size.width, _note.rawImage.size.height);
        [_scrollView addSubview:_imageView];

        _scrollView.contentSize = _note.rawImage.size;
        _scrollView.minimumZoomScale = [self minimumZoomScaleForCurrentBoundsWithMargin:0.0f];
        _scrollView.maximumZoomScale = noteImageMaximumZoomScale;
        _scrollView.zoomScale = _scrollView.minimumZoomScale;

        spotlightMask = [[UIView alloc] initWithFrame:_imageView.bounds];
        spotlightMask.alpha = noteImageMaskAlpha;
        spotlightMask.backgroundColor = [UIColor blackColor];
        [_imageView addSubview:spotlightMask];

        _cropViewContainer = [[UIView alloc] initWithFrame:contentFrame];

        CGRect croppedFrame = CGRectOffset(_note.croppedImageFrame,
                                           _cropViewContainer.bounds.size.width / 2.0f,
                                           _cropViewContainer.bounds.size.height / 2.0f);

        if (_note.preOcrImage) {
            _cropView = [[UIImageView alloc] initWithImage:_note.preOcrImage];
        } else {
            _cropView = [[UIImageView alloc] initWithImage:_note.croppedImage];
        }
        _cropView.frame = croppedFrame;
        [_cropViewContainer addSubview:_cropView];

        _spotlightView = [[UIView alloc] initWithFrame:croppedFrame];
        _spotlightView.layer.borderColor = [UIColor whiteColor].CGColor;
        _spotlightView.layer.borderWidth = spotlightBorderWidth / [UIScreen mainScreen].scale;
        [_cropViewContainer addSubview:_spotlightView];

        ocrView = [[UIImageView alloc] init];
        ocrView.alpha = 0.0f;
        ocrView.frame = croppedFrame;
        [_cropViewContainer addSubview:ocrView];

        _cropViewContainer.transform = CGAffineTransformInvert(_note.croppedImageTransform);
        _cropViewContainer.center = CGPointMake(_imageView.bounds.size.width / 2.0f, _imageView.bounds.size.height / 2.0f);
        [_imageView addSubview:_cropViewContainer];

        imageState = NoteImageStateSpotlight;

        [self centerScrollViewContents];
    }
}

- (CGFloat)minimumZoomScaleForCurrentBoundsWithMargin:(CGFloat)margin
{
    CGRect bounds = self.scrollContentFrame;
    CGSize boundsSize = CGSizeMake(bounds.size.width - (margin * 2.0f), bounds.size.height - (margin * 2.0f));
    CGSize imageSize = _imageView.image.size;
    return MIN(boundsSize.width / imageSize.width, boundsSize.height / imageSize.height);
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)_scrollView
{
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)_scrollView
{
    [self centerScrollViewContents];
}

- (void)centerScrollViewContents
{
    UIEdgeInsets contentInset = _scrollView.contentInset;
    CGRect boundsFrame = CGRectMake(contentInset.left,
                                    contentInset.top,
                                    _scrollView.bounds.size.width - contentInset.left - contentInset.right,
                                    _scrollView.bounds.size.height - contentInset.top - contentInset.bottom);
    CGRect contentFrame = _imageView.frame;

    if (contentFrame.size.width < boundsFrame.size.width) {
        contentFrame.origin.x = (boundsFrame.size.width - contentFrame.size.width) / 2.0f;
    } else {
        contentFrame.origin.x = 0.0f;
    }

    if (contentFrame.size.height < boundsFrame.size.height) {
        contentFrame.origin.y = (boundsFrame.size.height - contentFrame.size.height) / 2.0f;
    } else {
        contentFrame.origin.y = 0.0f;
    }

    _imageView.frame = contentFrame;
}

- (void)onScrollViewTap:(UITapGestureRecognizer *)recognizer
{
    if (imageState == NoteImageStateNormal) {
        [self onSpotlightButton];
    } else if (imageState == NoteImageStateSpotlight) {
        [self onOcrButton];
    } else if (imageState == NoteImageStateOcr) {
        [self onNormalButton];
    }
}

- (void)onScrollViewDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:_imageView];

    UIEdgeInsets contentInset = _scrollView.contentInset;
    CGRect boundsFrame = CGRectMake(contentInset.left,
                                    contentInset.top,
                                    _scrollView.bounds.size.width - contentInset.left - contentInset.right,
                                    _scrollView.bounds.size.height - contentInset.top - contentInset.bottom);
    CGFloat scale = _scrollView.minimumZoomScale;
    CGPoint offset = _scrollView.contentOffset;
    if (ABS(offset.x + contentInset.left) < 0.00001 &&
        ABS(offset.y + contentInset.top) < 0.00001 &&
        _scrollView.zoomScale == _scrollView.minimumZoomScale) {

        scale = 1.0f;
        offset.x = tapPoint.x - (boundsFrame.size.width / 2.0f);
        offset.y = tapPoint.y - (boundsFrame.size.height / 2.0f);
    }
    scale = MIN(scale, _scrollView.maximumZoomScale);

    CGFloat width = boundsFrame.size.width / scale;
    CGFloat height = boundsFrame.size.height / scale;
    CGFloat x = tapPoint.x - (width / 2.0f);
    CGFloat y = tapPoint.y - (height / 2.0f);

    [_scrollView zoomToRect:CGRectMake(x, y, width, height) animated:YES];
}

- (void)onScrollViewTapAndHold:(UILongPressGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        currentTapAndHoldPoint = [recognizer locationInView:self.view];
    } else {
        CGPoint tapAndHoldPoint = [recognizer locationInView:self.view];
        CGFloat deltaY = currentTapAndHoldPoint.y - tapAndHoldPoint.y;
        CGFloat yPercent = (deltaY / self.view.bounds.size.height);
        CGFloat deltaScale = yPercent * ((_scrollView.maximumZoomScale - _scrollView.minimumZoomScale) / 2.0f);
        currentTapAndHoldPoint = tapAndHoldPoint;

        [_scrollView setZoomScale:(1.0f + deltaScale) * _scrollView.zoomScale animated:NO];
    }
}

@end
