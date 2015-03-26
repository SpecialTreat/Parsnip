//
//  BEInboxController.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEInboxController.h"

#import "BEDB.h"
#import "BEInfoController.h"
#import "BEUI.h"
#import "UIViewController+Tools.h"


@implementation BEInboxController
{
    UIBarButtonItem *infoButton;
}

static NSString *archiveCellIdentifier = @"ArchiveCell";
static NSArray *archiveCellThemeKey;
static NSString *archiveCellText;
static UIEdgeInsets archiveCellSeparatorInset;
static NSString *inboxTitle;
static NSString *noteCellArchiveButtonTitle;

+ (void)initialize
{
    archiveCellThemeKey = @[@"NoteTableArchiveCell", @"TableCell"];
    archiveCellText = [BEUI.theme stringForKey:@"ArchiveTable.Title"];
    archiveCellSeparatorInset = [BEUI.theme edgeInsetsForKey:archiveCellThemeKey withSubkey:@"SeparatorInset"];
    inboxTitle = [BEUI.theme stringForKey:@"Inbox.Title"];
    noteCellArchiveButtonTitle = [BEUI.theme stringForKey:@"Inbox.ArchiveButtonTitle"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = inboxTitle;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    infoButton = [BEUI barButtonItemWithKey:@[@"NavigationBarSettingsButton", @"NavigationBarButton"] target:self action:@selector(onInfoButtonTouch)];
    [self setRightBarButtonItem:infoButton animated:NO];
}

- (NSDictionary *)noteQueryParameters
{
    return @{BENote.propertyToColumnMap[@"archived"]: [NSNumber numberWithBool:NO]};
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= tableSectionCount) {
        return 1;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [super numberOfSectionsInTableView:tableView] + 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section >= tableSectionCount) {
        return [self tableViewHeader:tableView];
    } else {
        return [super tableView:tableView viewForHeaderInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= tableSectionCount) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:archiveCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:archiveCellIdentifier];
            cell.backgroundColor = [BEUI.theme colorForKey:archiveCellThemeKey withSubkey:@"BackgroundColor" withDefault:[UIColor whiteColor]];
            cell.selectedBackgroundView = [[UIView alloc] init];
            cell.selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            cell.selectedBackgroundView.backgroundColor = [BEUI.theme colorForKey:archiveCellThemeKey withSubkey:@"SelectedBackgroundColor"];
            cell.imageView.image = [BEUI.theme imageForKey:archiveCellThemeKey withSubkey:@"Image"];
            cell.textLabel.text = archiveCellText;
            cell.textLabel.textColor = [BEUI.theme colorForKey:archiveCellThemeKey withSubkey:@"TextColor"];
            cell.textLabel.highlightedTextColor = [BEUI.theme colorForKey:archiveCellThemeKey withSubkey:@"SelectedTextColor"];
            cell.textLabel.font = [BEUI.theme fontForKey:archiveCellThemeKey withSubkey:@"TextFont"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[BEUI.theme imageForKey:@"TableCellAccessory.Image"]
                                                   highlightedImage:[BEUI.theme imageForKey:@"TableCellAccessory.SelectedImage"]];
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                cell.separatorInset = archiveCellSeparatorInset;
            }
        }
        return cell;
    } else {
        BENoteTableViewCell *cell = (BENoteTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        cell.archiveButtonTitle = noteCellArchiveButtonTitle;
        return cell;
    }
}

- (void)onInfoButtonTouch
{
    BEInfoController *infoController = [[BEInfoController alloc] init];
    [self.navigationController pushViewController:infoController animated:YES];
}

- (void)cellArchiveConfirmation:(BENoteTableViewCell *)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    BENote *note = [self noteForIndexPath:indexPath];
    note.archived = YES;
    note.userSaved = YES;
    if([BEDB save:note]) {
        [self removeNoteForIndexPath:indexPath];
        _tableViewMask.hidden = YES;
    } else {
        [cell hideControlsAnimated:YES completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= tableSectionCount) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        BENoteTableController *noteTableController = [[BENoteTableController alloc] init];
        [self.navigationController pushViewController:noteTableController animated:YES];
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

@end
