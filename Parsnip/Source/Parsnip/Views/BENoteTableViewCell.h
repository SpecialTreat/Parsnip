#import <UIKit/UIKit.h>
#import "BENote.h"


@protocol BENoteTableViewCellDelegate;


@interface BENoteTableViewCell : UITableViewCell<UIGestureRecognizerDelegate>

+ (CGFloat)preferredHeight;

@property (nonatomic) BENote *note;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) BOOL canDelete;
@property (nonatomic) BOOL canArchive;
@property (nonatomic) NSString *archiveButtonTitle;
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic, readonly) BOOL showingControls;
@property (unsafe_unretained, nonatomic) id<BENoteTableViewCellDelegate> delegate;

- (void)showDeleteConfirmationAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;
- (void)showArchiveConfirmationAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;
- (void)hideControlsAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;

@end


@protocol BENoteTableViewCellDelegate

- (void)cellWillShowControls:(BENoteTableViewCell *)cell;
- (void)cellDidHideControls:(BENoteTableViewCell *)cell;

- (void)cellWillShowDeleteConfirmation:(BENoteTableViewCell *)cell;
- (void)cellDidHideDeleteConfirmation:(BENoteTableViewCell *)cell;
- (void)cellDeleteConfirmation:(BENoteTableViewCell *)cell;

- (void)cellWillShowArchiveConfirmation:(BENoteTableViewCell *)cell;
- (void)cellDidHideArchiveConfirmation:(BENoteTableViewCell *)cell;
- (void)cellArchiveConfirmation:(BENoteTableViewCell *)cell;

@end