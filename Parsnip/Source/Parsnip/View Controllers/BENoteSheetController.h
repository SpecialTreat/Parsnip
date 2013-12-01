#import <UIKit/UIKit.h>

#import "BENote.h"


@protocol BENoteSheetControllerDelegate;


@interface BENoteSheetController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BENote *note;
@property (unsafe_unretained, nonatomic) id<BENoteSheetControllerDelegate> delegate;

- (CGSize)preferredSize;

@end

@protocol BENoteSheetControllerDelegate
@optional
- (void)noteSheet:(BENoteSheetController *)controller keep:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller copy:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller archive:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller unarchive:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller discard:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller
         calendar:(BENote *)note
             text:(NSString *)text
             date:(NSDate *)date
         duration:(NSTimeInterval)duration
         timeZone:(NSTimeZone *)timeZone;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
      phoneNumber:(NSString *)phoneNumber;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
              url:(NSURL *)url;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
            email:(NSURL *)email;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
             text:(NSString *)text
          address:(NSDictionary *)components;

@end
