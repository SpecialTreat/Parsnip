//
//  BECroppableImageView.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>


@interface BECroppableImageView : UIView

@property (nonatomic) UIImage *image;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGFloat maskAlpha;
@property (nonatomic) CGFloat zoomStep;
@property (nonatomic) CGFloat zoomMargin;
@property (nonatomic) CGFloat maximumZoomScale;
@property (nonatomic) BOOL symmetrical;
@property (nonatomic, readonly) CGRect selectedFrame;
@property (nonatomic, readonly) CGRect cropFrame;
@property (nonatomic, readonly) CGPoint imageOffset;
@property (nonatomic, readonly) CGFloat imageScale;
@property (nonatomic, readonly) CGFloat imageRotation;
@property (nonatomic, readonly) CGAffineTransform imageTransform;

- (UIImage *)getCroppedImage;

@end
