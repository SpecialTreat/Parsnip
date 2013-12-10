#import "BENoteSheetController.h"

#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+Tools.h"
#import "BEAlertView.h"
#import "BEInAppPurchaser.h"
#import "BENoteSheetTableViewCell.h"
#import "BEUI.h"
#import "UIBarButtonItem+Tools.h"
#import "UIDevice+Tools.h"
#import "UIImage+Drawing.h"
#import "UIView+Tools.h"
#import "UIViewController+Tools.h"


@implementation BENoteSheetController
{
    UITableView *tableView;
}

static CGFloat popoverScreenPercentage;

static CGFloat tableCellButtonHeight;
static UIEdgeInsets tableCellButtonMargin;
static UIEdgeInsets tableCellPadding;

+ (void)initialize
{
    popoverScreenPercentage = [BEUI.theme floatForKey:@"NoteSheetPopover.ScreenPercentage"];

    tableCellButtonHeight = [BEUI.theme floatForKey:@"NoteSheetTableCellButton.Height"];
    tableCellButtonMargin = [BEUI.theme edgeInsetsForKey:@"NoteSheetTableCellButton.Margin"];
    tableCellPadding = [BEUI.theme edgeInsetsForKey:@[@"NoteSheetTableCell", @"TableCell"] withSubkey:@"Padding"];
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
    return CGSizeMake(MAX(self.view.frame.size.width / 2.0f, 320.0f), self.numberOfRows * tableView.rowHeight);
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

    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    tableView.backgroundColor = [BEUI.theme colorForKey:@[@"NoteSheetTableCell", @"TableCell"] withSubkey:@"BackgroundColor"];
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

    [self.view addSubview:tableView];
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
    NSUInteger count = 1;
    count += [dataTypes[@"PhoneNumber"] count];
    count += [dataTypes[@"Address"] count];
    count += [dataTypes[@"Email"] count];
    count += [dataTypes[@"URL"] count];
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
        return 1;
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
    BENoteSheetTableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        cell.type = @"Contact";
        cell.text = @"Add Contact";

        [cell addButtonWithKey:@"NoteSheetTableCellContactButton"
                        target:self
                        action:@selector(onContactButtonTouch:event:)];
    } else if (indexPath.section == 1) {
        NSArray *data = self.note.dataTypes[@"PhoneNumber"][indexPath.row];
        if (data) {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
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
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
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
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
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
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
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
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
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
        [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
            if (success) {
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
            }
        }];
        [view deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)setNote:(BENote *)note
{
    _note = note;
    if (self.isViewLoaded) {
        [tableView reloadData];
        if (self.numberOfRows) {
            tableView.hidden = NO;
        } else {
            tableView.hidden = YES;
        }
    }
}

- (void)onDateButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
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
    }];
}

- (void)onMapButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                [UIDevice openInMaps:cell.text];
            }
        }
    }];
}

- (void)onGoogleMapsButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                [UIDevice openInGoogleMaps:cell.text];
            }
        }
    }];
}

- (void)onEmailButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                [[UIApplication sharedApplication] openURL:cell.URL];
            }
        }
    }];
}

- (void)onChromeButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                [UIDevice openInChrome:cell.URL createNewTab:YES];
            }
        }
    }];
}

- (void)onSafariButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                [[UIApplication sharedApplication] openURL:cell.URL];
            }
        }
    }];
}

- (void)onCallButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", cell.phoneNumber]];
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }];
}

- (void)onMessageButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", cell.phoneNumber]];
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }];
}

- (void)onContactButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                @synchronized(self) {
                    [self.delegate noteSheet:self contact:self.note];
                }
            }
        }
    }];
}

- (BENoteSheetTableViewCell *)parentCell:(UIButton *)button
{
    UIView *view = button;
    while(view) {
        if([view isKindOfClass:[BENoteSheetTableViewCell class]]) {
            return (BENoteSheetTableViewCell *)view;
        }
        view = view.superview;
    }
    return nil;
}

@end
