//
//  BENoteTableController.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>

#import "BESidePanel.h"
#import "BENoteTableViewCell.h"
#import "BETouchableView.h"


@interface BENoteTableSection : NSObject
@property (nonatomic) NSInteger count;
@property (nonatomic) NSDate *date;
@end


@interface BENoteTableController : BESidePanel<UITableViewDelegate,
                                               UITableViewDataSource,
                                               UINavigationControllerDelegate,
                                               BENoteTableViewCellDelegate,
                                               BETouchableViewDelegate>
{
    UITableView *_tableView;
    BETouchableView *_tableViewMask;
    NSString *tableSectionQuery;
    NSString *tableSectionCountQuery;
    NSInteger tableSectionCount;
    NSInteger noteQueryPageSize;
    NSInteger tableSectionQueryPageSize;

    void (^navigationControllerPushCompletion)(BOOL finished);
}

@property (nonatomic, strong) NSMutableDictionary *notes;
@property (nonatomic, strong) NSMutableArray *tableSections;
@property (nonatomic, readonly) NSDictionary *noteQueryParameters;

- (void)refreshCache;
- (BENote *)noteForIndexPath:(NSIndexPath *)indexPath;
- (UITableViewHeaderFooterView *)tableViewHeader:(UITableView *)tableView;
- (void)removeNoteForIndexPath:(NSIndexPath *)indexPath;

@end
