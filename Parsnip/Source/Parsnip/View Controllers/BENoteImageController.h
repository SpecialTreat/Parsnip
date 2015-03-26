//
//  BENoteImageController.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>
#import "BEBaseController.h"
#import "BENote.h"


@interface BENoteImageController : BEBaseController<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) BENote *note;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIView *cropViewContainer;
@property (nonatomic, readonly) UIImageView *cropView;
@property (nonatomic, readonly) UIView *spotlightView;
@property (nonatomic, readonly) UIView *toolbar;
@property (nonatomic, readonly) UIEdgeInsets scrollContentInset;
@property (nonatomic, readonly) CGRect scrollContentFrame;

@end
