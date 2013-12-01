#import "BENoteSheetTableViewCell.h"

#import "BEUI.h"
#import "UIColor+Tools.h"
#import "UIImage+Drawing.h"
#import "UIView+Tools.h"


@implementation BENoteSheetTableViewCell
{
    NSMutableArray *buttons;
    UILabel *textLabel;
}

static NSArray *themeKey;

static UIEdgeInsets accessoryMargin;
static UIEdgeInsets buttonMargin;
static CGFloat buttonWidth;
static UIEdgeInsets cellPadding;
static UIEdgeInsets textMargin;

+ (void)initialize
{
    themeKey = @[@"NoteSheetTableCell", @"TableCell"];
    accessoryMargin = [BEUI.theme edgeInsetsForKey:@"TableCellAccessory.Margin"];
    buttonMargin = [BEUI.theme edgeInsetsForKey:@"NoteSheetTableCellButton.Margin"];
    buttonWidth = [BEUI.theme floatForKey:@"NoteSheetTableCellButton.Width"];
    cellPadding = [BEUI.theme edgeInsetsForKey:themeKey withSubkey:@"Padding"];
    textMargin = [BEUI.theme edgeInsetsForKey:themeKey withSubkey:@"Text.Margin"];
}

@synthesize type = _type;
@synthesize date = _date;
@synthesize timeZone = _timeZone;
@synthesize duration = _duration;
@synthesize addressComponents = _addressComponents;
@synthesize URL = _URL;
@synthesize email = _email;
@synthesize phoneNumber = _phoneNumber;
@synthesize components = _components;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        buttons = [NSMutableArray array];

        self.accessoryView = [[UIImageView alloc] initWithImage:[BEUI.theme imageForKey:@"TableCellAccessory.Image"]
                                               highlightedImage:[BEUI.theme imageForKey:@"TableCellAccessory.SelectedImage"]];

        self.backgroundColor = [BEUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.selectedBackgroundView.backgroundColor = [BEUI.theme colorForKey:themeKey withSubkey:@"SelectedBackgroundColor"];

        textLabel = [[UILabel alloc] init];
        textLabel.backgroundColor = [BEUI.theme colorForKey:themeKey withSubkey:@"BackgroundColor"];
        textLabel.textColor = [BEUI.theme colorForKey:themeKey withSubkey:@"TextColor"];
        textLabel.highlightedTextColor = [BEUI.theme colorForKey:themeKey withSubkey:@"SelectedTextColor"];
        textLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:textLabel];
    }
    return self;
}

- (NSString *)text
{
    return textLabel.text;
}

- (void)setText:(NSString *)text
{
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound) {
        textLabel.adjustsFontSizeToFitWidth = YES;
        textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        textLabel.numberOfLines = 1;
        textLabel.font = [BEUI.theme fontForKey:themeKey withSubkey:@"Font"];
    } else {
        textLabel.adjustsFontSizeToFitWidth = NO;
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        NSUInteger numberOfLines = 0;
        NSUInteger index = 0;
        NSUInteger stringLength = text.length;
        for(index=0, numberOfLines=0; index < stringLength; numberOfLines++) {
            index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
        }
        textLabel.numberOfLines = MIN(numberOfLines, 3);
        if(numberOfLines > 2) {
            textLabel.font = [BEUI.theme fontForKey:themeKey withSubkey:@"SmallFont"];
        } else {
            textLabel.font = [BEUI.theme fontForKey:themeKey withSubkey:@"Font"];
        }
    }
    textLabel.text = text;
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    CGRect accessoryFrame = self.accessoryView.frame;
    accessoryFrame.origin.x = width - accessoryFrame.size.width - accessoryMargin.right;
    accessoryFrame = [UIView alignRect:accessoryFrame];
    self.accessoryView.frame = accessoryFrame;

    CGFloat maxLabelWidth = width -
                            (buttonWidth * buttons.count) -
                            ((buttonMargin.left + buttonMargin.right) * buttons.count) -
                            ((cellPadding.left + cellPadding.right)) -
                            textMargin.left -
                            textMargin.right -
                            accessoryFrame.size.width -
                            accessoryMargin.right;

    CGFloat maxLabelHeight = height -
                             cellPadding.top -
                             cellPadding.bottom -
                             textMargin.top -
                             textMargin.bottom;

    CGSize maxLabelSize = CGSizeMake(maxLabelWidth, maxLabelHeight);

    CGSize labelSize = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:maxLabelSize lineBreakMode:textLabel.lineBreakMode];
    textLabel.frameAligned = CGRectMake(self.accessoryView.frame.origin.x - labelSize.width - textMargin.right,
                                        (height - labelSize.height) / 2.0f,
                                        labelSize.width,
                                        labelSize.height);
}

- (void)addButtonWithKey:(NSString *)key
                  target:(id)target
                  action:(SEL)selector
{
    UIButton *button = [BEUI buttonWithKey:@[key, @"NoteSheetTableCellButton"] target:target action:selector];

    CGFloat width = 0.0f;
    for (UIButton *button in buttons) {
        width += button.frame.size.width + buttonMargin.left + buttonMargin.right;
    }

    button.frameAligned = CGRectMake(cellPadding.left + width,
                                     cellPadding.top + buttonMargin.top,
                                     button.frame.size.width,
                                     button.frame.size.height);

    [buttons addObject:button];
    [self addSubview:button];
    [self layoutSubviews];
}

@end
