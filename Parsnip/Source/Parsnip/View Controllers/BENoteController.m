//
//  BENoteController.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BENoteController.h"

#import <QuartzCore/QuartzCore.h>
#import "NSString+Tools.h"
#import "BEAlertView.h"
#import "BEDB.h"
#import "BEInAppPurchaser.h"
#import "BENoteImageController.h"
#import "BENoteSheetController.h"
#import "BENotificationView.h"
#import "BEScanner.h"
#import "BEPopoverBackgroundView.h"
#import "BEPopoverController.h"
#import "BETextData.h"
#import "BETextDataDetector.h"
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
    UIBarButtonItem *copyButton;
    UIBarButtonItem *archiveButton;
    UIBarButtonItem *unarchiveButton;
    UIBarButtonItem *deleteButton;
    UIToolbar *toolbar;

    UIBarButtonItem *dismissKeyboardButton;
    UIBarButtonItem *plusButton;
    BEAlertView *deleteAlert;
    BEAlertView *archiveAlert;
    UITextView *textView;
    BETouchableView *touchableView;
    BOOL initialAppearance;

    NSArray *_products;

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

    textView = [[UITextView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - toolbarHeight)];
    textView.alwaysBounceHorizontal = NO;
    textView.alwaysBounceVertical = YES;
    textView.bounces = YES;
    textView.clipsToBounds = YES;

    textView.font = [BEUI.theme fontForKey:@"Note.Font"];
    textView.textColor = [BEUI.theme colorForKey:@"Note.TextColor"];
    textView.backgroundColor = [BEUI.theme colorForKey:@"Note.BackgroundColor"];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.delegate = self;

    dismissKeyboardButton = [BEUI barButtonItemWithKey:@[@"NavigationBarDismissKeyboardButton", @"NavigationBarButton"] target:self action:@selector(onDismissKeyboardButtonTouch)];
    plusButton = [BEUI barButtonItemWithKey:@[@"NavigationBarPlusButton", @"NavigationBarButton"] target:self action:@selector(onPlusButtonTouch)];
    plusButton.enabled = NO;
    [self setRightBarButtonItem:plusButton animated:NO];

    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.navigationItem.titleView = [BEUI styleNavigationBarTitleView:titleView];
    [self setTitle:self.title];

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

    copyButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarCopyButton", @"NoteToolbarButton"] target:self action:@selector(onCopyButtonTouch:event:)];
    archiveButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarArchiveButton", @"NoteToolbarButton"] target:self action:@selector(onArchiveButtonTouch:event:)];
    unarchiveButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarUnarchiveButton", @"NoteToolbarButton"] target:self action:@selector(onUnarchiveButtonTouch:event:)];
    deleteButton = [BEUI barButtonItemWithKey:@[@"NoteToolbarDeleteButton", @"NoteToolbarButton"] target:self action:@selector(onDeleteButtonTouch:event:)];

    BOOL hasNote = !!_note;
    copyButton.enabled = hasNote;
    archiveButton.enabled = hasNote;
    unarchiveButton.enabled = hasNote;
    deleteButton.enabled = hasNote;

    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(toolbarMargin.left,
                                                          frame.size.height - toolbarHeight + toolbarMargin.top,
                                                          frame.size.width - (toolbarMargin.left + toolbarMargin.right),
                                                          toolbarHeight - (toolbarMargin.top + toolbarMargin.bottom))];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [toolbar setBackgroundImage:[BEUI.theme imageForKey:@"NoteToolbar.BackgroundImage"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [toolbar setShadowImage:[BEUI.theme imageForKey:@"NoteToolbar.ShadowImage"] forToolbarPosition:UIToolbarPositionAny];

    [self updateToolbarButtonsAnimated:NO];

    [textView addSubview:_imageViewBackground];
    [textView addSubview:_imageView];
    [textView addSubview:touchableView];
    [textView addSubview:_scannerView];
    [self.view addSubview:textView];
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

    [self layoutSubviews];

    if (initialAppearance) {
        initialAppearance = NO;
        UIEdgeInsets insets = self.insetsForView;
        insets.top += _imageView.frame.size.height;
        textView.contentOffset = CGPointMake(0.0f - insets.left, 0.0f - insets.top);
    }

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
    UIEdgeInsets insets = self.insetsForView;
    textView.scrollIndicatorInsets = insets;
    insets.top += _imageView.frame.size.height;
    textView.contentInset = insets;

    if (_note) {
        CGRect frame = [self boundsForViewStatusBarHidden:YES];
        frame.size.height -= toolbarHeight;
        [self layoutForImage:_note.croppedImage inFrame:frame];
    }
}

- (void)layoutForImage:(UIImage *)image inFrame:(CGRect)frame
{
    CGRect imageViewFrame = [self frameForImage:image inFrame:frame];
    imageViewFrame.origin.y -= imageViewFrame.size.height;
    _imageView.frame = imageViewFrame;
    _imageViewBackground.frame = imageViewFrame;
    _scannerView.frame = imageViewFrame;
    touchableView.frame = imageViewFrame;
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
    frame.size.height -= MAX(keyboardHeight, toolbarHeight);
    textView.frame = frame;
}

- (void)onKeyboardWillHide:(NSNotification *)notification
{
    [self setRightBarButtonItem:plusButton animated:YES];

    CGRect frame = self.view.bounds;
    frame.size.height -= toolbarHeight;
    textView.frame = frame;

    touchableView.userInteractionEnabled = YES;
}

- (void)onKeyboardWillShow:(NSNotification *)notification
{
    touchableView.userInteractionEnabled = NO;
    [self setRightBarButtonItem:dismissKeyboardButton animated:YES];
}

- (UILabel *)titleView
{
    return (UILabel *)self.navigationItem.titleView;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    self.titleView.text = title;
    [self.titleView sizeToFit];
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

                [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
                    cloneTitleView.alpha = 0.0f;
                    titleView.alpha = 1.0f;
                } completion:^(BOOL finished) {
                    [cloneTitleView removeFromSuperview];
                }];
            } else {
                self.title = title;
            }
        }
    }
}

- (void)updateToolbarButtonsAnimated:(BOOL)animated
{
    NSArray *items = nil;
    if (_note.archived) {
        items = @[[UIBarButtonItem spacer],
                  copyButton,
                  [UIBarButtonItem spacer],
                  unarchiveButton,
                  [UIBarButtonItem spacer],
                  deleteButton,
                  [UIBarButtonItem spacer]];
    } else {
        items = @[[UIBarButtonItem spacer],
                  copyButton,
                  [UIBarButtonItem spacer],
                  archiveButton,
                  [UIBarButtonItem spacer],
                  deleteButton,
                  [UIBarButtonItem spacer]];
    }

    [toolbar setItems:items animated:animated];
}

- (void)setIsDirty:(BOOL)isDirty
{
    _isDirty = isDirty;
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

        CGPoint desiredCenter = [self.navigationController.view convertPoint:_imageView.center fromView:textView];
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
        _imageView.image = _note.croppedImage;
        if (_note.postOcrTextTimestamp || _note.codeScanTimestamp) {
            [self updateTitle:_note.firstNonDataTypeLine animated:NO];
        }
        [self updateText:_note.text];
        [self layoutSubviews];

        if(_imageView.image) {
            _imageView.hidden = NO;
        }

        plusButton.enabled = YES;
        copyButton.enabled = YES;
        archiveButton.enabled = YES;
        unarchiveButton.enabled = YES;
        deleteButton.enabled = YES;

        [self updateToolbarButtonsAnimated:NO];
    }
}

- (CGFloat)viewableHeight
{
    return textView.frame.size.height - textView.contentInset.top - textView.contentInset.bottom;
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

- (void)scan:(BENote *)value
{
    self.note = value;
    plusButton.enabled = NO;
    copyButton.enabled = NO;
    archiveButton.enabled = NO;
    unarchiveButton.enabled = NO;
    deleteButton.enabled = NO;
    self.isDirty = YES;
    [_scannerView show:NO];

    void (^scanCompleted)() = ^()
    {
        [_note dataTypes];

        _note.thumbnailImage = [BENote createThumbnail:_note.croppedImage];
        _note.thumbnailImageTimestamp = [NSDate date];

        if([BEDB save:_note]) {
            self.isDirty = NO;
        }

        [BEThread main:^{
            [self updateText:_note.text];
            [self updateTitle:_note.firstNonDataTypeLine animated:YES];
            plusButton.enabled = YES;
            copyButton.enabled = YES;
            archiveButton.enabled = YES;
            unarchiveButton.enabled = YES;
            deleteButton.enabled = YES;
            [_scannerView hide:YES completion:^(BOOL finished) {

            }];
        }];
    };

    BEScanner *scanner = [[BEScanner alloc] init];
    [scanner codeScan:_note.croppedImage completion:^(NSArray *codeScanData) {
        // NSLog(@"CODE SCAN");
        _note.codeScanTimestamp = [NSDate date];
        if (codeScanData && codeScanData.count) {
            _note.codeScanData = codeScanData;
            NSMutableArray *lines = [NSMutableArray arrayWithCapacity:codeScanData.count];
            for (NSDictionary *data in codeScanData) {
                [lines addObject:[data[@"Data"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
            _note.codeScanText = [lines componentsJoinedByString:@"\n\n"];
            scanCompleted();
        } else {
            [scanner preOcr:_note.croppedImage completion:^(UIImage *preOcrImage) {
                // NSLog(@"PRE OCR");

                _note.preOcrImage = preOcrImage;
                _note.preOcrImageTimestamp = [NSDate date];

                [scanner ocr:_note.preOcrImage completion:^(NSString *ocrText, UIImage *ocrImage, NSString* hocrText) {
                    // NSLog(@"OCR");

                    _note.ocrImage = ocrImage;
                    _note.ocrImageTimestamp = [NSDate date];

                    _note.ocrText = ocrText;
                    _note.ocrTextTimestamp = [NSDate date];

                    _note.hocrText = hocrText;
                    _note.hocrTextTimestamp = [NSDate date];

                    [scanner postOcr:ocrText completion:^(NSString *postOcrText) {
                        // NSLog(@"POST OCR");

                        _note.postOcrText = postOcrText;
                        _note.postOcrTextTimestamp = [NSDate date];
                        
                        [BEThread background:^{
                            scanCompleted();
                        }];
                    }];
                }];
            }];
        }
    }];
}

- (void)onDismissKeyboardButtonTouch
{
    [self updateTitle:_note.firstNonDataTypeLine animated:YES];
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
    textView.text = text;
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
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            if (!_note) {
                return;
            }
            [UIPasteboard generalPasteboard].string = textView.text;

            [BENotificationView notify:@"Text Copied"];
        }
    }];
}

- (void)onArchiveButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (!_note) {
        return;
    }
    archiveAlert = [[BEAlertView alloc] initWithFrame:self.navigationController.view.bounds];
    archiveAlert.maskAlpha = [BEUI.theme floatForKey:@"Alert.MaskAlpha"];
    archiveAlert.buttons = @[[BEUI.theme stringForKey:@"NoteArchiveAlertArchiveButton"]];
    archiveAlert.delegate = self;

    [self.navigationController.view addSubview:archiveAlert];
    [archiveAlert show:nil completion:nil];
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

- (void)onDeleteButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (!_note) {
        return;
    }
    deleteAlert = [[BEAlertView alloc] initWithFrame:self.navigationController.view.bounds];
    deleteAlert.maskAlpha = [BEUI.theme floatForKey:@"Alert.MaskAlpha"];
    deleteAlert.buttons = @[[BEUI.theme stringForKey:@"NoteDeleteAlertDeleteButton"]];
    deleteAlert.delegate = self;

    [self.navigationController.view addSubview:deleteAlert];
    [deleteAlert show:nil completion:nil];
}

- (void)onAlertArchiveButtonTouch
{
    [archiveAlert dismissAnimated:YES];

    _note.archived = YES;
    _note.userSaved = YES;
    [BEDB save:_note];
    self.isDirty = NO;
    if([BEDB save:_note]) {
        [self popToRoot];
    }
}

- (void)onAlertDeleteButtonTouch
{
    [deleteAlert dismissAnimated:YES];

    if ([BEDB remove:_note]) {
        [self popToRoot];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((BEAlertView *)alertView == deleteAlert) {
        if (buttonIndex == 0) {
            [self onAlertDeleteButtonTouch];
        }
    } else if((BEAlertView *)alertView == archiveAlert) {
        if (buttonIndex == 0) {
            [self onAlertArchiveButtonTouch];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ((BEAlertView *)alertView == deleteAlert) {
        deleteAlert = nil;
    } else if((BEAlertView *)alertView == archiveAlert) {
        archiveAlert = nil;
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{

}

- (void)alertViewCancel:(UIAlertView *)alertView
{

}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    return YES;
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{

}

- (void)willPresentAlertView:(UIAlertView *)alertView
{

}

- (void)noteSheet:(BENoteSheetController *)controller contact:(BENote *)note
{
    ABRecordRef person = [note createPerson];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
            vCard:(NSString *)vCard
{
    CFDataRef vCardData = (__bridge CFDataRef)[vCard dataUsingEncoding:NSUTF8StringEncoding];
    CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vCardData);
    ABRecordRef person = CFRetain(CFArrayGetValueAtIndex(vCardPeople, 0));
    CFRelease(vCardPeople);
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
         textData:(BETextData *)textData
{
    ABRecordRef person = [BETextDataDetector createPersonWithDataTypes:@{textData.dataType: @[textData]}];
    [self performSelectorOnMainThread:@selector(showContact:) withObject:(__bridge id)person waitUntilDone:NO];
}

- (void)noteSheet:(BENoteSheetController *)controller
         calendar:(BENote *)note
         textData:(BETextData *)textData
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if(granted) {
            NSDate *date = textData.components[0];
            NSTimeInterval duration = [textData.components[1] doubleValue];
            NSTimeZone *timeZone = textData.components[2];

            EKEvent *event = [EKEvent eventWithEventStore:eventStore];
            event.startDate = date;
            event.timeZone = timeZone;
            if(duration) {
                event.endDate = [date dateByAddingTimeInterval:duration];
            } else {
                event.endDate = [date dateByAddingTimeInterval:3600.0];
            }
            NSString *title = note.firstNonDataTypeLine;
            if(![title isEqualToString:textData.matchedText]) {
                event.title = title;
            }
            event.notes = [NSString stringWithFormat:@"%@\n\n%@", [BEUI.theme stringForKey:@"CreateContactNoteText"], note.text];

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
