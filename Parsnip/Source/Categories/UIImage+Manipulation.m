#import "UIImage+Manipulation.h"


@implementation UIImage (Manipulation)

- (UIImage *)autolevels
{
    CGFloat whitePoint;
    CGFloat blackPoint;
    
    CalculateAutocorretionValues(self.CGImage, &whitePoint, &blackPoint);
    
    const CGFloat decode[6] = {blackPoint,whitePoint,blackPoint,whitePoint,blackPoint,whitePoint};
    
    CGImageRef decodedImage;
    
    decodedImage = CGImageCreate(CGImageGetWidth(self.CGImage),
                                 CGImageGetHeight(self.CGImage),
                                 CGImageGetBitsPerComponent(self.CGImage),
                                 CGImageGetBitsPerPixel(self.CGImage),
                                 CGImageGetBytesPerRow(self.CGImage),
                                 CGImageGetColorSpace(self.CGImage),
                                 CGImageGetBitmapInfo(self.CGImage),
                                 CGImageGetDataProvider(self.CGImage),
                                 decode,
                                 YES,
                                 CGImageGetRenderingIntent(self.CGImage));
    
    UIImage* newImage = [UIImage imageWithCGImage:decodedImage scale:self.scale orientation:self.imageOrientation];
    
    CGImageRelease(decodedImage);
    
    return newImage;
}

void CalculateAutocorretionValues(CGImageRef image, CGFloat *whitePoint, CGFloat *blackPoint)
{
    UInt8* imageData = (UInt8 *)malloc(100 * 100 * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(imageData, 100, 100, 8, 4 * 100, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, 100, 100), image);
    
    int histogramm[256];
    bzero(histogramm, 256 * sizeof(int));
    
    for (int i = 0; i < 100 * 100 * 4; i += 4) {
        UInt8 value = (imageData[i] + imageData[i+1] + imageData[i+2]) / 3;
        histogramm[value]++;
    }
    
    CGContextRelease(ctx);
    free(imageData);
    
    int black = 0;
    int counter = 0;
    
    // count up to 200 (2%) values from the black side of the histogramm to find the black point
    while ((counter < 200) && (black < 256)) {
        counter += histogramm[black];
        black ++;
    }
    
    int white = 255;
    counter = 0;
    
    // count up to 200 (2%) values from the white side of the histogramm to find the white point
    while ((counter < 200) && (white > 0)) {
        counter += histogramm[white];
        white --;
    }
    
    *blackPoint = 0.0 - (black / 256.0);
    *whitePoint = 1.0 + ((255-white) / 256.0);
}

- (UIImage *)brightness:(CGFloat)brightnessFactor
{
    if ( brightnessFactor == 0 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = (uint8_t *)malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i; 
        uint8_t* green = rawData + (i + 1); 
        uint8_t* blue = rawData + (i + 2); 
        
        *red = MIN(255,MAX(0,roundf(*red + (*red * brightnessFactor))));
        *green = MIN(255,MAX(0,roundf(*green + (*green * brightnessFactor))));
        *blue = MIN(255,MAX(0,roundf(*blue + (*blue * brightnessFactor))));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg scale:self.scale orientation:self.imageOrientation];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage *)contrast:(CGFloat)contrastFactor
{
    if ( contrastFactor == 1 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = (uint8_t *)malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i; 
        uint8_t* green = rawData + (i + 1); 
        uint8_t* blue = rawData + (i + 2); 
        
        *red = MIN(255,MAX(0, roundf(contrastFactor*(*red - 127.5f)) + 128));
        *green = MIN(255,MAX(0, roundf(contrastFactor*(*green - 127.5f)) + 128));
        *blue = MIN(255,MAX(0, roundf(contrastFactor*(*blue - 127.5f)) + 128));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg scale:self.scale orientation:self.imageOrientation];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage *)contrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor
{
    if ( contrastFactor == 1 && brightnessFactor == 0 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = (uint8_t *)malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i; 
        uint8_t* green = rawData + (i + 1); 
        uint8_t* blue = rawData + (i + 2); 
        
        *red = MIN(255,MAX(0,roundf(*red + (*red * brightnessFactor))));
        *green = MIN(255,MAX(0,roundf(*green + (*green * brightnessFactor))));
        *blue = MIN(255,MAX(0,roundf(*blue + (*blue * brightnessFactor))));
        
        *red = MIN(255,MAX(0, roundf(contrastFactor*(*red - 127.5f)) + 128));
        *green = MIN(255,MAX(0, roundf(contrastFactor*(*green - 127.5f)) + 128));
        *blue = MIN(255,MAX(0, roundf(contrastFactor*(*blue - 127.5f)) + 128));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg scale:self.scale orientation:self.imageOrientation];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage *)crop:(CGRect)rect
{
    if (self.scale != 1.0f) {
        rect = CGRectMake(rect.origin.x * self.scale,
                          rect.origin.y * self.scale,
                          rect.size.width * self.scale,
                          rect.size.height * self.scale);
    }
    
    if([self isLandscape]) {
        CGFloat t = rect.origin.x;
        rect.origin.x = rect.origin.y;
        rect.origin.y = t;
        t = rect.size.width;
        rect.size.width = rect.size.height;
        rect.size.height = t;
    }

    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);

    return image;
}

- (UIImage *)gaussianBlur3x3
{
    const CGFloat filter[3][3] = { 
        {1.0f/16.0f, 2.0f/16.0f, 1.0f/16.0f},
        {2.0f/16.0f, 4.0f/16.0f, 2.0f/16.0f},
        {1.0f/16.0f, 2.0f/16.0f, 1.0f/16.0f}
    };
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = (uint8_t *)malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    for ( int y = 0; y < height; y++ ) {
        
        for ( int x = 0; x < width; x++ ) {
            
            uint8_t* pixel = rawData + (bytesPerRow * y) + (x * bytesPerPixel);
            
            CGFloat sumRed = 0;
            CGFloat sumGreen = 0;
            CGFloat sumBlue = 0;
            
            for ( int j = 0; j < 3; j++ ) {
                
                for ( int i = 0; i < 3; i++ ) {
                    
                    if ( (y + j - 1) >= height || (y + j - 1) < 0 ) {
                        //Use zero values at edge of image
                        //continue;
                        
                        //Use half value at edge of image
                        sumRed += 128.0f * filter[j][i];
                        sumGreen += 128.0f * filter[j][i];
                        sumBlue += 128.0f * filter[j][i];
                        continue;
                    }
                    
                    if ( (x + i - 1) >= width || (x + i - 1) < 0 ) {
                        //Use Zero values at edge of image
                        //continue;
                        
                        //Use half value at edge of image
                        sumRed += 128.0f * filter[j][i];
                        sumGreen += 128.0f * filter[j][i];
                        sumBlue += 128.0f * filter[j][i];
                        continue;
                    }
                    
                    uint8_t* kernelPixel = rawData + (bytesPerRow * (y + j - 1)) + ((x + i - 1) * bytesPerPixel);
                    
                    sumRed += kernelPixel[0] * filter[j][i];
                    sumGreen += kernelPixel[1] * filter[j][i];
                    sumBlue += kernelPixel[2] * filter[j][i];
                    
                }
                
            }
            
            pixel[0] = roundf(sumRed);
            pixel[1] = roundf(sumGreen);
            pixel[2] = roundf(sumBlue);
            
        }
        
    }
    
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg scale:self.scale orientation:self.imageOrientation];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage *)gaussianBlur5x5 {
    const CGFloat filter[5][5] = { 
        {1.0f/256.0f, 4.0f/256.0f, 6.0f/256.0f, 4.0f/256.0f, 1.0f/256.f},
        {4.0f/256.0f, 16.0f/256.0f, 24.0f/256.0f, 16.0f/256.0f, 4.0f/256.f},
        {6.0f/256.0f, 24.0f/256.0f, 36.0f/256.0f, 24.0f/256.0f, 6.0f/256.f},
        {4.0f/256.0f, 16.0f/256.0f, 24.0f/256.0f, 16.0f/256.0f, 4.0f/256.f},
        {1.0f/256.0f, 4.0f/256.0f, 6.0f/256.0f, 4.0f/256.0f, 1.0f/256.f}
    };
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = (uint8_t *)malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    for ( int y = 0; y < height; y++ ) {
        
        for ( int x = 0; x < width; x++ ) {
            
            uint8_t* pixel = rawData + (bytesPerRow * y) + (x * bytesPerPixel);
            
            CGFloat sumRed = 0;
            CGFloat sumGreen = 0;
            CGFloat sumBlue = 0;
            
            for ( int j = 0; j < 5; j++ ) {
                
                for ( int i = 0; i < 5; i++ ) {
                    
                    if ( (y + j - 2) >= height || (y + j - 2) < 0 ) {
                        //Use zero values at edge of image
                        //continue;
                        
                        //Use half value at edge of image
                        sumRed += 128.0f * filter[j][i];
                        sumGreen += 128.0f * filter[j][i];
                        sumBlue += 128.0f * filter[j][i];
                        continue;
                    }
                    
                    if ( (x + i - 2) >= width || (x + i - 2) < 0 ) {
                        //Use zero values at edge of image
                        //continue;
                        
                        //Use half value at edge of image
                        sumRed += 128.0f * filter[j][i];
                        sumGreen += 128.0f * filter[j][i];
                        sumBlue += 128.0f * filter[j][i];
                        continue;
                    }
                    
                    uint8_t* kernelPixel = rawData + (bytesPerRow * (y + j - 2)) + ((x + i - 2) * bytesPerPixel);
                    
                    sumRed += kernelPixel[0] * filter[j][i];
                    sumGreen += kernelPixel[1] * filter[j][i];
                    sumBlue += kernelPixel[2] * filter[j][i];
                    
                }
                
            }
            
            pixel[0] = roundf(sumRed);
            pixel[1] = roundf(sumGreen);
            pixel[2] = roundf(sumBlue);
            
        }
        
    }
    
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg scale:self.scale orientation:self.imageOrientation];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage *)grayscale
{
    UIImage *image = self;
    
    CGImageRef imageRef = self.CGImage;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object  
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:self.scale orientation:self.imageOrientation];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(newImageRef);
    
    // Return the new grayscale image
    return newImage;
}

- (BOOL)hasAlpha {
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

- (BOOL)isLandscape
{
    return (self.imageOrientation == UIImageOrientationLeft ||
            self.imageOrientation == UIImageOrientationRight ||
            self.imageOrientation == UIImageOrientationLeftMirrored ||
            self.imageOrientation == UIImageOrientationRightMirrored);
}

- (BOOL)isPortrait
{
    return ![self isLandscape];
}

- (UIImage *)rectangle:(CGRect)rect color:(UIColor *)color width:(CGFloat)width
{
    CGImageRef imgRef = self.CGImage;
    size_t w = CGImageGetWidth(imgRef);
    size_t h = CGImageGetHeight(imgRef);
    rect = CGRectMake(
        rect.origin.x,
        h - rect.origin.y - rect.size.height,
        rect.size.width,
        rect.size.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * w;
    size_t totalBytes = bytesPerRow * h;
    
    //Allocate Image space
    uint8_t* rawData = (uint8_t *)malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, w, h, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), imgRef);
    
    //Draw the rectangle
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    CGContextSetRGBStrokeColor(context, red, green, blue, alpha);
    CGContextStrokeRectWithWidth(context, rect, width);
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg scale:self.scale orientation:self.imageOrientation];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage *)reorient
{
    return [self reorientToOrientation:self.imageOrientation];
}

- (UIImage *)reorientToOrientation:(UIImageOrientation)imageOrientation
{
    UIImage *image = self;
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation currentImageOrientation = image.imageOrientation;
    
    switch(currentImageOrientation) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (currentImageOrientation == UIImageOrientationRight || currentImageOrientation == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -1, 1);
        CGContextTranslateCTM(context, -height, 0);
    } else if (currentImageOrientation == UIImageOrientationRightMirrored || currentImageOrientation == UIImageOrientationLeftMirrored){
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -width);  
    } else {
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [[UIImage alloc] initWithCGImage:newImage.CGImage scale:self.scale orientation:imageOrientation];
}

- (UIImage *)resize:(CGSize)size interpolationQuality:(CGInterpolationQuality)quality
{
    BOOL drawTransposed;
    
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
            
        default:
            drawTransposed = NO;
    }
    
    return [self resize:size
              transform:[self transformForOrientation:size]
         drawTransposed:drawTransposed
   interpolationQuality:quality];
}

- (UIImage *)resizeWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize)bounds interpolationQuality:(CGInterpolationQuality)quality
{
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio;

    switch (contentMode) {
        case UIViewContentModeScaleAspectFill:
            ratio = MAX(horizontalRatio, verticalRatio);
            break;
            
        case UIViewContentModeScaleAspectFit:
            ratio = MIN(horizontalRatio, verticalRatio);
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unsupported content mode: %ld", (long)contentMode];
    }
    
    CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    
    return [self resize:newSize interpolationQuality:quality];
}

- (UIImage *)resize:(CGSize)size transform:(CGAffineTransform)transform drawTransposed:(BOOL)transpose interpolationQuality:(CGInterpolationQuality)quality
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, size.width, size.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;
    
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));
    
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

- (UIImage *)rotate:(CGFloat)degrees
{   
    CGFloat radians = degrees * M_PI / 180.0f;
    CGImageRef imgRef = self.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;

    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

    // Rotate the image context
    CGContextRotateCTM(bitmap, radians);

    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-width / 2, -height / 2, width, height), self.CGImage);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [[UIImage alloc] initWithCGImage:newImage.CGImage scale:self.scale orientation:self.imageOrientation];
}

- (UIImage *)thumbnail:(CGSize)size
{
    UIImage *image = [self resizeWithContentMode:UIViewContentModeScaleAspectFill bounds:size interpolationQuality:kCGInterpolationMedium];
    return [image crop:CGRectMake(0.0f, 0.0f, size.width, size.height)];
}

- (UIImage *)removeAlpha
{
    UIGraphicsBeginImageContextWithOptions(self.size, YES, self.scale);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default:
            break;
    }
    
    return transform;
}

@end
