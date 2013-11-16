#import "PreenNoteTableViewCell.h"

#import "NSString+Tools.h"
#import "PreenThread.h"
#import "PreenUI.h"
#import "UIColor+Tools.h"
#import "UIImage+Drawing.h"
#import "UIView+Tools.h"


@implementation PreenNoteTableViewCell
{
    BOOL _editing;
    BOOL _showingDeleteConfirmation;
    BOOL _showingArchiveConfirmation;

    CGPoint currentPanPoint;
    CGPoint originPanPoint;

    UIView *_contentView;
    UIImageView *_imageView;
    UILabel *_textLabel;
    UILabel *_detailTextLabel;
    UIButton *_deleteButton;
    UIButton *_archiveButton;
}

static NSArray *themeKey;

static CGFloat preferredHeight;
static UIEdgeInsets padding;
static UIEdgeInsets separatorInset;

static CGFloat deleteConfirmationBounceWidth;
static CGFloat deleteConfirmationDragThreshold;
static CGFloat archiveConfirmationDragThreshold;

static UIEdgeInsets textLabelMargin;
static NSString *textLabelEmptyText;

static UIEdgeInsets detailTextLabelMargin;
static NSInteger detailTextLabelNumberOfLines;

static UIEdgeInsets imageViewMargin;
static CGSize imageViewSize;

+ (void)initialize
{
    themeKey = @[@"NoteTableCell", @"TableCell"];

    preferredHeight = [PreenUI.theme floatForKey:themeKey withSubkey:@"Height" withDefault:56.0f];
    padding = [PreenUI.theme edgeInsetsForKey:themeKey withSubkey:@"Padding"];
    separatorInset = [PreenUI.theme edgeInsetsForKey:themeKey withSubkey:@"SeparatorInset"];

    deleteConfirmationBounceWidth = [PreenUI.theme floatForKey:themeKey withSubkey:@"DeleteButtonBounceWidth" withDefault:50.0f];
    deleteConfirmationDragThreshold = [PreenUI.theme floatForKey:themeKey withSubkey:@"DeleteButtonDragThreshold" withDefault:0.5f];
    archiveConfirmationDragThreshold = [PreenUI.theme floatForKey:themeKey withSubkey:@"ArchiveButtonDragThreshold" withDefault:0.5f];

    textLabelMargin = [PreenUI.theme edgeInsetsForKey:themeKey withSubkey:@"Text.Margin"];
    textLabelEmptyText = [PreenUI.theme stringForKey:@"Note.EmptyTitle"];

    detailTextLabelMargin = [PreenUI.theme edgeInsetsForKey:themeKey withSubkey:@"DetailText.Margin"];
    detailTextLabelNumberOfLines = [PreenUI.theme integerForKey:themeKey withSubkey:@"DetailText.NumberOfLines"];

    CGSize thumbnailSize = [PreenUI.theme sizeForKey:@"NoteThumbnailSize"];
    CGFloat imageViewHeight = preferredHeight - padding.top - padding.bottom - imageViewMargin.top - imageViewMargin.bottom;
    CGFloat imageViewWidth = imageViewHeight * (thumbnailSize.width / thumbnailSize.height);
    imageViewSize = CGSizeMake(imageViewWidth, imageViewHeight);
    imageViewMargin = [PreenUI.theme edgeInsetsForKey:themeKey withSubkey:@"Thumbnail.Margin"];
}

+ (CGFloat)preferredHeight
{
    return preferredHeight;
}

@synthesize note = _note;
@synthesize imageView = _imageView;
@synthesize delegate = _delegate;
@synthesize canDelete = _canDelete;
@synthesize canArchive = _canArchive;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
            self.separatorInset = separatorInset;
        }
        _editing = NO;
        _showingDeleteConfirmation = NO;
        _showingArchiveConfirmation = NO;
        _canDelete = YES;
        _canArchive = YES;

        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _contentView.backgroundColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"];

        _imageView = [[UIImageView alloc] initWithFrame:[UIView frameWithParentPadding:padding withSize:imageViewSize withMargin:imageViewMargin]];
        _imageView.backgroundColor = [UIColor whiteColor];
        _imageView.opaque = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;


        UIColor *textColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"TextColor"];
        UIColor *selectedTextColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"SelectedTextColor"];

        _textLabel = [[UILabel alloc] init];
        _textLabel.backgroundColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"];
        _textLabel.textColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"Text.TextColor" withDefault:textColor];;
        _textLabel.highlightedTextColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"Text.SelectedTextColor" withDefault:selectedTextColor];
        _textLabel.textAlignment = NSTextAlignmentLeft;
        _textLabel.font = [PreenUI.theme fontForKey:themeKey withSubkey:@"Text.Font"];
        _textLabel.numberOfLines = 1;

        _detailTextLabel = [[UILabel alloc] init];
        _detailTextLabel.backgroundColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"];
        _detailTextLabel.textColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"DetailText.TextColor" withDefault:textColor];
        _detailTextLabel.highlightedTextColor = [PreenUI.theme colorForKey:themeKey withSubkey:@"DetailText.SelectedTextColor" withDefault:selectedTextColor];
        _detailTextLabel.textAlignment = NSTextAlignmentLeft;
        _detailTextLabel.font = [PreenUI.theme fontForKey:themeKey withSubkey:@"DetailText.Font"];
        _detailTextLabel.numberOfLines = detailTextLabelNumberOfLines;

        _archiveButton = [PreenUI buttonWithKey:@"NoteTableCell.ArchiveButton" target:nil action:nil];
        _archiveButton.hidden = YES;

        _deleteButton = [PreenUI buttonWithKey:@"NoteTableCell.DeleteButton" target:self action:@selector(onDeleteButton)];
        _deleteButton.hidden = YES;

        [self addSubview:_archiveButton];
        [self addSubview:_deleteButton];
        [_contentView addSubview:_imageView];
        [_contentView addSubview:_textLabel];
        [_contentView addSubview:_detailTextLabel];
        [self addSubview:_contentView];

        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        panRecognizer.delegate = self;
        panRecognizer.minimumNumberOfTouches = 1;
        panRecognizer.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:panRecognizer];
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _imageView.frame = [UIView frameWithParentPadding:padding withSize:imageViewSize withMargin:imageViewMargin];

    CGFloat contentX = _imageView.frame.origin.x + _imageView.frame.size.width + imageViewMargin.right;
    CGFloat contentY = padding.top;
    CGFloat contentWidth = self.bounds.size.width - contentX;

    [_textLabel sizeToFit];
    CGRect textLabelFrame = _textLabel.frame;
    textLabelFrame.origin.x = contentX + textLabelMargin.left;
    textLabelFrame.origin.y = contentY + textLabelMargin.top;
    textLabelFrame.size.width = contentWidth - textLabelMargin.left - textLabelMargin.right;
    _textLabel.frameAligned = textLabelFrame;

    [_detailTextLabel sizeToFit];
    CGRect detailTextLabelFrame = _detailTextLabel.frame;
    detailTextLabelFrame.origin.x = contentX + detailTextLabelMargin.left;
    detailTextLabelFrame.origin.y = textLabelFrame.origin.y + textLabelFrame.size.height + textLabelMargin.bottom + detailTextLabelMargin.top;
    detailTextLabelFrame.size.width = contentWidth - detailTextLabelMargin.left - detailTextLabelMargin.right;
    _detailTextLabel.frameAligned = detailTextLabelFrame;

    CGRect archiveButtonFrame = self.bounds;
    archiveButtonFrame.size.width = [UIScreen mainScreen].bounds.size.width;
    archiveButtonFrame.origin.y = 0.0f;
    _archiveButton.frame = archiveButtonFrame;

    CGRect deleteButtonFrame = _deleteButton.frame;
    deleteButtonFrame.origin.x = self.bounds.size.width - _deleteButton.frame.size.width;
    deleteButtonFrame.origin.y = 0.0f;
    _deleteButton.frame = deleteButtonFrame;
}

- (BOOL)showingDeleteConfirmation
{
    return _showingDeleteConfirmation;
}

- (BOOL)showingArchiveConfirmation
{
    return _showingArchiveConfirmation;
}

- (NSString *)archiveButtonTitle
{
    return _archiveButton.titleLabel.text;
}

- (void)setArchiveButtonTitle:(NSString *)archiveButtonTitle
{
    [_archiveButton setTitle:archiveButtonTitle forState:UIControlStateNormal];
}

- (BOOL)isEditing
{
    return _editing || self.showingControls;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    _editing = editing;
    if (!editing) {
        [self hideControlsAnimated:animated completion:nil];
    }
}

- (BOOL)showingControls
{
    return _showingDeleteConfirmation || _showingArchiveConfirmation;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (!self.showingControls) {
        [super setHighlighted:highlighted animated:animated];
        if(highlighted) {
            [self setBackgroundColor:[PreenUI.theme colorForKey:themeKey withSubkey:@"SelectedBackgroundColor"] animated:animated];
        } else {
            [self setBackgroundColor:[PreenUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"] animated:animated];
        }
    }
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        [self setBackgroundColor:[PreenUI.theme colorForKey:themeKey withSubkey:@"SelectedBackgroundColor"] animated:animated];
    } else {
        [self setBackgroundColor:[PreenUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"] animated:animated];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor animated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            _contentView.backgroundColor = backgroundColor;
        }];
    } else {
        _contentView.backgroundColor = backgroundColor;
    }
}

- (void)onDeleteButton
{
    [self.delegate cellDeleteConfirmation:self];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return !_editing && !self.showingControls;
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (_canDelete || _canArchive) {
        CGPoint translation = [gestureRecognizer translationInView:[self superview]];
        if (ABS(translation.x) > ABS(translation.y)) {
            return YES;
        }
    }
    return NO;
}

- (void)onPan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint panPoint = [recognizer translationInView:self];
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        currentPanPoint = panPoint;
        originPanPoint = panPoint;
    } else if(recognizer.state == UIGestureRecognizerStateEnded) {
        if (_showingArchiveConfirmation) {
            CGFloat dragThreshold = (self.bounds.size.width + 1.0f) * archiveConfirmationDragThreshold;
            if (ABS(_contentView.frame.origin.x) > dragThreshold) {
                [self showArchiveConfirmationAnimated:YES completion:^(BOOL finished) {
                    [self.delegate cellArchiveConfirmation:self];
                }];
            } else {
                [self hideControlsAnimated:YES completion:nil];
            }
        } else if (_showingDeleteConfirmation) {
            CGFloat dragThreshold = _deleteButton.frame.size.width * deleteConfirmationDragThreshold;
            if (ABS(_contentView.frame.origin.x) > dragThreshold) {
                [self showDeleteConfirmationAnimated:YES completion:nil];
            } else {
                [self hideControlsAnimated:YES completion:nil];
            }
        }
    } else {
        CGPoint deltaPoint = CGPointMake(currentPanPoint.x - panPoint.x, currentPanPoint.y - panPoint.y);
        currentPanPoint = panPoint;

        CGFloat contentViewX = _contentView.frame.origin.x - deltaPoint.x;

        if (contentViewX < 0.0f) {
            if (!_canDelete || _showingArchiveConfirmation) {
                contentViewX = 0.0f;
            } else {
                CGFloat minX = 0.0f - _deleteButton.frame.size.width;
                if (contentViewX < minX) {
                    CGFloat amountOver = ABS(minX - contentViewX);
                    CGFloat percentOver = MAX(0.0f, (1.0f - (amountOver / deleteConfirmationBounceWidth)));
                    contentViewX = [UIView alignCoordinate:_contentView.frame.origin.x - (deltaPoint.x * percentOver)];
                }
                [self willShowDeleteConfirmation];
            }
        } else if (contentViewX > 0.0f) {
            if (!_canArchive || _showingDeleteConfirmation) {
                contentViewX = 0.0f;
            } else {
                [self willShowArchiveConfirmation];
            }
        }

        CGRect contentViewFrame = _contentView.frame;
        contentViewFrame.origin.x = contentViewX;
        _contentView.frame = contentViewFrame;

        if (_showingArchiveConfirmation) {
            _archiveButton.center = CGPointMake(MIN(contentViewX, self.bounds.size.width + 1.0f) / 2.0f, _archiveButton.center.y);
            _archiveButton.alpha = MIN(1.0f, (contentViewX / (self.bounds.size.width + 1.0f) * 0.75f));
        }
    }
}

- (void)willShowDeleteConfirmation
{
    _archiveButton.hidden = YES;
    if (_showingArchiveConfirmation) {
        _showingArchiveConfirmation = NO;
        [self.delegate cellDidHideArchiveConfirmation:self];
        [self.delegate cellDidHideControls:self];
    }

    if (!_showingDeleteConfirmation) {
        [self.delegate cellWillShowControls:self];
        [self.delegate cellWillShowDeleteConfirmation:self];
        _showingDeleteConfirmation = YES;
    }
    _deleteButton.hidden = NO;
}

- (void)willShowArchiveConfirmation
{
    _deleteButton.hidden = YES;
    if (_showingDeleteConfirmation) {
        _showingDeleteConfirmation = NO;
        [self.delegate cellDidHideDeleteConfirmation:self];
        [self.delegate cellDidHideControls:self];
    }

    if (!_showingArchiveConfirmation) {
        [self.delegate cellWillShowControls:self];
        [self.delegate cellWillShowDeleteConfirmation:self];
        _showingArchiveConfirmation = YES;
    }
    _archiveButton.hidden = NO;
}

- (void)didHideControls
{
    BOOL showingControls = self.showingControls;

    if (_showingDeleteConfirmation) {
        _showingDeleteConfirmation = NO;
        [self.delegate cellDidHideDeleteConfirmation:self];
    }

    if (_showingArchiveConfirmation) {
        _showingArchiveConfirmation = NO;
        [self.delegate cellDidHideArchiveConfirmation:self];
    }

    if (showingControls) {
        [self.delegate cellDidHideControls:self];
    }
}

- (void)showDeleteConfirmationAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
    [self willShowDeleteConfirmation];
    void (^showCompletion)(BOOL) = ^void (BOOL finished) {
        if (completion) {
            completion(finished);
        }
    };

    CGRect contentViewFrame = _contentView.frame;
    contentViewFrame.origin.x = 0.0f - _deleteButton.frame.size.width;
    if (animated) {
        CGFloat deltaX = ABS(_contentView.frame.origin.x - contentViewFrame.origin.x);
        CGFloat deltaPercent = (deltaX / _deleteButton.frame.size.width);
        CGFloat duration = UINavigationControllerHideShowBarDuration * MAX(0.0f, MIN(1.0f, deltaPercent));
        [UIView animateWithDuration:duration animations:^{
            _contentView.frame = contentViewFrame;
        } completion:^(BOOL finished) {
            showCompletion(finished);
        }];
    } else {
        _contentView.frame = contentViewFrame;
        showCompletion(YES);
    }
}

- (void)showArchiveConfirmationAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
    [self willShowArchiveConfirmation];
    void (^showCompletion)(BOOL) = ^void (BOOL finished) {
        if (completion) {
            completion(finished);
        }
    };

    CGRect contentViewFrame = _contentView.frame;
    contentViewFrame.origin.x = (self.bounds.size.width + 1.0f);
    if (animated) {
        CGFloat deltaX = ABS(_contentView.frame.origin.x - contentViewFrame.origin.x);
        CGFloat deltaPercent = (deltaX / (self.bounds.size.width + 1.0f));
        CGFloat duration = UINavigationControllerHideShowBarDuration * MAX(0.0f, MIN(1.0f, deltaPercent));
        [UIView animateWithDuration:duration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             _contentView.frame = contentViewFrame;
                             _archiveButton.center = CGPointMake((self.bounds.size.width + 1) / 2.0f, _archiveButton.center.y);
                             _archiveButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             showCompletion(finished);
                         }];
    } else {
        _contentView.frame = contentViewFrame;
        _archiveButton.center = CGPointMake((self.bounds.size.width + 1) / 2.0f, _archiveButton.center.y);
        _archiveButton.alpha = 1.0f;
        showCompletion(YES);
    }
}

- (void)hideControlsAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
    void (^hideCompletion)(BOOL) = ^void (BOOL finished) {
        [self didHideControls];
        if (completion) {
            completion(finished);
        }
    };

    CGRect contentViewFrame = _contentView.frame;
    contentViewFrame.origin.x = 0.0f;
    if (animated) {
        CGFloat deltaX = ABS(_contentView.frame.origin.x - contentViewFrame.origin.x);
        CGFloat totalX = (_contentView.frame.origin.x > 0.0f)? (self.bounds.size.width + 1.0f): _deleteButton.frame.size.width;
        totalX = totalX / 2.0f;
        CGFloat deltaPercent = (deltaX / totalX);
        CGFloat duration = UINavigationControllerHideShowBarDuration * MAX(0.0f, MIN(1.0f, deltaPercent));
        [UIView animateWithDuration:duration animations:^{
            _contentView.frame = contentViewFrame;
            _archiveButton.center = CGPointMake(0.0f, _archiveButton.center.y);
            _archiveButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            hideCompletion(finished);
        }];
    } else {
        _contentView.frame = contentViewFrame;
        _archiveButton.center = CGPointMake(0.0f, _archiveButton.center.y);
        _archiveButton.alpha = 0.0f;
        hideCompletion(YES);
    }
}

- (void)setNote:(PreenNote *)note
{
    _note = note;
    NSArray *lines = [note.text stripEmptyLines:_detailTextLabel.numberOfLines + 1];
    NSMutableArray *detailLines;
    if (lines.firstObject) {
        _textLabel.text = lines.firstObject;
        detailLines = [NSMutableArray arrayWithArray:[lines subarrayWithRange:NSMakeRange(1, lines.count - 1)]];
    } else {
        _textLabel.text = textLabelEmptyText;
        detailLines = [NSMutableArray array];
    }
    while (detailLines.count < _detailTextLabel.numberOfLines) {
        [detailLines addObject:@" "];
    }
    _detailTextLabel.text = [detailLines componentsJoinedByString:@"\n"];
    _imageView.image = note.thumbnailImage;
}

@end
