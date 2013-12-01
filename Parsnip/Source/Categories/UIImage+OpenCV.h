#import <UIKit/UIKit.h>
#include "opencv2/opencv.hpp"


@interface UIImage (OpenCV)

- (cv::Mat)mat;
- (cv::Mat)matGray;

/**
 * Must call cvReleaseImage(iplImage) and free(iplImage) on returned (IplImage *).
 */
- (IplImage *)iplImageWithNumberOfChannels:(int)channels;

//- (NSArray *)textBoundingBoxes;
- (CGAffineTransform)transformForOrientationDrawnTransposed:(BOOL *)drawTransposed;

//- (UIImage *)binarization;

// Returns a UIImage by copying the IplImage's bitmap data.
+ (UIImage *)imageFromIplImage:(IplImage *)iplImage;
+ (UIImage *)imageFromIplImage:(IplImage *)iplImage orientation:(UIImageOrientation)orientation;
+ (UIImage *)imageFromMat:(cv::Mat)mat;

@end
