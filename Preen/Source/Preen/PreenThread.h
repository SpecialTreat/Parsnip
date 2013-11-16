#import <Foundation/Foundation.h>


@interface PreenThread : NSObject

+ (void)background:(void(^)())block;
+ (void)main:(void(^)())block;

@end
