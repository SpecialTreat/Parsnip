#import <UIKit/UIKit.h>


@interface PreenCameraView : UIView

@property (nonatomic, readonly) BOOL torchEnabled;
@property (nonatomic, readonly) BOOL flashEnabled;

- (void)startVideo;
- (void)stopVideo;
- (void)captureImage:(void(^)(UIImage *image))imageHandler;

@end
