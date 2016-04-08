//
//  BENoteSheetController.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BENoteSheetController.h"

#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+Tools.h"
#import "BEAlertView.h"
#import "BEInAppPurchaser.h"
#import "BENoteSheetTableViewCell.h"
#import "BETextDataDetector.h"
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

- (CGSize)preferredContentSize
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
    NSUInteger vCardCount = self.note.vCardCount;

    NSUInteger count = 1;
    if (vCardCount > 0) {
        count = vCardCount;
    }
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
        NSUInteger vCardCount = self.note.vCardCount;
        if (vCardCount > 0) {
            return vCardCount;
        } else {
            return 1;
        }
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

- (NSString *)extractVCardName:(NSString *)vCard
{
    NSError *error = nil;
    NSRange range = NSMakeRange(0, vCard.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^FN:(.*)$"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:vCard options:0 range:range];
    if (match && [match rangeAtIndex:1].location != NSNotFound) {
        NSRange nameRange = [match rangeAtIndex:1];
        NSString *name = [vCard substringWithRange:nameRange];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"; "]];
        return name;
    }

    range = NSMakeRange(0, vCard.length);
    regex = [NSRegularExpression regularExpressionWithPattern:@"^N:(.*)$"
                                                      options:NSRegularExpressionAnchorsMatchLines
                                                        error:&error];
    match = [regex firstMatchInString:vCard options:0 range:range];
    if (match && [match rangeAtIndex:1].location != NSNotFound) {
        NSRange nameRange = [match rangeAtIndex:1];
        NSString *name = [vCard substringWithRange:nameRange];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"; "]];
        name = [name removeRepeats:@";"];
        name = [name stringByReplacingOccurrencesOfString:@";" withString:@", "];
        return name;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)view cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BENoteSheetTableViewCell *cell;
    if (indexPath.section == 0) {
        NSArray *vCards = self.note.vCards;
        if (vCards && vCards.count) {
            NSString *vCard = vCards[indexPath.row];
            NSString *name = [self extractVCardName:vCard];
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"VCard";
            if (name) {
                cell.text = [NSString stringWithFormat:@"Add Contact \"%@\"", name];
            } else {
                cell.text = [NSString stringWithFormat:@"Add Contact"];
            }
            cell.vCard = vCard;
            [cell addButtonWithKey:@"NoteSheetTableCellContactButton"
                            target:self
                            action:@selector(onVCardButtonTouch:event:)];
        } else {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.type = @"Contact";
            cell.text = @"Add Contact";

            [cell addButtonWithKey:@"NoteSheetTableCellContactButton"
                            target:self
                            action:@selector(onContactButtonTouch:event:)];
        }
    } else if (indexPath.section == 1) {
        BETextData *textData = self.note.dataTypes[@"PhoneNumber"][indexPath.row];
        if (textData) {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.textData = textData;
            cell.type = @"PhoneNumber";
            cell.text = textData.matchedText;
            cell.phoneNumber = textData.components[0];
            
            [cell addButtonWithKey:@"NoteSheetTableCellCallButton"
                            target:self
                            action:@selector(onCallButtonTouch:event:)];

            [cell addButtonWithKey:@"NoteSheetTableCellMessageButton"
                            target:self
                            action:@selector(onMessageButtonTouch:event:)];
        }
    } else if (indexPath.section == 2) {
        BETextData *textData = self.note.dataTypes[@"Address"][indexPath.row];
        if (textData) {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.textData = textData;
            cell.type = @"Address";
            cell.text = textData.matchedText;
            cell.addressComponents = textData.components[0];

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
        BETextData *textData = self.note.dataTypes[@"Email"][indexPath.row];
        if (textData) {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.textData = textData;
            cell.type = @"Email";
            cell.text = textData.matchedText;
            cell.email = textData.components[0];

            [cell addButtonWithKey:@"NoteSheetTableCellEmailButton"
                            target:self
                            action:@selector(onEmailButtonTouch:event:)];
        }
    } else if (indexPath.section == 4) {
        BETextData *textData = self.note.dataTypes[@"URL"][indexPath.row];
        if (textData) {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.textData = textData;
            cell.type = @"URL";
            cell.text = textData.matchedText;
            cell.URL = textData.components[0];

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
        BETextData *textData = self.note.dataTypes[@"Date"][indexPath.row];
        if (textData) {
            cell = [[BENoteSheetTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.textData = textData;
            cell.type = @"Date";
            cell.text = textData.matchedText;
            cell.date = textData.components[0];
            cell.duration = [textData.components[1] doubleValue];
            cell.timeZone = textData.components[2];

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
                    NSArray *vCards = self.note.vCards;
                    if (vCards && vCards.count) {
                        [self.delegate noteSheet:self contact:self.note vCard:vCards[indexPath.row]];
                    } else {
                        [self.delegate noteSheet:self contact:self.note];
                    }
                } else if (indexPath.section == 1) {
                    BETextData *textData = self.note.dataTypes[@"PhoneNumber"][indexPath.row];
                    [self.delegate noteSheet:self contact:self.note textData:textData];
                } else if (indexPath.section == 2) {
                    BETextData *textData = self.note.dataTypes[@"Address"][indexPath.row];
                    [self.delegate noteSheet:self contact:self.note textData:textData];
                } else if (indexPath.section == 3) {
                    BETextData *textData = self.note.dataTypes[@"Email"][indexPath.row];
                    [self.delegate noteSheet:self contact:self.note textData:textData];
                } else if (indexPath.section == 4) {
                    BETextData *textData = self.note.dataTypes[@"URL"][indexPath.row];
                    [self.delegate noteSheet:self contact:self.note textData:textData];
                } else if (indexPath.section == 5) {
                    BETextData *textData = self.note.dataTypes[@"Date"][indexPath.row];
                    [self.delegate noteSheet:self calendar:self.note textData:textData];
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
                @synchronized(self) {
                    [self.delegate noteSheet:self calendar:self.note textData:cell.textData];
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
                [[UIApplication sharedApplication] openURL:cell.email];
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

- (void)onVCardButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    [BEInAppPurchaser.parsnipPurchaser checkForProduct:BEInAppPurchaserParsnipPro completion:^(BOOL success) {
        if (success) {
            BENoteSheetTableViewCell *cell = [self parentCell:sender];
            if(cell) {
                @synchronized(self) {
                    [self.delegate noteSheet:self contact:self.note vCard:cell.vCard];
                }
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
