#import "BENoteController.h"

#import <QuartzCore/QuartzCore.h>
#import "NSString+Tools.h"
#import "BEAlertView.h"
#import "BEDB.h"
#import "BENoteImageController.h"
#import "BENoteSheetController.h"
#import "BEOcr.h"
#import "BEPopoverBackgroundView.h"
#import "BEPopoverController.h"
#import "BETextData.h"
#import "BEThread.h"
#import "BEUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIColor+Tools.h"
#import "UIDevice+Tools.h"
#import "UIImage+Drawing.h"
#import "UIImage+Manipulation.h"
#import "UIViewController+Tools.h"
#import "UIView+Tools.h"


@implementation BENoteController
{
//    UIBarButtonItem *keepButton;
    UIBarButtonItem *copyButton;
    UIBarButtonItem *archiveButton;
    UIBarButtonItem *unarchiveButton;
    UIBarButtonItem *discardButton;
    UIToolbar *toolbar;

    UIBarButtonItem *dismissKeyboardButton;
    UIBarButtonItem *plusButton;
    BEAlertView *alert;
    UITextView *textView;
    BETouchableView *touchableView;
    UIScrollView *scrollView;
    BOOL initialAppearance;

    void (^navigationControllerPushCompletion)(BOOL finished);
}

static NSString *noteScanningTitle;
static NSString *noteEmptyTitle;
static CGFloat scannerMaskAlpha;
static CGFloat scannerSweepDuration;
static CGFloat scannerFadeDuration;

static CGFloat toolbarButtonWidth;
static CGFloat toolbarHeight;
static CGFloat toolbarSpacer;
static UIEdgeInsets toolbarMargin;

static UIEdgeInsets noteSheetPopoverLayoutMargins;
static UIEdgeInsets noteSheetPopoverContentViewInsets;
static CGFloat noteSheetPopoverMaskAlpha;
static BOOL noteSheetPopoverBackgroundClipsToBounds;

static CGSize noteDiscardAlertSize;

+ (void)initialize
{
    noteScanningTitle = [BEUI.theme stringForKey:@"Note.ScanningTitle"];
    noteEmptyTitle = [BEUI.theme stringForKey:@"Note.EmptyTitle"];
    scannerMaskAlpha = [BEUI.theme floatForKey:@"Scanner.MaskAlpha" withDefault:0.5f];
    scannerSweepDuration = [BEUI.theme floatForKey:@"Scanner.SweepDuration" withDefault:2.0f];
    scannerFadeDuration = [BEUI.theme floatForKey:@"Scanner.FadeDuration" withDefault:0.3f];

    toolbarButtonWidth = [BEUI.theme floatForKey:@"NoteToolbarButton.Width"];
    toolbarSpacer = [BEUI.theme floatForKey:@"NoteToolbar.Spacer"];
    toolbarHeight = [BEUI.theme floatForKey:@"NoteToolbar.Height"];
    toolbarMargin = [BEUI.theme edgeInsetsForKey:@"NoteToolbar.Margin"];

    noteSheetPopoverLayoutMargins = [BEUI.theme edgeInsetsForKey:@"NoteSheetPopover.Margin"];
    noteSheetPopoverContentViewInsets = [BEUI.theme edgeInsetsForKey:@"NoteSheetPopover.Padding"];
    noteSheetPopoverMaskAlpha = [BEUI.theme floatForKey:@"NoteSheetPopover.MaskAlpha"];
    noteSheetPopoverBackgroundClipsToBounds = [BEUI.theme boolForKey:@"NoteSheetPopover.Background.ClipsToBounds" withDefault:YES];

    noteDiscardAlertSize = [BEUI.theme sizeForKey:@[@"NoteDiscardAlert", @"Alert"] withSubkey:@"BackgroundSize" withDefault:CGSizeMake(240.0f, 120.0f)];
}

@synthesize note = _note;
@synthesize popover = _popover;
@synthesize isDirty = _isDirty;
@synthesize imageView = _imageView;
@synthesize imageViewBackground = _imageViewBackground;
@synthesize scannerView = _scannerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isDirty = NO;
        initialAppearance = YES;
        self.title = noteScanningTitle;
        self.manuallyAdjustsViewInsets = YES;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:self.frameForView];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect frame = self.view.bounds;

    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - toolbarHeight)];
    scrollView.alwaysBounceHorizontal = NO;
    scrollView.alwaysBounceVertical = YES;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.backgroundColor = [BEUI.theme colorForKey:@"Note.BackgroundColor"];
    scrollView.bounces = YES;
    scrollView.clipsToBounds = YES;

    dismissKeyboardButton = [BEUI barButtonItemWithKey:@[@"NavigationBarDismissKeyboardButton", @"NavigationBarButton"] target:self action:@selector(onDismissKeyboardButtonTouch)];
    plusButton = [BEUI barButtonItemWithKey:@[@"NavigationBarPlusButton", @"NavigationBarButton"] target:self action:@selector(onPlusButtonTouch)];
    plusButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = plusButton;

    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.navigationItem.titleView = [BEUI styleNavigationBarTitleView:titleView];
    [self setTitle:self.title];
    [self updateTitleStyle];

    _imageView = [[UIImageView alloc] init];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.opaque = YES;
    _imageView.hidden = YES;

    _imageViewBackground = [[UIView alloc] init];
    _imageViewBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _imageViewBackground.backgroundColor = [UIColor blackColor];

    touchableView = [[BETouchableView alloc] init];
    touchableView.delegate = self;

    _scannerView = [[BEScannerView alloc] init];
    _scannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _scannerView.hidden = YES;
    _scannerView.maskAlpha = scannerMaskAlpha;
    _scannerView.sweepDuration = scannerSweepDuration;
    _scannerView.fadeDuration = scannerFadeDuration;

    textView = [[UITextView alloc] init];
    textView.font = [BEUI.theme fontForKey:@"Note.Font"];
    textView.textColor = [BEUI.theme colorForKey:@"Note.TextColor"];
    textView.backgroundColor = [BEUI.theme colorForKey:@"Note.BackgroundColor"];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.delegate = self;

//    keepButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarSaveButton", @"NoteToolbarButton"] target:self action:@selector(onKeepButtonTouch:event:)];
    copyButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarCopyButton", @"NoteToolbarButton"] target:self action:@selector(onCopyButtonTouch:event:)];
    archiveButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarArchiveButton", @"NoteToolbarButton"] target:self action:@selector(onArchiveButtonTouch:event:)];
    unarchiveButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarUnarchiveButton", @"NoteToolbarButton"] target:self action:@selector(onUnarchiveButtonTouch:event:)];
    discardButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarDeleteButton", @"NoteToolbarButton"] target:self action:@selector(onDiscardButtonTouch:event:)];

    BOOL hasNote = !!_note;
    copyButton.enabled = hasNote;
    archiveButton.enabled = hasNote;
    unarchiveButton.enabled = hasNote;
    discardButton.enabled = hasNote;

    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(toolbarMargin.left,
                                                          frame.size.height - toolbarHeight + toolbarMargin.top,
                                                          frame.size.width - (toolbarMargin.left + toolbarMargin.right),
                                                          toolbarHeight - (toolbarMargin.top + toolbarMargin.bottom))];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [toolbar setBackgroundImage:[BEUI.theme imageForKey:@"NoteToolbar.BackgroundImage"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [toolbar setShadowImage:[BEUI.theme imageForKey:@"NoteToolbar.ShadowImage"] forToolbarPosition:UIToolbarPositionAny];

    [self updateToolbarButtonsAnimated:NO];

    [scrollView addSubview:textView];
    [scrollView addSubview:_imageViewBackground];
    [scrollView addSubview:_imageView];
    [scrollView addSubview:touchableView];
    [scrollView addSubview:_scannerView];
    [self.view addSubview:scrollView];
    [self.view addSubview:toolbar];

    [self initDeviceListeners];
}

- (void)dealloc
{
    textView.delegate = nil;
    touchableView.delegate = nil;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self layoutSubviews];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self layoutSubviews];
    if (self.popover) {
        CGFloat arrowHeight = [BEPopoverBackgroundView arrowHeight];
        CGRect buttonFrame = plusButton.internalView.frame;
        buttonFrame = [self.navigationController.view convertRect:buttonFrame fromView:self.navigationController.navigationBar];
        buttonFrame.size.height = buttonFrame.size.height - (arrowHeight - self.popover.popoverLayoutMargins.top);

        [self.popover presentPopoverFromRect:buttonFrame
                                      inView:self.navigationController.view
                    permittedArrowDirections:UIPopoverArrowDirectionUp
                                    animated:NO];
        self.popover.backgroundView.clipsToBounds = noteSheetPopoverBackgroundClipsToBounds;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    if (initialAppearance) {
        initialAppearance = NO;
        UIEdgeInsets insets = self.insetsForView;
        scrollView.contentOffset = CGPointMake(0.0f - insets.left, 0.0f - insets.top);
    }
    [self layoutSubviews];

    if (self.popover) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.popover.view.alpha = 1.0f;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)layoutSubviews
{
    CGRect frame = [self boundsForViewStatusBarHidden:YES];
    UIEdgeInsets insets = self.insetsForView;
    scrollView.contentInset = insets;
    scrollView.scrollIndicatorInsets = insets;

    if (_note) {
        [self layoutForImage:_note.croppedImage inFrame:frame];
    }
}

- (void)layoutForImage:(UIImage *)image inFrame:(CGRect)frame
{
    CGRect imageViewFrame = [self frameForImage:image inFrame:frame];
    _imageView.frame = imageViewFrame;
    _imageViewBackground.frame = imageViewFrame;
    _scannerView.frame = imageViewFrame;
    touchableView.frame = imageViewFrame;

    [self layoutTextView];
}

- (void)layoutTextView
{
    CGRect textViewFrame = [self frameForTextView];
    if (!CGRectEqualToRect(textViewFrame, textView.frame)) {
        textView.frame = textViewFrame;
    }
    CGSize scrollViewContentSize = CGSizeMake(scrollView.frame.size.width, _imageView.frame.size.height + textView.frame.size.height);
    if (!CGSizeEqualToSize(scrollViewContentSize, scrollView.contentSize)) {
        scrollView.contentSize = scrollViewContentSize;
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (navigationControllerPushCompletion) {
        navigationControllerPushCompletion(YES);
        navigationControllerPushCompletion = nil;
    }
}

- (void)initDeviceListeners
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(onKeyboardDidShow:)
                               name:UIKeyboardDidShowNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(onKeyboardWillHide:)
                               name:UIKeyboardWillHideNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(onKeyboardWillShow:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
}

- (void)onKeyboardDidShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat keyboardHeight = keyboardSize.height;
    if (keyboardSize.height > keyboardSize.width) {
        keyboardHeight = keyboardSize.width;
    }
    CGRect frame = self.view.bounds;
    frame.size.height -= keyboardHeight;
    scrollView.frame = frame;
    [self layoutTextView];
}

- (void)onKeyboardWillHide:(NSNotification *)notification
{
    [self.navigationItem setRightBarButtonItem:plusButton animated:YES];
    scrollView.frame = self.view.bounds;
    [self layoutTextView];
    touchableView.userInteractionEnabled = YES;
}

- (void)onKeyboardWillShow:(NSNotification *)notification
{
    touchableView.userInteractionEnabled = NO;
    [self.navigationItem setRightBarButtonItem:dismissKeyboardButton animated:YES];
}

- (UILabel *)titleView
{
    return (UILabel *)self.navigationItem.titleView;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    self.titleView.text = title;
}

- (NSString *)title
{
    return [super title];
}

- (void)updateTitle:(NSString *)title animated:(BOOL)animated
{
    if (title) {
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        UILabel *titleView = self.titleView;
        if ([title isEqualToString:@""]) {
            title = noteEmptyTitle;
        }
        if (![title isEqualToString:titleView.text]) {
            if (animated) {
                UILabel *cloneTitleView = [[UILabel alloc] initWithFrame:titleView.frame];
                cloneTitleView.backgroundColor = titleView.backgroundColor;
                cloneTitleView.font = titleView.font;
                cloneTitleView.textAlignment = titleView.textAlignment;
                cloneTitleView.textColor = titleView.textColor;
                cloneTitleView.text = titleView.text;
                cloneTitleView.center = titleView.center;
                [titleView.superview addSubview:cloneTitleView];
                titleView.alpha = 0.0f;
                self.title = title;
                [titleView sizeToFit];

                [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
                    cloneTitleView.alpha = 0.0f;
                    titleView.alpha = 1.0f;
                } completion:^(BOOL finished) {
                    [cloneTitleView removeFromSuperview];
                }];
            } else {
                self.title = title;
                [titleView sizeToFit];
            }
        }
    }
}

- (void)updateTitleStyle
{
//    if (_isDirty || !_note.userSaved) {
//        [self.titleView setFont:[BEUI.theme fontForKey:@[@"NoteNavigationBar.UnsavedTitle", @"NavigationBar.Title"] withSubkey:@"Font"]];
//    } else {
//        [self.titleView setFont:[BEUI.theme fontForKey:@"NavigationBar.Title.Font"]];
//    }
//    [self.titleView sizeToFit];
}

- (void)updateToolbarButtonsAnimated:(BOOL)animated
{
    NSArray *items = nil;
    if (_note.archived) {
        items = @[//keepButton,
                  [UIBarButtonItem spacer],
                  copyButton,
                  [UIBarButtonItem spacer],
                  unarchiveButton,
                  [UIBarButtonItem spacer],
                  discardButton,
                  [UIBarButtonItem spacer]];
    } else {
        items = @[//keepButton,
                  [UIBarButtonItem spacer],
                  copyButton,
                  [UIBarButtonItem spacer],
                  archiveButton,
                  [UIBarButtonItem spacer],
                  discardButton,
                  [UIBarButtonItem spacer]];
    }

    [toolbar setItems:items animated:animated];
}

- (void)setIsDirty:(BOOL)isDirty
{
    _isDirty = isDirty;
    [self updateTitleStyle];
}

- (void)touchableViewOnTouch:(BETouchableView *)view
{
    [self dismissKeyboard];

    BENoteImageController *noteImageController = [[BENoteImageController alloc] init];
    [noteImageController view];
    noteImageController.note = _note;

    if (!CGRectEqualToRect(_note.croppedImageFrame, CGRectZero)) {
        CGRect frame = noteImageController.scrollContentFrame;

        // UIImageView *imageView = [[UIImageView alloc] initWithImage:_note.rawImage];
        UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _note.rawImage.size.width, _note.rawImage.size.height)];
        UIView *cropViewContainer = [[UIView alloc] initWithFrame:frame];

        UIImageView *cropView = [[UIImageView alloc] initWithImage:_note.croppedImage];
        cropView.frame = CGRectOffset(_note.croppedImageFrame, frame.size.width / 2.0f, frame.size.height / 2.0f);

        UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cropView.frame.size.width, cropView.frame.size.height)];
        borderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        borderView.alpha = 0.0f;
        borderView.layer.borderColor = [UIColor whiteColor].CGColor;
        borderView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;

        [cropView addSubview:borderView];
        [cropViewContainer addSubview:cropView];

        cropViewContainer.transform = CGAffineTransformInvert(_note.croppedImageTransform);
        cropViewContainer.center = CGPointMake(imageView.bounds.size.width / 2.0f, imageView.bounds.size.height / 2.0f);
        [imageView addSubview:cropViewContainer];

        CGFloat scale = _imageView.frame.size.height / cropView.frame.size.height;
        imageView.transform = CGAffineTransformScale(_note.croppedImageTransform, scale, scale);
        [self.navigationController.view addSubview:imageView];

        CGPoint desiredCenter = [self.navigationController.view convertPoint:_imageView.center fromView:scrollView];
        CGPoint actualCenter = [self.navigationController.view convertPoint:cropView.center fromView:cropViewContainer];
        CGPoint offset = CGPointMake(desiredCenter.x - actualCenter.x, desiredCenter.y - actualCenter.y);

        imageView.center = CGPointMake(imageView.center.x + offset.x, imageView.center.y + offset.y);

        UIView *selfImageView = _imageView;
        selfImageView.hidden = YES;
        NSObject<UINavigationControllerDelegate> *navigationControllerDelegate = self.navigationController.delegate;
        UINavigationController *navigationController = self.navigationController;
        navigationControllerPushCompletion = ^(BOOL finished) {
            selfImageView.hidden = NO;
            noteImageController.cropView.hidden = NO;
            noteImageController.spotlightView.hidden = NO;
            [imageView removeFromSuperview];
            navigationController.delegate = navigationControllerDelegate;
        };

        noteImageController.cropView.hidden = YES;
        noteImageController.spotlightView.hidden = YES;
        CGFloat zoomScale = noteImageController.scrollView.zoomScale;
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, zoomScale, zoomScale);
            imageView.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
            borderView.alpha = 1.0f;
        }];
        self.navigationController.delegate = self;
    }

    [self.navigationController pushViewController:noteImageController animated:YES];
}

- (void)setNote:(BENote *)note
{
    _note = note;
    if ([self isViewLoaded]) {
        CGRect imageViewFrame = [self frameForImage:_note.croppedImage inFrame:scrollView.frame];
        _imageView.frame = imageViewFrame;
        _imageViewBackground.frame = imageViewFrame;
        _scannerView.frame = imageViewFrame;
        touchableView.frame = imageViewFrame;

        _imageView.image = _note.croppedImage;
        if (_note.postOcrText) {
            [self updateTitle:_note.text.firstLine animated:NO];
        }
        [self updateTitleStyle];
        [self updateText:_note.text];

        if(_imageView.image) {
            _imageView.hidden = NO;
        }

        plusButton.enabled = _note.hasDataTypes;
        copyButton.enabled = YES;
        archiveButton.enabled = YES;
        unarchiveButton.enabled = YES;
        discardButton.enabled = YES;

        [self updateToolbarButtonsAnimated:NO];
    }
}

- (CGFloat)viewableHeight
{
    return scrollView.frame.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom;
}

- (BOOL)isImageLetterboxed:(UIImage *)image inFrame:(CGRect)frame
{
    if(image) {
        CGFloat width = frame.size.width;
        CGFloat height = floor(([UIScreen mainScreen].bounds.size.height - 64.0f - toolbarHeight) / 2.0f);
        return (image.size.width / image.size.height) < (width / height);
    } else {
        return YES;
    }
}

- (CGRect)frameForImage:(UIImage *)image inFrame:(CGRect)frame
{
    CGFloat width = frame.size.width;
    if(!image || [self isImageLetterboxed:image inFrame:frame]) {
        CGFloat imageHeight = floor(([UIScreen mainScreen].bounds.size.height - 64.0f - toolbarHeight) / 2.0f);
        return [UIView alignRect:CGRectMake(frame.origin.x, frame.origin.y, width, imageHeight)];
    } else {
        CGFloat imageHeight = width * (image.size.height / image.size.width);
        return [UIView alignRect:CGRectMake(frame.origin.x, frame.origin.y, width, imageHeight)];
    }
}

- (CGRect)frameForTextView
{
    CGFloat width = scrollView.frame.size.width;
    CGFloat height = self.viewableHeight;
    CGFloat xInsets = 10.0f + textView.contentInset.left + textView.contentInset.right;
    CGFloat yInsets = textView.contentInset.top + textView.contentInset.bottom;
    CGFloat textViewHeight = 0.0f;
    NSString *text = [NSString stringWithFormat:@".%@.", textView.text];
    if ([NSString instancesRespondToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        xInsets += textView.textContainerInset.left + textView.textContainerInset.right;
        yInsets += textView.textContainerInset.top + textView.textContainerInset.bottom;
        CGRect textFrame = [text boundingRectWithSize:CGSizeMake(width - xInsets, FLT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{UITextAttributeFont: textView.font,
                                                        UITextAttributeTextColor: textView.textColor}
                                              context:nil];
        textViewHeight = ceil(textFrame.origin.y + textFrame.size.height + yInsets);

    } else {
        yInsets += 16.0f;
        CGSize textSize = [text sizeWithFont:textView.font
                           constrainedToSize:CGSizeMake(width - xInsets, FLT_MAX)
                               lineBreakMode:NSLineBreakByWordWrapping];
        textViewHeight = ceil(textSize.height + yInsets);
    }
    textViewHeight = MAX(textViewHeight, height - _imageView.frame.size.height);
    return [UIView alignRect:CGRectMake(0, _imageView.frame.origin.y + _imageView.frame.size.height, width, textViewHeight)];
}

- (void)ocr:(BENote *)value
{
    self.note = value;
    copyButton.enabled = NO;
    archiveButton.enabled = NO;
    unarchiveButton.enabled = NO;
    discardButton.enabled = NO;
    self.isDirty = YES;
    [_scannerView show:NO];

    BEOcr *ocr = [[BEOcr alloc] init];
    [ocr preOcr:_note.croppedImage completion:^(UIImage *preOcrImage) {
        // NSLog(@"PRE OCR");
        
        _note.preOcrImage = preOcrImage;
        _note.preOcrImageTimestamp = [NSDate date];

        [ocr ocr:_note.preOcrImage completion:^(NSString *ocrText, UIImage *ocrImage, NSString* hocrText) {
            // NSLog(@"OCR");

            _note.ocrImage = ocrImage;
            _note.ocrImageTimestamp = [NSDate date];

            _note.ocrText = ocrText;
            _note.ocrTextTimestamp = [NSDate date];

            _note.hocrText = hocrText;
            _note.hocrTextTimestamp = [NSDate date];

            [ocr postOcr:ocrText completion:^(NSString *postOcrText) {
                // NSLog(@"POST OCR");

                _note.postOcrText = postOcrText;
                _note.postOcrTextTimestamp = [NSDate date];

                [BEThread background:^{
                    [_note dataTypes];

                    _note.thumbnailImage = [BENote createThumbnail:_note.croppedImage];
                    _note.thumbnailImageTimestamp = [NSDate date];
                    
//                    if (![NSString isEmpty:_note.text]) {
//                        [BENote replaceMostRecentDrafts:_note];
//                    }
                    if([BEDB save:_note]) {
                        self.isDirty = NO;
                    }

                    [BEThread main:^{
                        [self updateText:_note.text];
                        [self updateTitle:_note.text.firstLine animated:YES];
                        plusButton.enabled = _note.hasDataTypes;
                        copyButton.enabled = YES;
                        archiveButton.enabled = YES;
                        unarchiveButton.enabled = YES;
                        discardButton.enabled = YES;
                        [_scannerView hide:YES completion:^(BOOL finished) {

                        }];
                    }];
                }];
            }];
        }];
    }];
}

- (void)onDismissKeyboardButtonTouch
{
    [self updateTitle:_note.text.firstLine animated:YES];
    if (self.isDirty && _note.userText) {
        _note.userSaved = YES;
        if([BEDB save:_note]) {
            self.isDirty = NO;
        }
    }
    [self dismissKeyboard];
}

- (void)onPlusButtonTouch
{
    [self showNoteSheet];
}

- (void)showNoteSheet
{
    if(!self.popover) {
        BENoteSheetController *viewController = [[BENoteSheetController alloc] init];
        viewController.delegate = self;
        viewController.note = self.note;
        self.popover = [[BEPopoverController alloc] initWithContentViewController:viewController];
        self.popover.parentView = self.view;
        self.popover.popoverBackgroundViewClass = [BEPopoverBackgroundView class];
        self.popover.popoverLayoutMargins = noteSheetPopoverLayoutMargins;
        self.popover.contentViewInsets = noteSheetPopoverContentViewInsets;
        self.popover.maskAlpha = noteSheetPopoverMaskAlpha;
        self.popover.shadowColor = [BEUI.theme colorForKey:@"NoteSheetPopover.ShadowColor"];
        self.popover.delegate = self;

        CGFloat arrowHeight = [BEPopoverBackgroundView arrowHeight];
        CGRect buttonFrame = plusButton.internalView.frame;
        buttonFrame = [self.navigationController.view convertRect:buttonFrame fromView:self.navigationController.navigationBar];
        buttonFrame.size.height = buttonFrame.size.height - (arrowHeight - self.popover.popoverLayoutMargins.top);

        [self.popover presentPopoverFromRect:buttonFrame
                                      inView:self.navigationController.view
                    permittedArrowDirections:UIPopoverArrowDirectionUp
                                    animated:YES];
        self.popover.backgroundView.clipsToBounds = noteSheetPopoverBackgroundClipsToBounds;

    }
}

- (void)dismissKeyboard
{
    [textView resignFirstResponder];
}

- (void)dismissPopover
{
    [self dismissPopover:YES];
}

- (void)dismissPopover:(BOOL)animated
{
    if(self.popover) {
        [self.popover dismissPopoverAnimated:animated];
        if ([self.popover.contentViewController respondsToSelector:@selector(delegate)]) {
            ((BENoteSheetController *)self.popover.contentViewController).delegate = nil;
        }
        self.popover.delegate = nil;
        self.popover = nil;
    }
}

- (void)updateText:(NSString *)text
{
    textView.hidden = YES;
    textView.text = text;
    [self layoutTextView];
    [self showTextView:YES];
}

- (void)showTextView:(BOOL)animated
{
    [self showTextView:animated completion:nil];
}

- (void)showTextView:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
    if(animated) {
        textView.alpha = 0.0f;
        textView.hidden = NO;
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                         animations:^{ textView.alpha = 1.0f; }
                         completion:completion];
    } else {
        textView.alpha = 1.0f;
        textView.hidden = NO;
        if(completion) {
            completion(YES);
        }
    }
}

- (void)popoverControllerDidDismissPopover:(BEPopoverController *)popoverController
{
    self.popover = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(BEPopoverController *)popoverController
{
    return YES;
}

- (void)textViewDidChange:(UITextView *)view
{
    _note.userText = textView.text;
    _note.userTextTimestamp = [NSDate date];
    if (!self.isDirty) {
        self.isDirty = YES;
    }
    [self layoutTextView];
}

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{

}

- (void)onKeepButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    _note.userSaved = YES;
    [BEDB save:_note];
    self.isDirty = NO;
}

- (void)onCopyButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (!_note) {
        return;
    }
    [UIPasteboard generalPasteboard].string = textView.text;
}

- (void)onArchiveButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (!_note) {
        return;
    }
    alert = [[BEAlertView alloc] initWithFrame:self.view.bounds];
    alert.maskAlpha = [BEUI.theme floatForKey:@"NoteArchiveAlert.MaskAlpha"];
    alert.shadowColor = [BEUI.theme colorForKey:@"NoteArchiveAlert.ShadowColor"];
    alert.size = noteDiscardAlertSize;

    UIButton *confirmButton = [BEUI buttonWithKey:@[@"NoteArchiveAlertArchiveButton", @"AlertButton"] target:self action:@selector(onAlertArchiveButtonTouch:event:)];
    UIButton *cancelButton = [BEUI buttonWithKey:@[@"AlertCancelButton", @"AlertButton"] target:self action:@selector(onAlertCancelButtonTouch:event:)];

    alert.buttons = @[confirmButton, cancelButton];

    [self.navigationController.view addSubview:alert];
    [alert show:nil completion:nil];
}

- (void)onUnarchiveButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (!_note) {
        return;
    }
    _note.archived = NO;
    _note.userSaved = YES;
    if([BEDB save:_note]) {
        self.isDirty = NO;
        [self updateToolbarButtonsAnimated:YES];
    }
}

- (void)onDiscardButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (!_note) {
        return;
    }
    alert = [[BEAlertView alloc] initWithFrame:self.view.bounds];
    alert.maskAlpha = [BEUI.theme floatForKey:@"NoteDiscardAlert.MaskAlpha"];
    alert.shadowColor = [BEUI.theme colorForKey:@"NoteDiscardAlert.ShadowColor"];
    alert.size = noteDiscardAlertSize;

    UIButton *confirmButton = [BEUI buttonWithKey:@[@"NoteDiscardAlertDiscardButton", @"AlertWarningButton", @"AlertButton"] target:self action:@selector(onAlertDiscardButtonTouch:event:)];
    UIButton *cancelButton = [BEUI buttonWithKey:@[@"AlertCancelButton", @"AlertButton"] target:self action:@selector(onAlertCancelButtonTouch:event:)];

    alert.buttons = @[confirmButton, cancelButton];

    [self.navigationController.view addSubview:alert];
    [alert show:nil completion:nil];
}

- (void)onAlertArchiveButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [alert hide:nil completion:^(BOOL finished) {
        [alert removeFromSuperview];
        alert = nil;
    }];

    _note.archived = YES;
    _note.userSaved = YES;
    [BEDB save:_note];
    self.isDirty = NO;
    if([BEDB save:_note]) {
        [self popToRoot];
    }
}

- (void)onAlertDiscardButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [alert hide:nil completion:^(BOOL finished) {
        [alert removeFromSuperview];
        alert = nil;
    }];
    if ([BEDB remove:_note]) {
        [self popToRoot];
    }
}

- (void)onAlertCancelButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [alert hide:nil completion:^(BOOL finished) {
        [alert removeFromSuperview];
        alert = nil;
    }];
}

- (void)noteSheet:(BENoteSheetController *)controller contact:(BENote *)note
{
    ABRecordRef person = [note createPerson];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
      phoneNumber:(NSString *)phoneNumber
{
    ABRecordRef person = [BETextData createPersonWithDataTypes:@{@"PhoneNumber": @[@[text, phoneNumber]]}];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
              url:(NSURL *)url
{
    ABRecordRef person = [BETextData createPersonWithDataTypes:@{@"URL": @[@[text, url]]}];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
            email:(NSURL *)email
{
    ABRecordRef person = [BETextData createPersonWithDataTypes:@{@"Email": @[@[text, email]]}];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
          address:(NSDictionary *)components
{
    ABRecordRef person = [BETextData createPersonWithDataTypes:@{@"Address": @[@[text, components]]}];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
         calendar:(BENote *)note
             text:(NSString *)text
             date:(NSDate *)date
         duration:(NSTimeInterval)duration
         timeZone:(NSTimeZone *)timeZone
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if(granted) {
            EKEvent *event = [EKEvent eventWithEventStore:eventStore];
            event.startDate = date;
            event.timeZone = timeZone;
            if(duration) {
                event.endDate = [date dateByAddingTimeInterval:duration];
            } else {
                event.endDate = [date dateByAddingTimeInterval:3600.0];
            }
            NSString *title = note.text.firstLine;
            if(![title isEqualToString:text]) {
                event.title = title;
            }
            event.notes = [NSString stringWithFormat:@"%@\n\n%@", [BEUI.theme stringForKey:@"CreateContactNote"], note.text];

            [self performSelectorOnMainThread:@selector(showCalendar:) withObject:@[event, eventStore] waitUntilDone:NO];
        }
    }];
}

- (void)showContact:(ABRecordRef)person
{
    ABUnknownPersonViewController *controller = [[ABUnknownPersonViewController alloc] init];
    controller.allowsActions = YES;
    controller.allowsAddingToAddressBook = YES;
    controller.displayedPerson = person;
    controller.unknownPersonViewDelegate = self;

    CFRelease(person);

    if (!UIDevice.isIOS7) {
        UIScrollView *view = controller.topScrollView;
        if (view) {
            UIEdgeInsets insets = [self insetsForViewStatusBarHidden:YES];
            view.contentInset = insets;
            view.scrollIndicatorInsets = insets;
        }
    }

    @synchronized(self) {
        [self.navigationController pushViewController:controller animated:YES];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.popover.view.alpha = 0.0f;
        }];
    }
}

- (void)showCalendar:(NSArray *)args
{
    EKEvent *event = args[0];
    EKEventStore *eventStore = args[1];

    EKEventEditViewController* controller = [[EKEventEditViewController alloc] init];
    controller.editViewDelegate = self;
    controller.event = event;
    controller.eventStore = eventStore;

    @synchronized(self) {
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    @synchronized(self) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    }
}

- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller
{
    return controller.eventStore.defaultCalendarForNewEvents;
}

@end
