#import "PreenInfoController.h"

#import "PreenDB.h"
#import "PreenUI.h"


@implementation PreenInfoController

static NSString *archiveCellIdentifier = @"ArchiveCell";
static NSArray *archiveCellThemeKey;
static NSString *archiveCellText;
static UIEdgeInsets archiveCellSeparatorInset;
static NSString *infoTableTitle;
static NSString *noteCellArchiveButtonTitle;

+ (void)initialize
{
    archiveCellThemeKey = @[@"NoteTableArchiveCell", @"TableCell"];
    archiveCellText = [PreenUI.theme stringForKey:@"ArchiveTable.Title"];
    archiveCellSeparatorInset = [PreenUI.theme edgeInsetsForKey:archiveCellThemeKey withSubkey:@"SeparatorInset"];
    infoTableTitle = [PreenUI.theme stringForKey:@"InfoTable.Title"];
    noteCellArchiveButtonTitle = [PreenUI.theme stringForKey:@"InfoTable.ArchiveButtonTitle"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = infoTableTitle;
    }
    return self;
}

- (NSDictionary *)noteQueryParameters
{
    return @{PreenNote.propertyToColumnMap[@"archived"]: [NSNumber numberWithBool:NO]};
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
            cell.backgroundColor = [PreenUI.theme colorForKey:archiveCellThemeKey withSubkey:@"BackgroundColor" withDefault:[UIColor whiteColor]];
            cell.selectedBackgroundView = [[UIView alloc] init];
            cell.selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            cell.selectedBackgroundView.backgroundColor = [PreenUI.theme colorForKey:archiveCellThemeKey withSubkey:@"SelectedBackgroundColor"];
            cell.imageView.image = [PreenUI.theme imageForKey:archiveCellThemeKey withSubkey:@"Image"];
            cell.textLabel.text = archiveCellText;
            cell.textLabel.textColor = [PreenUI.theme colorForKey:archiveCellThemeKey withSubkey:@"TextColor"];
            cell.textLabel.highlightedTextColor = [PreenUI.theme colorForKey:archiveCellThemeKey withSubkey:@"SelectedTextColor"];
            cell.textLabel.font = [PreenUI.theme fontForKey:archiveCellThemeKey withSubkey:@"TextFont"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[PreenUI.theme imageForKey:@"TableCellAccessory.Image"]
                                                   highlightedImage:[PreenUI.theme imageForKey:@"TableCellAccessory.SelectedImage"]];
            if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
                cell.separatorInset = archiveCellSeparatorInset;
            }
        }
        return cell;
    } else {
        PreenNoteTableViewCell *cell = (PreenNoteTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        cell.archiveButtonTitle = noteCellArchiveButtonTitle;
        return cell;
    }
}

- (void)cellArchiveConfirmation:(PreenNoteTableViewCell *)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    PreenNote *note = [self noteForIndexPath:indexPath];
    note.archived = YES;
    note.userSaved = YES;
    if([PreenDB save:note]) {
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
        PreenNoteTableController *noteTableController = [[PreenNoteTableController alloc] init];
        [self.navigationController pushViewController:noteTableController animated:YES];
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

@end
