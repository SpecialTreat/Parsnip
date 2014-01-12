#import <Foundation/Foundation.h>


@interface BEScanner : NSObject

- (void)codeScan:(UIImage *)image completion:(void(^)(NSArray *codeScanData))completion;
- (void)ocr:(UIImage *)image completion:(void(^)(NSString *ocrText, UIImage *ocrImage, NSString *hocrText))completion;
- (void)preOcr:(UIImage *)image completion:(void(^)(UIImage *preOcrImage))completion;
- (void)postOcr:(NSString *)text completion:(void(^)(NSString *postOcrText))completion;

@end
