#import <UIKit/UIKit.h>
#import "PreenNote.h"


@protocol PreenNoteTableViewCellDelegate;


@interface PreenNoteTableViewCell : UITableViewCell<UIGestureRecognizerDelegate>

+ (CGFloat)preferredHeight;

@property (nonatomic) PreenNote *note;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) BOOL canDelete;
@property (nonatomic) BOOL canArchive;
@property (nonatomic) NSString *archiveButtonTitle;
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic, readonly) BOOL showingControls;
@property (unsafe_unretained, nonatomic) id<PreenNoteTableViewCellDelegate> delegate;

- (void)showDeleteConfirmationAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;
- (void)showArchiveConfirmationAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;
- (void)hideControlsAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;

@end


@protocol PreenNoteTableViewCellDelegate

- (void)cellWillShowControls:(PreenNoteTableViewCell *)cell;
- (void)cellDidHideControls:(PreenNoteTableViewCell *)cell;

- (void)cellWillShowDeleteConfirmation:(PreenNoteTableViewCell *)cell;
- (void)cellDidHideDeleteConfirmation:(PreenNoteTableViewCell *)cell;
- (void)cellDeleteConfirmation:(PreenNoteTableViewCell *)cell;

- (void)cellWillShowArchiveConfirmation:(PreenNoteTableViewCell *)cell;
- (void)cellDidHideArchiveConfirmation:(PreenNoteTableViewCell *)cell;
- (void)cellArchiveConfirmation:(PreenNoteTableViewCell *)cell;

@end