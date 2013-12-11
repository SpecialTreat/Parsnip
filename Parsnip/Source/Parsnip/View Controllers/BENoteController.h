#import <UIKit/UIKit.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "BEAlertView.h"
#import "BEBaseController.h"
#import "BENote.h"
#import "BENoteSheetController.h"
#import "BEPopoverController.h"
#import "BEScannerView.h"
#import "BETextData.h"


@interface BENoteController : BEBaseController<UITextViewDelegate,
                                                     BEPopoverControllerDelegate,
                                                     EKEventEditViewDelegate,
                                                     ABUnknownPersonViewControllerDelegate,
                                                     BENoteSheetControllerDelegate,
                                                     BETouchableViewDelegate,
                                                     UINavigationControllerDelegate>

@property (nonatomic) BENote *note;
@property (nonatomic, strong) BEPopoverController *popover;
@property (nonatomic, readonly) BOOL isDirty;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIView *imageViewBackground;
@property (nonatomic, readonly) BEScannerView *scannerView;

- (BOOL)isImageLetterboxed:(UIImage *)image inFrame:(CGRect)frame;
- (void)layoutForImage:(UIImage *)image inFrame:(CGRect)frame;
- (CGRect)frameForImage:(UIImage *)image inFrame:(CGRect)frame;
- (void)ocr:(BENote *)value;

- (void)popoverControllerDidDismissPopover:(BEPopoverController *)popoverController;
- (BOOL)popoverControllerShouldDismissPopover:(BEPopoverController *)popoverController;

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action;
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller;

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView
                 didResolveToPerson:(ABRecordRef)person;

- (void)noteSheet:(BENoteSheetController *)controller contact:(BENote *)note;
- (void)noteSheet:(BENoteSheetController *)controller
         calendar:(BENote *)note
         textData:(BETextData *)textData;
- (void)noteSheet:(BENoteSheetController *)controller
          contact:(BENote *)note
         textData:(BETextData *)textData;

@end
