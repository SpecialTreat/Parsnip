#import "BEUI.h"

#import "BEAlertView.h"
#import "BEDialogView.h"
#import "BEPopoverBackgroundView.h"
#import "BEThread.h"
#import "UIColor+Tools.h"
#import "UIDevice+Tools.h"
#import "UIImage+Drawing.h"
#import "VSThemeLoader.h"


@implementation BEUI

static VSThemeLoader *themeLoader;
static VSTheme *theme;

static BOOL GLOBAL_DEBUG;

static BOOL navigationBarTranslucent;
static BOOL navigationBarClipsToBounds;

static UIBarStyle themeNavigationBarStyle;
static UIStatusBarStyle themeStatusBarStyle;

+ (void)initialize
{
    themeLoader = [[VSThemeLoader alloc] init];

    if (UIDevice.isIOS7) {
        theme = themeLoader.defaultTheme;
    } else {
        theme = [themeLoader themeNamed:@"iOS6"];
    }
    if (UIDevice.isIpad) {
        VSTheme *ipadTheme = [themeLoader themeNamed:@"iPad"];
        ipadTheme.parentTheme = theme;
        theme = ipadTheme;
    }

    GLOBAL_DEBUG = [theme boolForKey:@"Debug" withDefault:NO];

    navigationBarTranslucent = [theme boolForKey:@"NavigationBar.Translucent" withDefault:YES];
    navigationBarClipsToBounds = [theme boolForKey:@"NavigationBar.ClipsToBounds" withDefault:NO];

    NSString *navigationBarStyle = [theme stringForKey:@"NavigationBar.BarStyle"];
    if ([@"BlackOpaque" isEqualToString:navigationBarStyle]) {
        themeNavigationBarStyle = UIBarStyleBlackOpaque;
    } else if ([@"BlackTranslucent" isEqualToString:navigationBarStyle]) {
        themeNavigationBarStyle = UIBarStyleBlackTranslucent;
    } else if ([@"Black" isEqualToString:navigationBarStyle]) {
        themeNavigationBarStyle = UIBarStyleBlack;
    } else {
        themeNavigationBarStyle = UIBarStyleDefault;
    }

    NSString *statusBarStyle = [theme stringForKey:@"StatusBarStyle"];
    if ([@"BlackOpaque" isEqualToString:statusBarStyle]) {
        themeStatusBarStyle = UIStatusBarStyleBlackOpaque;
    } else if ([@"BlackTranslucent" isEqualToString:statusBarStyle]) {
        themeStatusBarStyle = UIStatusBarStyleBlackTranslucent;
    } else if ([@"LightContent" isEqualToString:statusBarStyle]) {
        themeStatusBarStyle = UIStatusBarStyleLightContent;
    } else {
        themeStatusBarStyle = UIStatusBarStyleDefault;
    }
}

+ (BOOL)debug
{
    return GLOBAL_DEBUG;
}

+ (VSTheme *)theme
{
    return theme;
}

+ (BOOL)isStatusBarTranslucent
{
    return (UIDevice.isIOS7 || [BEUI preferredStatusBarStyle] == UIStatusBarStyleBlackTranslucent);
}

+ (UIStatusBarStyle)preferredStatusBarStyle
{
    return themeStatusBarStyle;
}

+ (UIBarStyle)preferredNavigationBarStyle
{
    return themeNavigationBarStyle;
}

+ (void)styleApp:(BEAppDelegate *)app
{
    if ([app.window respondsToSelector:@selector(setTintColor:)]) {
        app.window.tintColor = [theme colorForKey:@"TintColor"];
    }
    [BEUI styleStatusBar];
    [BEUI styleNavigationBarAppearance];
    [BEUI styleAlertView];
    [BEUI styleDialogView];
    [BEUI stylePopoverBackgroundView];
}

+ (void)styleNavigationBarAppearance
{
    [[UINavigationBar appearance] setTitleTextAttributes:@{
        UITextAttributeFont: [theme fontForKey:@"NavigationBar.Title.Font"],
        UITextAttributeTextColor: [theme colorForKey:@"NavigationBar.Title.TextColor" withDefault:[UIColor blackColor]],
        UITextAttributeTextShadowColor: [theme colorForKey:@"NavigationBar.Title.TextShadowColor" withDefault:[UIColor clearColor]],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:[theme offsetForKey:@"NavigationBar.Title.TextShadowOffset" withDefault:UIOffsetZero]]
    }];
    [[UINavigationBar appearance] setBarStyle:[BEUI preferredNavigationBarStyle]];
    [[UINavigationBar appearance] setTintColor:[theme colorForKey:@"NavigationBar.TintColor" withDefault:nil]];
    [[UINavigationBar appearance] setBackgroundImage:[theme imageForKey:@"NavigationBar.BackgroundImage"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:[theme imageForKey:@"NavigationBar.LandscapeBackgroundImage"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setShadowImage:[theme imageForKey:@"NavigationBar.ShadowImage"]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:[theme floatForKey:@"NavigationBar.Title.VerticalOffset"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:[theme floatForKey:@"NavigationBar.Title.LandscapeVerticalOffset"] forBarMetrics:UIBarMetricsLandscapePhone];

    if ([UINavigationBar instancesRespondToSelector:@selector(setBarTintColor:)]) {
        [[UINavigationBar appearance] setBarTintColor:[theme colorForKey:@[@"NavigationBar.BarTintColor", @"BarTintColor"] withDefault:nil]];
    }

    if ([UINavigationBar instancesRespondToSelector:@selector(setBackIndicatorImage:)]) {
        UIImage *backIndicator = [theme imageForKey:@"NavigationBar.BackIndicator"];
        [UINavigationBar appearance].backIndicatorImage = backIndicator;
        [UINavigationBar appearance].backIndicatorTransitionMaskImage = backIndicator;
    } else {
        UIImage *image = [theme imageForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"BackgroundImage"];
        UIImage *selectedImage = [theme imageForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"SelectedBackgroundImage"];
        UIImage *highlightedImage = [theme imageForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"HighlightedBackgroundImage" withDefault:selectedImage];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:selectedImage forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:highlightedImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:selectedImage forState:UIControlStateSelected barMetrics:UIBarMetricsLandscapePhone];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:highlightedImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
    }

    [[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:[theme floatForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"BackgroundImage.VerticalOffset"] forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:[theme floatForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"BackgroundImage.LandscapeVerticalOffset"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:[theme offsetForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"Title.Offset"] forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:[theme offsetForKey:@[@"BarButtonItemBack", @"BarButtonItem"] withSubkey:@"Title.Offset"] forBarMetrics:UIBarMetricsLandscapePhone];

    UIImage *image = [theme imageForKey:@"BarButtonItem.BackgroundImage"];
    UIImage *selectedImage = [theme imageForKey:@"BarButtonItem.SelectedBackgroundImage"];
    UIImage *highlightedImage = [theme imageForKey:@"BarButtonItem.HighlightedBackgroundImage" withDefault:selectedImage];
    [[UIBarButtonItem appearance] setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:selectedImage forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:highlightedImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackgroundImage:selectedImage forState:UIControlStateSelected barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackgroundImage:highlightedImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];

    [[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:[theme floatForKey:@"BarButtonItem.BackgroundImage.VerticalOffset"] forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:[theme floatForKey:@"BarButtonItem.BackgroundImage.LandscapeVerticalOffset"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:[theme offsetForKey:@"BarButtonItem.Title.Offset"] forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:[theme offsetForKey:@"BarButtonItem.Title.Offset"] forBarMetrics:UIBarMetricsLandscapePhone];

    UIFont *font = [theme fontForKey:@"BarButtonItem.Title.Font"];
    UIFont *selectedFont = [theme fontForKey:@"BarButtonItem.SelectedTitle.Font"];

    UIColor *textColor = [theme colorForKey:@"BarButtonItem.Title.TextColor" withDefault:[UIColor blackColor]];
    UIColor *selectedTextColor = [theme colorForKey:@"BarButtonItem.SelectedTitle.TextColor"];

    UIColor *textShadowColor = [theme colorForKey:@"BarButtonItem.Title.TextShadowColor" withDefault:[UIColor clearColor]];
    UIColor *selectedTextShadowColor = [theme colorForKey:@"BarButtonItem.SelectedTitle.TextShadowColor" withDefault:textShadowColor];

    UIOffset textShadowOffset = [theme offsetForKey:@"BarButtonItem.Title.TextShadowOffset" withDefault:UIOffsetZero];
    UIOffset selectedTextShadowOffset = [theme offsetForKey:@"BarButtonItem.SelectedTitle.TextShadowOffset" withDefault:textShadowOffset];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
        UITextAttributeFont: font,
        UITextAttributeTextColor: textColor,
        UITextAttributeTextShadowColor: textShadowColor,
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:textShadowOffset]
    } forState:UIControlStateNormal];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
        UITextAttributeFont: selectedFont,
        UITextAttributeTextColor: selectedTextColor,
        UITextAttributeTextShadowColor: selectedTextShadowColor,
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:selectedTextShadowOffset]
    } forState:UIControlStateHighlighted];
}

+ (void)styleAlertView
{
    [BEAlertView setShowAnimationScale:[BEUI.theme floatForKey:@"Alert.ShowAnimationScale" withDefault:1.4f]];
    [BEAlertView setHideAnimationScale:[BEUI.theme floatForKey:@"Alert.HideAnimationScale" withDefault:0.8f]];
    [BEAlertView setCornerRadii:[BEUI.theme cornerRadiiForKey:@"Alert.CornerRadius" withDefault:@[@0.0f, @0.0f, @0.0f, @0.0f]]];
}

+ (void)styleDialogView
{
    [BEDialogView setShowAnimationScale:[BEUI.theme floatForKey:@"Dialog.ShowAnimationScale" withDefault:1.4f]];
    [BEDialogView setHideAnimationScale:[BEUI.theme floatForKey:@"Dialog.HideAnimationScale" withDefault:0.8f]];
    [BEDialogView setCornerRadii:[BEUI.theme cornerRadiiForKey:@"Dialog.CornerRadius" withDefault:@[@0.0f, @0.0f, @0.0f, @0.0f]]];
    [BEDialogView setButtonHeight:[BEUI.theme floatForKey:@"DialogButton.Height" withDefault:60.0f]];
    [BEDialogView setTitleColor:[BEUI.theme colorForKey:@"Dialog.Title.TextColor" withDefault:[UIColor blackColor]]];
    [BEDialogView setTitleFont:[BEUI.theme fontForKey:@"Dialog.Title.Font"]];
    [BEDialogView setTitleMargin:[BEUI.theme edgeInsetsForKey:@"Dialog.Title.Margin"]];
    [BEDialogView setDescriptionColor:[BEUI.theme colorForKey:@"Dialog.Description.TextColor" withDefault:[UIColor blackColor]]];
    [BEDialogView setDescriptionFont:[BEUI.theme fontForKey:@"Dialog.Description.Font"]];
    [BEDialogView setDescriptionMargin:[BEUI.theme edgeInsetsForKey:@"Dialog.Description.Margin"]];
}

+ (void)stylePopoverBackgroundView
{
    [BEPopoverBackgroundView setArrowBase:[theme floatForKey:@"PopoverBackground.ArrowBase" withDefault:34.0f]];
    [BEPopoverBackgroundView setArrowHeight:[theme floatForKey:@"PopoverBackground.ArrowHeight" withDefault:17.0f]];
    [BEPopoverBackgroundView setCornerRadius:[theme floatForKey:@"PopoverBackground.CornerRadius" withDefault:6.0f]];
    [BEPopoverBackgroundView setContentViewInsets:[theme edgeInsetsForKey:@"PopoverBackground.Padding" withDefault:UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f)]];
    [BEPopoverBackgroundView setUpArrowGradientTopColor:[theme colorForKey:@"PopoverBackground.UpArrowGradientTopColor" withDefault:nil]];
    [BEPopoverBackgroundView setUpArrowGradientBottomColor:[theme colorForKey:@"PopoverBackground.UpArrowGradientBottomColor" withDefault:nil]];
    [BEPopoverBackgroundView setGradientTopColor:[theme colorForKey:@"PopoverBackground.GradientTopColor" withDefault:nil]];
    [BEPopoverBackgroundView setGradientBottomColor:[theme colorForKey:@"PopoverBackground.GradientBottomColor" withDefault:nil]];
    [BEPopoverBackgroundView setGradientHeight:[theme floatForKey:@"PopoverBackground.GradientHeight" withDefault:74.0f]];
    [BEPopoverBackgroundView setBackgroundColor:[theme colorForKey:@"PopoverBackground.BackgroundColor" withDefault:[UIColor whiteColor]]];
}

+ (void)styleStatusBar
{
    [[UIApplication sharedApplication] setStatusBarStyle:BEUI.preferredStatusBarStyle];
}

+ (UINavigationBar *)styleNavigationBar:(UINavigationBar *)navigationBar
{
    if (!UIDevice.isIOS7) {
        navigationBar.translucent = navigationBarTranslucent;
        navigationBar.tintColor = [theme colorForKey:@"NavigationBar.TintColor" withDefault:nil];
        navigationBar.clipsToBounds = navigationBarClipsToBounds;
    }
    return navigationBar;
}

+ (UILabel *)styleNavigationBarTitleView:(UILabel *)titleView
{
    titleView.font = [BEUI.theme fontForKey:@"NavigationBar.Title.Font"];
    titleView.textColor = [BEUI.theme colorForKey:@"NavigationBar.Title.TextColor"];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.backgroundColor = [UIColor clearColor];
    return titleView;
}

+ (UIButton *)styleButton:(UIButton *)button withKey:(id)key
{
    CGSize size = [theme sizeForKey:key withDefault:button.bounds.size];
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        button.bounds = CGRectMake(0, 0, size.width, size.height);
    }

    CGFloat alpha = [theme floatForKey:key withSubkey:@"Alpha" withDefault:1.0f];
    button.alpha = alpha;

    UIFont *font = [theme fontForKey:key withSubkey:@"Title.Font" withDefault:nil];
    button.titleLabel.font = font;

    BOOL titleAdjustsFontSize = [theme boolForKey:key withSubkey:@"Title.AdjustsFontSize" withDefault:NO];
    button.titleLabel.adjustsFontSizeToFitWidth = titleAdjustsFontSize;

    UIColor *titleColor = [theme colorForKey:key withSubkey:@"Title.TextColor" withDefault:[UIColor blackColor]];
    [button setTitleColor:titleColor forState:UIControlStateNormal];

    UIColor *selectedTitleColor = [theme colorForKey:key withSubkey:@"SelectedTitle.TextColor" withDefault:nil];
    [button setTitleColor:selectedTitleColor forState:UIControlStateSelected];

    UIColor *disabledTitleColor = [theme colorForKey:key withSubkey:@"DisabledTitle.TextColor" withDefault:nil];
    [button setTitleColor:disabledTitleColor forState:UIControlStateDisabled];

    UIColor *highlightedTitleColor = [theme colorForKey:key withSubkey:@"HighlightedTitle.TextColor" withDefault:selectedTitleColor];
    [button setTitleColor:highlightedTitleColor forState:UIControlStateHighlighted];

    UIEdgeInsets titleMargin = [theme edgeInsetsForKey:key withSubkey:@"Title.Margin"];
    [button setTitleEdgeInsets:titleMargin];

    UIEdgeInsets imageMargin = [theme edgeInsetsForKey:key withSubkey:@"ImageMargin"];
    [button setImageEdgeInsets:imageMargin];

    UIEdgeInsets padding = [theme edgeInsetsForKey:key withSubkey:@"Padding"];
    [button setContentEdgeInsets:padding];

    NSString *title = [theme stringForKey:key withSubkey:@"Title.Text"];
    [button setTitle:title forState:UIControlStateNormal];

    UIColor *backgroundColor = [theme colorForKey:key withSubkey:@"BackgroundColor" withDefault:nil];
    button.backgroundColor = backgroundColor;

    UIImage *image = [theme imageForKey:key withSubkey:@"Image"];
    [button setImage:image forState:UIControlStateNormal];

    UIImage *selectedImage = [theme imageForKey:key withSubkey:@"SelectedImage"];
    [button setImage:selectedImage forState:UIControlStateSelected];

    UIImage *highlightedImage = [theme imageForKey:key withSubkey:@"HighlightedImage" withDefault:selectedImage];
    [button setImage:highlightedImage forState:UIControlStateHighlighted];

    UIImage *backgroundImage = [theme imageForKey:key withSubkey:@"BackgroundImage"];
    [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];

    UIImage *selectedBackgroundImage = [theme imageForKey:key withSubkey:@"SelectedBackgroundImage"];
    [button setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];

    UIImage *highlightedBackgroundImage = [theme imageForKey:key withSubkey:@"HighlightedBackgroundImage" withDefault:selectedBackgroundImage];
    [button setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];

    return button;
}

+ (UILabel *)styleLabel:(UILabel *)label withKey:(id)key
{
    CGFloat alpha = [theme floatForKey:key withSubkey:@"Alpha" withDefault:1.0f];
    label.alpha = alpha;

    UIFont *font = [theme fontForKey:key withSubkey:@"Font" withDefault:nil];
    label.font = font;

    BOOL titleAdjustsFontSize = [theme boolForKey:key withSubkey:@"AdjustsFontSize" withDefault:NO];
    label.adjustsFontSizeToFitWidth = titleAdjustsFontSize;

    UIColor *titleColor = [theme colorForKey:key withSubkey:@"TextColor" withDefault:[UIColor blackColor]];
    label.textColor = titleColor;

    CGFloat numberOfLines = [theme floatForKey:key withSubkey:@"NumberOfLines" withDefault:0];
    label.numberOfLines = numberOfLines;
    if (numberOfLines != 1) {
        label.lineBreakMode = NSLineBreakByWordWrapping;
    }

    NSString *title = [theme stringForKey:key withSubkey:@"Text"];
    label.text = title;

    UIColor *backgroundColor = [theme colorForKey:key withSubkey:@"BackgroundColor" withDefault:[UIColor clearColor]];
    label.backgroundColor = backgroundColor;

    UIColor *shadowColor = [theme colorForKey:key withSubkey:@"ShadowColor" withDefault:nil];
    label.shadowColor = shadowColor;

    CGSize shadowOffset = [theme sizeForKey:key withSubkey:@"ShadowOffset" withDefault:CGSizeMake(0, -1)];
    label.shadowOffset = shadowOffset;

    if ([theme hasKey:key withSubkey:@"Height"]) {
        CGRect frame = label.frame;
        frame.size.height = [theme floatForKey:key withSubkey:@"Height"];
        label.frame = frame;
    }

    if ([theme hasKey:key withSubkey:@"Width"]) {
        CGRect frame = label.frame;
        frame.size.width = [theme floatForKey:key withSubkey:@"Width"];
        label.frame = frame;
    }
    
    return label;
}

+ (UILabel *)labelWithKey:(id)key
{
    UILabel *label = [[UILabel alloc] init];
    [BEUI styleLabel:label withKey:key];
    return label;
}

+ (UIButton *)buttonWithKey:(id)key target:(id)target action:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [BEUI styleButton:button withKey:key];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (UIBarButtonItem *)barButtonItemWithKey:(id)key target:(id)target action:(SEL)selector
{
    return [[UIBarButtonItem alloc] initWithCustomView:[BEUI buttonWithKey:key target:target action:selector]];
}

+ (void)frontload
{
    [BEThread background:^{
        NSArray *key;
        UIColor *color;

        // Global
        [theme colorForKey:@"TintColor"];
        [theme colorForKey:@"NavigationBar.TintColor" withDefault:nil];
        [theme colorForKey:@"NavigationBar.Title.TextColor"];
        [theme fontForKey:@"NavigationBar.Title.Font"];
        [theme imageForKey:@"TableCellAccessory.Image"];
        [theme imageForKey:@"TableCellAccessory.SelectedImage"];

        // BECropController
        [BEUI barButtonItemWithKey:@[@"NavigationBarOkButton", @"NavigationBarButton"] target:nil action:nil];

        // BEInboxController
        key = @[@"NoteTableArchiveCell", @"TableCell"];
        [theme colorForKey:key withSubkey:@"BackgroundColor" withDefault:[UIColor whiteColor]];
        [theme colorForKey:key withSubkey:@"SelectedBackgroundColor"];
        [theme colorForKey:key withSubkey:@"TextColor"];
        [theme colorForKey:key withSubkey:@"SelectedTextColor"];
        [theme fontForKey:key withSubkey:@"TextFont"];
        [theme imageForKey:key withSubkey:@"Image"];

        // BENoteImageController
        [theme colorForKey:@"NavigationBarBlack.BackgroundColor"];
        [BEUI barButtonItemWithKey:@[@"NavigationBarBlackDoneButton", @"NavigationBarBlackButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NavigationBarNormalImageButton", @"NavigationBarBlackButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NavigationBarOcrImageButton", @"NavigationBarBlackButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NavigationBarSpotlightImageButton", @"NavigationBarBlackButton"] target:nil action:nil];

        // BENoteSheetTableViewCell
        key = @[@"NoteSheetTableCell", @"TableCell"];
        [theme colorForKey:key withSubkey:@"BackgroundColor"];
        [theme colorForKey:key withSubkey:@"SelectedBackgroundColor"];
        [theme colorForKey:key withSubkey:@"TextColor"];
        [theme colorForKey:key withSubkey:@"SelectedTextColor"];
        [theme fontForKey:key withSubkey:@"Font"];
        [theme fontForKey:key withSubkey:@"SmallFont"];

        // BENoteTableController
        key = @[@"NoteTable", @"Table"];
        [theme colorForKey:key withSubkey:@"SeparatorColor"];
        key = @[@"NoteTableSectionHeader", @"TableSectionHeader"];
        [theme colorForKey:key withSubkey:@"BackgroundColor"];
        [theme colorForKey:key withSubkey:@"TextColor"];
        [theme colorForKey:key withSubkey:@"SelectedTextColor"];
        [theme fontForKey:key withSubkey:@"Font"];
        [theme imageForKey:key withSubkey:@"BackgroundImage"];

        // BENoteTableViewCell
        key = @[@"NoteTableCell", @"TableCell"];
        [theme colorForKey:key withSubkey:@"BackgroundColor"];
        [theme colorForKey:key withSubkey:@"SelectedBackgroundColor"];
        color = [theme colorForKey:key withSubkey:@"TextColor"];
        [theme colorForKey:key withSubkey:@"Text.TextColor" withDefault:color];
        [theme colorForKey:key withSubkey:@"DetailText.TextColor" withDefault:color];
        color = [theme colorForKey:key withSubkey:@"SelectedTextColor"];
        [theme colorForKey:key withSubkey:@"Text.SelectedTextColor" withDefault:color];
        [theme colorForKey:key withSubkey:@"DetailText.SelectedTextColor" withDefault:color];
        [theme fontForKey:key withSubkey:@"Text.Font"];
        [theme fontForKey:key withSubkey:@"DetailText.Font"];
        [BEUI buttonWithKey:@"NoteTableCell.ArchiveButton" target:nil action:nil];
        [BEUI buttonWithKey:@"NoteTableCell.DeleteButton" target:nil action:nil];

        // BENoteController
        [theme colorForKey:@"Note.BackgroundColor"];
        [theme fontForKey:@"Note.Font"];
        [theme colorForKey:@"Note.TextColor"];
        [theme colorForKey:@"Note.BackgroundColor"];
        [theme fontForKey:@[@"NoteNavigationBar.UnsavedTitle", @"NavigationBar.Title"] withSubkey:@"Font"];
        [theme imageForKey:@"NoteToolbar.BackgroundImage"];
        [theme imageForKey:@"NoteToolbar.ShadowImage"];
//        [BEUI barButtonItemWithKey:@[@"NoteToolbarSaveButton", @"NoteToolbarButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NoteToolbarCopyButton", @"NoteToolbarButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NoteToolbarArchiveButton", @"NoteToolbarButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NoteToolbarUnarchiveButton", @"NoteToolbarButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NoteToolbarDeleteButton", @"NoteToolbarButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NavigationBarDismissKeyboardButton", @"NavigationBarButton"] target:nil action:nil];
        [BEUI barButtonItemWithKey:@[@"NavigationBarPlusButton", @"NavigationBarButton"] target:nil action:nil];
        [BEUI buttonWithKey:@[@"NoteDeleteAlertDeleteButton", @"AlertWarningButton", @"AlertButton"] target:nil action:nil];
        [BEUI buttonWithKey:@[@"NoteDeleteAlertCancelButton", @"AlertCancelButton", @"AlertButton"] target:nil action:nil];
    }];
}

@end
