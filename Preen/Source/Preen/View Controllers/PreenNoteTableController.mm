#import "PreenNoteTableController.h"

#import <QuartzCore/QuartzCore.h>
#import "JASidePanelController.h"
#import "NSString+Tools.h"
#import "PreenDB.h"
#import "PreenNote.h"
#import "PreenNoteController.h"
#import "PreenUI.h"
#import "UIColor+Tools.h"
#import "UIViewController+JASidePanel.h"
#import "UIViewController+Tools.h"
#import "UIView+Tools.h"


@implementation PreenNoteTableSection
@end

@implementation PreenNoteTableKey

+ (PreenNoteTableKey *)keyWithDate:(NSDate *)date row:(NSInteger)row
{
    PreenNoteTableKey *key = [[PreenNoteTableKey alloc] init];
    key.date = date;
    key.row = row;
    return key;
}

- (BOOL)isEqual:(id)object
{
    if (!object) {
        return NO;
    }
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    return [self.date isEqualToDate:[object date]] && (self.row == [object row]);
}

- (NSUInteger)hash
{
    NSNumber *date = [NSNumber numberWithInteger:self.date.timeIntervalSince1970];
    NSNumber *row = [NSNumber numberWithInteger:self.row];
    NSString *hashString = [NSString stringWithFormat:@"%@.%@", date, row];
    return [hashString hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    PreenNoteTableKey *key = [[PreenNoteTableKey alloc] init];
    key.date = [self.date copyWithZone:zone];
    key.row = self.row;
    return key;
}

@end


@implementation PreenNoteTableController

static NSDateFormatter *dateToStringFormatter;
static NSDateFormatter *stringToDateFormatter;
static NSCalendar *calendar;
static NSString *noteTableCellIdentifier = @"NoteTableCell";
static NSString *noteTableTitle;
static NSString *noteTableArchiveButtonTitle;
static NSString *tableSectionHeaderIdentifier = @"SectionHeader";
static NSArray *tableSectionHeaderThemeKey;
static CGFloat tableSectionHeaderHeight;
static UIEdgeInsets tableSectionHeaderPadding;

+ (void)initialize
{
    tableSectionHeaderThemeKey = @[@"NoteTableSectionHeader", @"TableSectionHeader"];
    tableSectionHeaderHeight = [PreenUI.theme floatForKey:tableSectionHeaderThemeKey withSubkey:@"Height"];
    tableSectionHeaderPadding = [PreenUI.theme edgeInsetsForKey:tableSectionHeaderThemeKey withSubkey:@"Padding"];

    noteTableTitle = [PreenUI.theme stringForKey:@"ArchiveTable.Title"];
    noteTableArchiveButtonTitle = [PreenUI.theme stringForKey:@"NoteTable.ArchiveButtonTitle"];

    stringToDateFormatter = [[NSDateFormatter alloc] init];
    [stringToDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];

    dateToStringFormatter = [[NSDateFormatter alloc] init];
    [dateToStringFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateToStringFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateToStringFormatter setDoesRelativeDateFormatting:YES];

    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
}

@synthesize notes = _notes;
@synthesize tableSections = _tableSections;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        noteQueryPageSize = MAX(20, 3.0f * ([UIScreen mainScreen].bounds.size.height / PreenNoteTableViewCell.preferredHeight));
        tableSectionQueryPageSize = noteQueryPageSize / 2;
        statusBarHidden = YES;

        tableSectionQuery = [self getTableSectionQuery];
        tableSectionCountQuery = [self getTableSectionCountQuery];
        _tableSections = [NSMutableArray array];
        _notes = [[NSCache alloc] init];

        self.title = noteTableTitle;
        self.manuallyAdjustsViewInsets = YES;
    }
    return self;
}

- (void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
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
    _tableView = [[UITableView alloc] initWithFrame:frame];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.separatorColor = [PreenUI.theme colorForKey:@[@"NoteTable", @"Table"] withSubkey:@"SeparatorColor"];
    _tableView.rowHeight = [PreenNoteTableViewCell preferredHeight];
    _tableView.delegate = self;
    _tableView.dataSource = self;

    _tableViewMask = [[PreenTouchableView alloc]initWithFrame:frame];
    _tableViewMask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableViewMask.hidden = YES;
    _tableViewMask.delegate = self;

    [self.view addSubview:_tableView];
    [self.view addSubview:_tableViewMask];
}

- (BOOL)prefersStatusBarHidden
{
    return statusBarHidden;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSDictionary *)noteQueryParameters
{
    return @{PreenNote.propertyToColumnMap[@"archived"]: [NSNumber numberWithBool:YES]};
}

- (NSString *)getTableSectionQuery
{
    NSDictionary *query = self.noteQueryParameters;
    NSString *dateColumn = PreenNote.propertyToColumnMap[@"croppedImageTimestamp"];
    NSString *select = @"SELECT count(%@) as count, strftime('%%Y-%%m-%%d', datetime(%@, 'unixepoch', 'localtime')) as day";
    select = [NSString stringWithFormat:select, PreenNote.primaryKey, dateColumn];
    NSString *from = [NSString stringWithFormat:@"FROM %@", PreenNote.table];
    NSString *groupBy = [NSString stringWithFormat:@"GROUP BY %@", @"day"];
    NSString *orderBy = [NSString stringWithFormat:@"ORDER BY %@ desc", @"day"];
    NSString *limit = @"LIMIT :limit OFFSET :offset";
    if (query.count) {
        NSString *columns = [[query allKeys] componentsJoinedByString:@", "];
        select = [NSString stringWithFormat:@"%@, %@", select, columns];
        groupBy = [NSString stringWithFormat:@"%@, %@", groupBy, columns];
        NSMutableArray *whereParts = [NSMutableArray array];
        for (NSString *column in query) {
            [whereParts addObject:[NSString stringWithFormat:@"%@ = :%@", column, column]];
        }
        NSString *where = [NSString stringWithFormat:@"WHERE %@", [whereParts componentsJoinedByString:@" AND "]];
        return [@[select, from, where, groupBy, orderBy, limit] componentsJoinedByString:@"\n"];
    } else {
        return [@[select, from, groupBy, orderBy, limit] componentsJoinedByString:@"\n"];
    }
}

- (NSString *)getTableSectionCountQuery
{
    NSDictionary *query = self.noteQueryParameters;
    NSString *dateColumn = PreenNote.propertyToColumnMap[@"croppedImageTimestamp"];
    NSString *select = [NSString stringWithFormat:@"SELECT COUNT(DISTINCT strftime('%%Y-%%m-%%d', datetime(%@, 'unixepoch', 'localtime'))) as count", dateColumn];
    NSString *from = [NSString stringWithFormat:@"FROM %@", PreenNote.table];
    if (query.count) {
        NSMutableArray *whereParts = [NSMutableArray array];
        for (NSString *column in query) {
            [whereParts addObject:[NSString stringWithFormat:@"%@ = :%@", column, column]];
        }
        NSString *where = [NSString stringWithFormat:@"WHERE %@", [whereParts componentsJoinedByString:@" AND "]];
        return [@[select, from, where] componentsJoinedByString:@"\n"];
    } else {
        return [@[select, from] componentsJoinedByString:@"\n"];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    UIEdgeInsets insets = [self insetsForViewStatusBarHidden:YES];
    _tableView.contentInset = insets;
    _tableView.scrollIndicatorInsets = insets;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    UIEdgeInsets insets = [self insetsForViewStatusBarHidden:YES];
    _tableView.contentInset = insets;
    _tableView.scrollIndicatorInsets = insets;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIEdgeInsets insets = [self insetsForViewStatusBarHidden:YES];
    _tableView.contentInset = insets;
    _tableView.scrollIndicatorInsets = insets;
    statusBarHidden = ([UIApplication sharedApplication].statusBarHidden ||
                       (self.sidePanelController.visiblePanel != self.navigationController));

    [self refreshCache];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    statusBarHidden = YES;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    statusBarHidden = ([UIApplication sharedApplication].statusBarHidden ||
                       (self.sidePanelController.visiblePanel != self.navigationController));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)refreshCache
{
    [self.notes removeAllObjects];
    [self.tableSections removeAllObjects];
    tableSectionCount = [PreenDB count:tableSectionCountQuery parameters:self.noteQueryParameters];
    for (int i = 0; i < tableSectionCount; i++) {
        self.tableSections[i] = [NSNull null];
    }
    [_tableView reloadData];
}

- (PreenNoteTableSection *)tableSection:(NSInteger)section
{
    id value = self.tableSections[section];
    if (value == [NSNull null]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.noteQueryParameters];
        parameters[@"limit"] = [NSNumber numberWithInteger:tableSectionQueryPageSize];
        parameters[@"offset"] = [NSNumber numberWithInteger:section];

        [PreenDB query:tableSectionQuery parameters:parameters results:^(FMResultSet *results) {
            NSInteger row = 0;
            while ([results next]) {
                PreenNoteTableSection *tableSection = [[PreenNoteTableSection alloc] init];
                tableSection.count = [results intForColumn:@"count"];
                tableSection.date = [stringToDateFormatter dateFromString:[results stringForColumn:@"day"]];
                [self.tableSections insertObject:tableSection atIndex:(section + row)];
                row++;
            }
        }];
        return self.tableSections[section];
    } else {
        return value;
    }
}

- (PreenNote *)noteForIndexPath:(NSIndexPath *)indexPath
{
    PreenNoteTableSection *section = [self tableSection:indexPath.section];
    PreenNoteTableKey *cacheKey = [PreenNoteTableKey keyWithDate:section.date row:indexPath.row];
    PreenNote *note = [self.notes objectForKey:cacheKey];
    if (note) {
        return note;
    } else {
        NSMutableDictionary *noteQuery = [NSMutableDictionary dictionaryWithDictionary:self.noteQueryParameters];
        NSString *dateColumn = PreenNote.propertyToColumnMap[@"croppedImageTimestamp"];
        noteQuery[dateColumn] = @[@"<", [cacheKey.date dateByAddingTimeInterval:(24 * 60 * 60)]];
        NSArray *notes = [PreenDB get:PreenNote.class parameters:noteQuery orderBy:dateColumn asc:NO limit:noteQueryPageSize offset:cacheKey.row];
        if (notes && notes.count) {
            NSInteger dateUnits = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
            note = notes[0];
            NSDate *currentDate = nil;
            NSInteger row = cacheKey.row;
            for (PreenNote *currentNote in notes) {
                NSDateComponents *components = [calendar components:dateUnits fromDate:currentNote.croppedImageTimestamp];
                NSDate *noteDate = [calendar dateFromComponents:components];
                if (!currentDate) {
                    currentDate = noteDate;
                }
                if (![currentDate isEqualToDate:noteDate]) {
                    currentDate = noteDate;
                    row = 0;
                }
                [self.notes setObject:currentNote forKey:[PreenNoteTableKey keyWithDate:currentDate row:row]];
                row++;
            }
            return note;
        } else {
            return nil;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self tableSection:section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return tableSectionCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return tableSectionHeaderHeight;
}

- (UITableViewHeaderFooterView *)tableViewHeader:(UITableView *)tableView
{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:tableSectionHeaderIdentifier];
    if (view) {
        UILabel *textLabel = view.contentView.subviews[0];
        textLabel.text = @"";
    } else {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:tableSectionHeaderIdentifier];
        view.backgroundView = [[UIImageView alloc] initWithImage:[PreenUI.theme imageForKey:tableSectionHeaderThemeKey withSubkey:@"BackgroundImage"]];

        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableSectionHeaderPadding.left, 0, 0, tableSectionHeaderHeight)];
        textLabel.backgroundColor = [PreenUI.theme colorForKey:tableSectionHeaderThemeKey withSubkey:@"BackgroundColor"];
        textLabel.textColor = [PreenUI.theme colorForKey:tableSectionHeaderThemeKey withSubkey:@"TextColor"];
        textLabel.highlightedTextColor = [PreenUI.theme colorForKey:tableSectionHeaderThemeKey withSubkey:@"SelectedTextColor"];
        textLabel.font = [PreenUI.theme fontForKey:tableSectionHeaderThemeKey withSubkey:@"Font"];
        [view.contentView insertSubview:textLabel atIndex:0];
    }
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *view = [self tableViewHeader:tableView];
    PreenNoteTableSection *tableSection = [self tableSection:section];
    NSDate *date = tableSection.date;
    UILabel *textLabel = view.contentView.subviews[0];
    textLabel.text = [dateToStringFormatter stringFromDate:date];
    [textLabel sizeToFit];
    CGRect textLabelFrame = textLabel.frame;
    textLabelFrame.size.height = tableSectionHeaderHeight;
    textLabel.frameAligned = textLabelFrame;

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreenNoteTableViewCell preferredHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PreenNoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noteTableCellIdentifier];
    if (!cell) {
        cell = [[PreenNoteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noteTableCellIdentifier];
        cell.archiveButtonTitle = noteTableArchiveButtonTitle;
        cell.canArchive = YES;
        cell.canDelete = YES;
        cell.delegate = self;
    }
    cell.note = [self noteForIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (navigationControllerPushCompletion) {
        navigationControllerPushCompletion(YES);
        navigationControllerPushCompletion = nil;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)cellWillShowControls:(PreenNoteTableViewCell *)cell
{
    _tableViewMask.passthroughViews = @[cell];
    _tableViewMask.hidden = NO;
}

- (void)cellDidHideControls:(PreenNoteTableViewCell *)cell
{
    _tableViewMask.hidden = YES;
}

- (void)cellWillShowDeleteConfirmation:(PreenNoteTableViewCell *)cell
{

}

- (void)cellDidHideDeleteConfirmation:(PreenNoteTableViewCell *)cell
{

}

- (void)cellDeleteConfirmation:(PreenNoteTableViewCell *)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    PreenNote *note = [self noteForIndexPath:indexPath];
    if([PreenDB remove:note]) {
        [self removeNoteForIndexPath:indexPath];
        _tableViewMask.hidden = YES;
    }
}

- (void)cellWillShowArchiveConfirmation:(PreenNoteTableViewCell *)cell
{

}

- (void)cellDidHideArchiveConfirmation:(PreenNoteTableViewCell *)cell
{

}

- (void)cellArchiveConfirmation:(PreenNoteTableViewCell *)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    PreenNote *note = [self noteForIndexPath:indexPath];
    note.archived = NO;
    note.userSaved = YES;
    if([PreenDB save:note]) {
        [self removeNoteForIndexPath:indexPath];
        _tableViewMask.hidden = YES;
    } else {
        [cell hideControlsAnimated:YES completion:nil];
    }
}

- (void)removeNoteForIndexPath:(NSIndexPath *)indexPath
{
    PreenNoteTableSection *section = [self tableSection:indexPath.section];
    section.count = MAX(0, section.count - 1);
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.notes removeObjectForKey:[PreenNoteTableKey keyWithDate:section.date row:indexPath.row]];
    if (!section.count) {
        [self.tableSections removeObjectAtIndex:indexPath.section];
        tableSectionCount--;
        [_tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)touchableViewOnTouch:(PreenTouchableView *)view
{
    for(UITableViewCell* cell in _tableView.visibleCells) {
        if (cell.editing) {
            [cell setEditing:NO animated:YES];
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.editing) {
        indexPath = nil;
        [cell setEditing:NO animated:YES];
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PreenNote *note = [self noteForIndexPath:indexPath];

    PreenNoteController *noteController = [[PreenNoteController alloc] init];
    [noteController view];
    noteController.note = note;
    noteController.imageView.hidden = YES;

    PreenNoteTableViewCell *cell = (PreenNoteTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    CGRect startFrame = [self.sidePanelController.navigationController.view convertRect:cell.imageView.frame fromView:cell];

    UIView *transitionContainer = [[UIView alloc] initWithFrame:startFrame];
    transitionContainer.clipsToBounds = YES;

    startFrame.origin.x = 0.0f;
    startFrame.origin.y = 0.0f;
    CGFloat width = startFrame.size.width;
    CGFloat height = startFrame.size.height;
    if ((note.croppedImage.size.width / note.croppedImage.size.height) < (width / height)) {
        startFrame.size.height = width * (note.croppedImage.size.height / note.croppedImage.size.width);
    } else {
        startFrame.size.width = height * (note.croppedImage.size.width / note.croppedImage.size.height);
    }

    UIImageView *transitionView = [[UIImageView alloc] initWithImage:note.croppedImage];
    transitionView.contentMode = UIViewContentModeScaleAspectFit;
    transitionView.frame = startFrame;
    [transitionContainer addSubview:transitionView];

    NSObject<UINavigationControllerDelegate> *navigationControllerDelegate = self.sidePanelController.navigationController.delegate;
    UINavigationController *navigationController = self.sidePanelController.navigationController;
    navigationControllerPushCompletion = ^(BOOL finished) {
        noteController.imageView.hidden = NO;
        [transitionContainer removeFromSuperview];
        navigationController.delegate = navigationControllerDelegate;
    };

    [self.sidePanelController.navigationController.view addSubview:transitionContainer];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        BOOL isStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        CGRect finishFrame = [self frameForViewStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:isStatusBarHidden withAnimation:UIStatusBarAnimationNone];
        finishFrame = [noteController frameForImage:note.croppedImage inFrame:finishFrame];
        transitionContainer.frame = finishFrame;
        finishFrame.origin.x = 0.0f;
        finishFrame.origin.y = 0.0f;
        transitionView.frame = finishFrame;
    } completion:nil];

    self.sidePanelController.navigationController.delegate = self;
    [self.sidePanelController.navigationController pushViewController:noteController animated:YES];
}

@end
