#import <UIKit/UIKit.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "PreenAlertView.h"
#import "PreenBaseController.h"
#import "PreenNote.h"
#import "PreenNoteSheetController.h"
#import "PreenPopoverController.h"
#import "PreenScannerView.h"


@interface PreenNoteController : PreenBaseController<UITextViewDelegate,
                                                     PreenPopoverControllerDelegate,
                                                     EKEventEditViewDelegate,
                                                     ABUnknownPersonViewControllerDelegate,
                                                     PreenNoteSheetControllerDelegate,
                                                     PreenTouchableViewDelegate,
                                                     UINavigationControllerDelegate>

@property (nonatomic) PreenNote *note;
@property (nonatomic, strong) PreenPopoverController *popover;
@property (nonatomic, readonly) BOOL isDirty;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIView *imageViewBackground;
@property (nonatomic, readonly) PreenScannerView *scannerView;

- (BOOL)isImageLetterboxed:(UIImage *)image inFrame:(CGRect)frame;
- (void)layoutForImage:(UIImage *)image inFrame:(CGRect)frame;
- (CGRect)frameForImage:(UIImage *)image inFrame:(CGRect)frame;
- (CGRect)frameForTextView;
- (void)ocr:(PreenNote *)value;

- (void)popoverControllerDidDismissPopover:(PreenPopoverController *)popoverController;
- (BOOL)popoverControllerShouldDismissPopover:(PreenPopoverController *)popoverController;

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action;
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller;

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView
                 didResolveToPerson:(ABRecordRef)person;

- (void)noteSheet:(PreenNoteSheetController *)controller keep:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller copy:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller archive:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller discard:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller contact:(PreenNote *)note;
- (void)noteSheet:(PreenNoteSheetController *)controller
         calendar:(PreenNote *)note
             text:(NSString *)text
             date:(NSDate *)date
         duration:(NSTimeInterval)duration
         timeZone:(NSTimeZone *)timeZone;
- (void)noteSheet:(PreenNoteSheetController *)controller
          contact:(PreenNote *)note
             text:(NSString *)text
      phoneNumber:(NSString *)phoneNumber;

@end
