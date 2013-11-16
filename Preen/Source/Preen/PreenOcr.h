#import <Foundation/Foundation.h>


@interface PreenOcr : NSObject

- (void)ocr:(UIImage *)image completion:(void(^)(NSString *ocrText, UIImage *ocrImage, NSString *hocrText))completion;
- (void)preOcr:(UIImage *)image completion:(void(^)(UIImage *preOcrImage))completion;
- (void)postOcr:(NSString *)text completion:(void(^)(NSString *postOcrText))completion;

@end
