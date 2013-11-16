#import <UIKit/UIKit.h>

#import "PreenNote.h"


@protocol PreenNoteSheetControllerDelegate;


@interface PreenNoteSheetController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) PreenNote *note;
@property (unsafe_unretained, nonatomic) id<PreenNoteSheetControllerDelegate> delegate;

- (CGSize)preferredSize;

@end

@protocol PreenNoteSheetControllerDelegate
@optional
- (void)noteSheet:(PreenNoteSheetController *)controller keep:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller copy:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller archive:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller unarchive:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller discard:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller
         calendar:(PreenNote *)note
             text:(NSString *)text
             date:(NSDate *)date
         duration:(NSTimeInterval)duration
         timeZone:(NSTimeZone *)timeZone;
- (void)noteSheet:(PreenNoteSheetController *)controller
          contact:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller
          contact:(PreenNote *)note
             text:(NSString *)text
      phoneNumber:(NSString *)phoneNumber;
- (void)noteSheet:(PreenNoteSheetController *)controller
          contact:(PreenNote *)note
             text:(NSString *)text
              url:(NSURL *)url;
- (void)noteSheet:(PreenNoteSheetController *)controller
          contact:(PreenNote *)note
             text:(NSString *)text
            email:(NSURL *)email;
- (void)noteSheet:(PreenNoteSheetController *)controller
          contact:(PreenNote *)note
             text:(NSString *)text
          address:(NSDictionary *)components;

@end
