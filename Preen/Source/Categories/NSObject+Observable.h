#import <Foundation/Foundation.h>


@interface NSObject (Observable)

@property (nonatomic, retain) NSMutableDictionary *observerCounts;

- (void)fire:(NSString *)event;
- (void)fire:(NSString *)event args:(NSDictionary *)args;
- (void)on:(NSString *)event target:(id)target action:(SEL)selector;
- (void)un:(NSString *)event target:(id)target;

@end
