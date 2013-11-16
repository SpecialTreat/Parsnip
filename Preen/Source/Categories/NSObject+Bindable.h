#import <Foundation/Foundation.h>


@interface NSObject (Bindable)

@property (readonly) NSArray *properties;

- (void)bind:(NSObject *)instance;
- (void)unbind:(NSObject *)instance;

@end
