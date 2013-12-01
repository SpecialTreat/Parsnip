#import <UIKit/UIKit.h>

#import "BEBaseController.h"
#import "BENoteTableViewCell.h"
#import "BETouchableView.h"


@interface BENoteTableSection : NSObject
@property (nonatomic) NSInteger count;
@property (nonatomic) NSDate *date;
@end


@interface BENoteTableKey : NSObject<NSCopying>
+ (BENoteTableKey *)keyWithDate:(NSDate *)date row:(NSInteger)row;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSInteger row;
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
- (id)copyWithZone:(NSZone *)zone;
@end


@interface BENoteTableController : BEBaseController<UITableViewDelegate,
                                                          UITableViewDataSource,
                                                          UINavigationControllerDelegate,
                                                          BENoteTableViewCellDelegate,
                                                          BETouchableViewDelegate>
{
    UITableView *_tableView;
    BETouchableView *_tableViewMask;
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
- (BENote *)noteForIndexPath:(NSIndexPath *)indexPath;
- (UITableViewHeaderFooterView *)tableViewHeader:(UITableView *)tableView;
- (void)removeNoteForIndexPath:(NSIndexPath *)indexPath;

@end
