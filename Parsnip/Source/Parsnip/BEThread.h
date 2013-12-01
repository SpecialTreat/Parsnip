#import <Foundation/Foundation.h>


@interface BEThread : NSObject

+ (void)background:(void(^)())block;
+ (void)main:(void(^)())block;

@end
