#import <UIKit/UIKit.h>

#import "PreenBaseController.h"
#import "PreenNoteTableViewCell.h"
#import "PreenTouchableView.h"


@interface PreenNoteTableSection : NSObject
@property (nonatomic) NSInteger count;
@property (nonatomic) NSDate *date;
@end


@interface PreenNoteTableKey : NSObject<NSCopying>
+ (PreenNoteTableKey *)keyWithDate:(NSDate *)date row:(NSInteger)row;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSInteger row;
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
- (id)copyWithZone:(NSZone *)zone;
@end


@interface PreenNoteTableController : PreenBaseController<UITableViewDelegate,
                                                          UITableViewDataSource,
                                                          UINavigationControllerDelegate,
                                                          PreenNoteTableViewCellDelegate,
                                                          PreenTouchableViewDelegate>
{
    UITableView *_tableView;
    PreenTouchableView *_tableViewMask;
    BOOL statusBarHidden;
    NSString *tableSectionQuery;
    NSString *tableSectionCountQuery;
    NSInteger tableSectionCount;
    NSInteger noteQueryPageSize;
    NSInteger tableSectionQueryPageSize;

    void (^navigationControllerPushCompletion)(BOOL finished);
}

@property (nonatomic, strong) NSCache *notes;
@property (nonatomic, strong) NSMutableArray *tableSections;
@property (nonatomic, readonly) NSDictionary *noteQueryParameters;

- (void)refreshCache;
- (PreenNote *)noteForIndexPath:(NSIndexPath *)indexPath;
- (UITableViewHeaderFooterView *)tableViewHeader:(UITableView *)tableView;
- (void)removeNoteForIndexPath:(NSIndexPath *)indexPath;

@end
