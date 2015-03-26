//
//  UIImage+Tesseract.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>
#import "allheaders.h"
#import "baseapi.h"
#import "environ.h"
#import "imageio.h"


@interface UIImage (Pix)

- (UIImage *)otsuThreshold;

/**
 * Must call pixFreeData(pix) and free(pix) on returned (Pix *).
 */
//- (Pix *)pix;

+ (UIImage *)imageFromPix:(Pix *)pix;
+ (UIImage *)imageFrom1bppPix:(Pix *)pix;

@end
