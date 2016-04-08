//
//  UIImage+Tesseract.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>
#import <TesseractOCR/allheaders.h>
#import <TesseractOCR/baseapi.h>
#import <TesseractOCR/environ.h>
#import <TesseractOCR/imageio.h>


@interface UIImage (Pix)

- (UIImage *)otsuThreshold;

/**
 * Must call pixFreeData(pix) and free(pix) on returned (Pix *).
 */
//- (Pix *)pix;

+ (UIImage *)imageFromPix:(Pix *)pix;
+ (UIImage *)imageFrom1bppPix:(Pix *)pix;

@end
