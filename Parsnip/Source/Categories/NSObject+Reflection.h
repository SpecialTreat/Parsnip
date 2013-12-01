#import <Foundation/Foundation.h>


@interface NSObject (Reflection)

- (NSString *)selectorNameToPropertyName:(NSString *)selectorName;
- (NSString *)selectorToPropertyName:(SEL)selector;
- (BOOL)isPropertyPrimitive:(NSString *)propertyName;
- (NSString *)encodedTypeOfProperty:(NSString *)propertyName;
- (NSString *)typeOfProperty:(NSString *)property;

@end
