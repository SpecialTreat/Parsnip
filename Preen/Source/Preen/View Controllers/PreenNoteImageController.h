#import <UIKit/UIKit.h>
#import "PreenBaseController.h"
#import "PreenNote.h"


@interface PreenNoteImageController : PreenBaseController<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) PreenNote *note;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIView *cropViewContainer;
@property (nonatomic, readonly) UIImageView *cropView;
@property (nonatomic, readonly) UIView *spotlightView;
@property (nonatomic, readonly) UIView *toolbar;
@property (nonatomic, readonly) UIEdgeInsets scrollContentInset;
@property (nonatomic, readonly) CGRect scrollContentFrame;

@end
