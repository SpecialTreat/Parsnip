#import "PreenNoteSheetController.h"

#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+Tools.h"
#import "PreenAlertView.h"
#import "PreenNoteSheetTableViewCell.h"
#import "PreenUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIDevice+Tools.h"
#import "UIImage+Drawing.h"
#import "UIView+Tools.h"
#import "UIViewController+Tools.h"


@implementation PreenNoteSheetController
{
    UIBarButtonItem *keepButton;
    UIBarButtonItem *copyButton;
    UIBarButtonItem *archiveButton;
    UIBarButtonItem *unarchiveButton;
    UIBarButtonItem *discardButton;
    UIToolbar *toolbar;
    UIView *toolbarBorder;
    
    UITableView *tableView;
}

static CGFloat popoverScreenPercentage;

static CGFloat tableCellButtonHeight;
static UIEdgeInsets tableCellButtonMargin;
static UIEdgeInsets tableCellPadding;

static UIEdgeInsets toolbarBorderSize;
static CGFloat toolbarButtonWidth;
static CGFloat toolbarHeight;
static UIEdgeInsets toolbarMargin;
static CGFloat toolbarSpacer;

+ (void)initialize
{
    popoverScreenPercentage = [PreenUI.theme floatForKey:@"NoteSheetPopover.ScreenPercentage"];

    tableCellButtonHeight = [PreenUI.theme floatForKey:@"NoteSheetTableCellButton.Height"];
    tableCellButtonMargin = [PreenUI.theme edgeInsetsForKey:@"NoteSheetTableCellButton.Margin"];
    tableCellPadding = [PreenUI.theme edgeInsetsForKey:@[@"NoteSheetTableCell", @"TableCell"] withSubkey:@"Padding"];

    toolbarButtonWidth = [PreenUI.theme floatForKey:@"NoteSheetToolbarButton.Width"];
    toolbarSpacer = [PreenUI.theme floatForKey:@"NoteSheetToolbar.Spacer"];
    toolbarHeight = [PreenUI.theme floatForKey:@"NoteSheetToolbar.Height"];
    toolbarMargin = [PreenUI.theme edgeInsetsForKey:@"NoteSheetToolbar.Margin"];
    toolbarBorderSize = [PreenUI.theme edgeInsetsForKey:@"NoteSheetToolbar.Border"];
}

@synthesize note = _note;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.manuallyAdjustsViewInsets = YES;
    }
    return self;
}

- (CGSize)preferredSize
{
    NSUInteger numberOfRows = self.numberOfRows;
    return CGSizeMake((toolbarButtonWidth * 4.0f) + (toolbarSpacer * 3.0f),
                      toolbarHeight + (numberOfRows * tableView.rowHeight));
}

- (CGSize)contentSizeForViewInPopover
{
    CGSize size = [self preferredSize];
    size.height = MIN(size.height, [UIScreen mainScreen].bounds.size.height * popoverScreenPercentage);
    return size;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:self.frameForView];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect frame = self.view.bounds;

    keepButton = [PreenUI barButtonItemWithKey:@[@"NoteSheetToolbarSaveButton", @"NoteSheetToolbarButton"] target:self action:@selector(onKeepButtonTouch:event:)];
    copyButton = [PreenUI barButtonItemWithKey:@[@"NoteSheetToolbarCopyButton", @"NoteSheetToolbarButton"] target:self action:@selector(onCopyButtonTouch:event:)];
    archiveButton = [PreenUI barButtonItemWithKey:@[@"NoteSheetToolbarArchiveButton", @"NoteSheetToolbarButton"] target:self action:@selector(onArchiveButtonTouch:event:)];
    unarchiveButton = [PreenUI barButtonItemWithKey:@[@"NoteSheetToolbarUnarchiveButton", @"NoteSheetToolbarButton"] target:self action:@selector(onUnarchiveButtonTouch:event:)];
    discardButton = [PreenUI barButtonItemWithKey:@[@"NoteSheetToolbarDeleteButton", @"NoteSheetToolbarButton"] target:self action:@selector(onDiscardButtonTouch:event:)];

    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(toolbarMargin.left,
                                                          toolbarMargin.top,
                                                          frame.size.width - (toolbarMargin.left + toolbarMargin.right),
                                                          toolbarHeight - (toolbarMargin.top + toolbarMargin.bottom))];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbar.clipsToBounds = YES;
    [toolbar setBackgroundImage:[PreenUI.theme imageForKey:@"NoteSheetToolbar.BackgroundImage"] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    if (_note.archived) {
        toolbar.items = @[keepButton,
                          [UIBarButtonItem spacer],
                          copyButton,
                          [UIBarButtonItem spacer],
                          unarchiveButton,
                          [UIBarButtonItem spacer],
                          discardButton];
    } else {
        toolbar.items = @[keepButton,
                          [UIBarButtonItem spacer],
                          copyButton,
                          [UIBarButtonItem spacer],
                          archiveButton,
                          [UIBarButtonItem spacer],
                          discardButton];
    }

    NSDictionary *borderColor = [PreenUI.theme borderColorForKey:@"NoteSheetToolbar.BorderColor"];
    CGFloat borderHeight = toolbarBorderSize.bottom / [UIScreen mainScreen].scale;
    toolbarBorder = [[UIView alloc]initWithFrame:CGRectMake(0, toolbarHeight, frame.size.width, borderHeight)];
    toolbarBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbarBorder.backgroundColor = borderColor[@"bottom"];

    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, toolbarHeight, frame.size.width, frame.size.height - toolbarHeight)];
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.alwaysBounceVertical = YES;
    tableView.bounces = YES;
    tableView.scrollEnabled = YES;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    tableView.rowHeight = tableCellButtonHeight +
                          tableCellButtonMargin.top + tableCellButtonMargin.bottom +
                          tableCellPadding.top + tableCellPadding.bottom;

    [self.view addSubview:toolbar];
    [self.view addSubview:tableView];
    [self.view addSubview:toolbarBorder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)dealloc
{
    self.delegate = nil;
    tableView.delegate = nil;
}

- (NSInteger)numberOfRows
{
    NSDictionary *dataTypes = self.note.dataTypes;
    NSUInteger count = [dataTypes[@"PhoneNumber"] count];
    count += [dataTypes[@"Address"] count];
    count += [dataTypes[@"Email"] count];
    count += [dataTypes[@"URL"] count];
    count += (count)? 1: 0;
    count += [dataTypes[@"Date"] count];
    return count;
}

- (NSArray *)dataForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return self.note.dataTypes[@"PhoneNumber"][indexPath.row];
    } else if (indexPath.section == 2) {
        return self.note.dataTypes[@"Address"][indexPath.row];
    } else if (indexPath.section == 3) {
        return self.note.dataTypes[@"Email"][indexPath.row];
    } else if (indexPath.section == 4) {
        return self.note.dataTypes[@"URL"][indexPath.row];
    } else if (indexPath.section == 5) {
        return self.note.dataTypes[@"Date"][indexPath.row];
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *dataTypes = _note.dataTypes;
    if (section == 0) {
        return (self.note.hasPerson)? 1: 0;
    } else if (section == 1) {
        return [dataTypes[@"PhoneNumber"] count];
    } else if (section == 2) {
        return [dataTypes[@"Address"] count];
    } else if (section == 3) {
        return [dataTypes[@"Email"] count];
    } else if (section == 4) {
        return [dataTypes[@"URL"] count];
    } else if (section == 5) {
        return [dataTypes[@"Date"] count];
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)view cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PreenNoteSheetTableViewCell *cell;
    if (indexPath.section == 0) {
        if (self.note.hasPerson) {
            cell = [[PreenNoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"Contact";
            cell.text = @"Add Contact";

            [cell addButtonWithKey:@"NoteSheetTableCellContactButton"
                            target:self
                            action:@selector(onContactButtonTouch:event:)];
        }
    } else if (indexPath.section == 1) {
        NSArray *data = self.note.dataTypes[@"PhoneNumber"][indexPath.row];
        if (data) {
            cell = [[PreenNoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"PhoneNumber";
            cell.text = data[0];
            cell.phoneNumber = data[1];
            
            [cell addButtonWithKey:@"NoteSheetTableCellCallButton"
                            target:self
                            action:@selector(onCallButtonTouch:event:)];

            [cell addButtonWithKey:@"NoteSheetTableCellMessageButton"
                            target:self
                            action:@selector(onMessageButtonTouch:event:)];
        }
    } else if (indexPath.section == 2) {
        NSArray *data = self.note.dataTypes[@"Address"][indexPath.row];
        if (data) {
            cell = [[PreenNoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"Address";
            cell.text = data[0];
            cell.addressComponents = data[1];

            [cell addButtonWithKey:@"NoteSheetTableCellMapButton"
                            target:self
                            action:@selector(onMapButtonTouch:event:)];

            if([UIDevice isGoogleMapsInstalled]) {
                [cell addButtonWithKey:@"NoteSheetTableCellGoogleMapsButton"
                                target:self
                                action:@selector(onGoogleMapsButtonTouch:event:)];
            }
        }
    } else if (indexPath.section == 3) {
        NSArray *data = self.note.dataTypes[@"Email"][indexPath.row];
        if (data) {
            cell = [[PreenNoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"Email";
            cell.text = data[0];
            cell.email = data[1];

            [cell addButtonWithKey:@"NoteSheetTableCellEmailButton"
                            target:self
                            action:@selector(onEmailButtonTouch:event:)];
        }
    } else if (indexPath.section == 4) {
        NSArray *data = self.note.dataTypes[@"URL"][indexPath.row];
        if (data) {
            cell = [[PreenNoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"URL";
            cell.text = data[0];
            cell.URL = data[1];

            [cell addButtonWithKey:@"NoteSheetTableCellSafariButton"
                            target:self
                            action:@selector(onSafariButtonTouch:event:)];

            if([UIDevice isChromeInstalled]) {
                [cell addButtonWithKey:@"NoteSheetTableCellChromeButton"
                                target:self
                                action:@selector(onChromeButtonTouch:event:)];
            }
        }
    } else if (indexPath.section == 5) {
        NSArray *data = self.note.dataTypes[@"Date"][indexPath.row];
        if (data) {
            cell = [[PreenNoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"Date";
            cell.text = data[0];
            cell.date = data[1];
            cell.duration = [data[2] doubleValue];
            cell.timeZone = data[3];

            [cell addButtonWithKey:@"NoteSheetTableCellDateButton"
                            target:self
                            action:@selector(onDateButtonTouch:event:)];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)view didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(self) {
        if (indexPath.section == 0) {
            [self.delegate noteSheet:self contact:self.note];
        } else if (indexPath.section == 1) {
            NSArray *data = self.note.dataTypes[@"PhoneNumber"][indexPath.row];
            [self.delegate noteSheet:self contact:self.note text:data[0] phoneNumber:data[1]];
        } else if (indexPath.section == 2) {
            NSArray *data = self.note.dataTypes[@"Address"][indexPath.row];
            [self.delegate noteSheet:self contact:self.note text:data[0] address:data[1]];
        } else if (indexPath.section == 3) {
            NSArray *data = self.note.dataTypes[@"Email"][indexPath.row];
            [self.delegate noteSheet:self contact:self.note text:data[0] email:data[1]];
        } else if (indexPath.section == 4) {
            NSArray *data = self.note.dataTypes[@"URL"][indexPath.row];
            [self.delegate noteSheet:self contact:self.note text:data[0] url:data[1]];
        } else if (indexPath.section == 5) {
            NSArray *data = self.note.dataTypes[@"Date"][indexPath.row];
            [self.delegate noteSheet:self calendar:self.note text:data[0] date:data[1] duration:[data[2] doubleValue] timeZone:data[3]];
        }
        [view deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)setNote:(PreenNote *)note
{
    _note = note;
    if (self.isViewLoaded) {
        if (_note.archived) {
            toolbar.items = @[keepButton,
                              [UIBarButtonItem spacer],
                              copyButton,
                              [UIBarButtonItem spacer],
                              unarchiveButton,
                              [UIBarButtonItem spacer],
                              discardButton];
        } else {
            toolbar.items = @[keepButton,
                              [UIBarButtonItem spacer],
                              copyButton,
                              [UIBarButtonItem spacer],
                              archiveButton,
                              [UIBarButtonItem spacer],
                              discardButton];
        }
        [tableView reloadData];
        if (self.numberOfRows) {
            tableView.hidden = NO;
            toolbarBorder.hidden = NO;
        } else {
            tableView.hidden = YES;
            toolbarBorder.hidden = YES;
        }
    }
}

- (void)onKeepButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    @synchronized(self) {
        [self.delegate noteSheet:self keep:self.note];
    }
}

- (void)onCopyButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    @synchronized(self) {
        [self.delegate noteSheet:self copy:self.note];
    }
}

- (void)onArchiveButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    @synchronized(self) {
        [self.delegate noteSheet:self archive:self.note];
    }
}

- (void)onUnarchiveButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    @synchronized(self) {
        [self.delegate noteSheet:self unarchive:self.note];
    }
}

- (void)onDiscardButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    @synchronized(self) {
        [self.delegate noteSheet:self discard:self.note];
    }
}

- (void)onDateButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        NSString *text = cell.text;
        NSDate *date = cell.date;
        NSTimeInterval duration = cell.duration;
        NSTimeZone *timeZone = cell.timeZone;
        @synchronized(self) {
            [self.delegate noteSheet:self calendar:self.note text:text date:date duration:duration timeZone:timeZone];
        }
    }
}

- (void)onMapButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        [UIDevice openInMaps:cell.text];
    }
}

- (void)onGoogleMapsButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        [UIDevice openInGoogleMaps:cell.text];
    }
}

- (void)onEmailButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        [[UIApplication sharedApplication] openURL:cell.URL];
    }
}

- (void)onChromeButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        [UIDevice openInChrome:cell.URL createNewTab:YES];
    }
}

- (void)onSafariButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        [[UIApplication sharedApplication] openURL:cell.URL];
    }
}

- (void)onCallButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", cell.phoneNumber]];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)onMessageButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", cell.phoneNumber]];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)onContactButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    PreenNoteSheetTableViewCell *cell = [self parentCell:sender];
    if(cell) {
        @synchronized(self) {
            [self.delegate noteSheet:self contact:self.note];
        }
    }
}

- (PreenNoteSheetTableViewCell *)parentCell:(UIButton *)button
{
    UIView *view = button;
    while(view) {
        if([view isKindOfClass:[PreenNoteSheetTableViewCell class]]) {
            return (PreenNoteSheetTableViewCell *)view;
        }
        view = view.superview;
    }
    return nil;
}

@end
