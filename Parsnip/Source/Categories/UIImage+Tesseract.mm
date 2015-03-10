#import "UIImage+Tesseract.h"


@implementation UIImage (Pix)

- (UIImage *)otsuThreshold
{
    CGImageRef imageRef = self.CGImage;
    size_t w = CGImageGetWidth(imageRef);
    size_t h = CGImageGetHeight(imageRef);
    
    int bytes_per_line  = (int)CGImageGetBytesPerRow(imageRef);
    int bytes_per_pixel = (int)CGImageGetBitsPerPixel(imageRef) / 8.0;
    
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    const UInt8 *imageBytes = CFDataGetBytePtr(imageData);
    
    tesseract::ImageThresholder *thresholder = new tesseract::ImageThresholder();
    thresholder->SetImage(imageBytes, (int)w, (int)h, (int)bytes_per_pixel, (int)bytes_per_line);
    
    Pix *pix = nil;
    thresholder->ThresholdToPix(&pix);

    UIImage *image = [UIImage imageFrom1bppPix:pix];
    
    CFRelease(imageData);
    pixFreeData(pix);
    delete thresholder;

    return image;
}

/**
 * Must call pixFreeData(pix) and free(pix) on returned (Pix *).
 */
- (Pix *)pix
{
    CGImageRef imageRef = self.CGImage;
    
    Pix *pix = (Pix *)malloc(sizeof(Pix));
    pix->w = CGImageGetWidth(imageRef);
    pix->h = CGImageGetHeight(imageRef);
    pix->d = CGImageGetBitsPerPixel(imageRef);
    pix->wpl = CGImageGetBytesPerRow(imageRef) / 4.0f;
    pix->informat = IFF_TIFF;
    pix->colormap = NULL;

#ifndef __clang_analyzer__
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    const UInt8 *pixData = CFDataGetBytePtr(data);
    pix->data = (l_uint32 *)pixData;
#endif

    pixEndianByteSwap(pix);
    
    return pix;
}

+ (UIImage *)imageFrom1bppPix:(Pix *)pix
{
    return [UIImage imageFromPix:pixUnpackBinary(pix, 32, 1)];
}

+ (UIImage *)imageFromPix:(Pix *)pix
{
    l_uint32 width = pixGetWidth(pix);
    l_uint32 height = pixGetHeight(pix);
    l_uint32 bitsPerPixel = pixGetDepth(pix);
    l_uint32 bytesPerRow = pixGetWpl(pix) * 4;
    l_uint32 bitsPerComponent = 8;
    if (pixSetSpp(pix, 4) == 0) {
        bitsPerComponent = bitsPerPixel / pixGetSpp(pix);
    }

    l_uint32 *pixData = pixGetData(pix);

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixData, bytesPerRow * height, NULL);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGImage *cgImage = CGImageCreate(width, height,
                                     bitsPerComponent, bitsPerPixel, bytesPerRow,
                                     colorSpace, kCGBitmapByteOrderDefault,
                                     provider, NULL, NO, kCGRenderingIntentDefault);

    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CFRelease(cgImage);
    return image;

//    UIImage *image = nil;
//    l_uint8 *bytes = NULL;
//    size_t size = 0;
//
//    if (0 == pixWriteMem(&bytes, &size, pix, IFF_TIFF)) {
//        NSData *data = [[NSData alloc] initWithBytesNoCopy:bytes length:(NSUInteger)size freeWhenDone:YES];
//        image = [UIImage imageWithData:data];
//    }
//    
//    return image;
}

@end
