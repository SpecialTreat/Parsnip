#import <UIKit/UIKit.h>

#import "BENote.h"
#import "BETextData.h"


@protocol BENoteSheetControllerDelegate;


@interface BENoteSheetController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BENote *note;
@property (unsafe_unretained, nonatomic) id<BENoteSheetControllerDelegate> delegate;

- (CGSize)preferredSize;

@end

@protocol BENoteSheetControllerDelegate

- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
         textData:(BETextData *)textData;
- (void)noteSheet:(BENoteSheetController *)controller
         calendar:(BENote *)note
         textData:(BETextData *)textData;
@end
