#import <AddressBook/AddressBook.h>
#import <Foundation/Foundation.h>


@interface BETextData : NSObject

+ (const CFStringRef)addressBookLabelForPhoneNumber:(NSString *)phoneNumber defaultLabel:(const CFStringRef)label;
+ (ABRecordRef)createPersonWithDataTypes:(NSDictionary *)dataTypes CF_RETURNS_RETAINED;
+ (NSDictionary *)detectDataTypes:(NSString *)text;
+ (NSDictionary *)detectDataTypes:(NSString *)text stripEmpty:(BOOL)stripEmpty;
+ (void)detectDataTypes:(NSString *)text stripEmpty:(BOOL)stripEmpty completion:(void(^)(NSDictionary *dataTypes))completion;
+ (NSUInteger)detectDataTypesCount:(NSString *)text;
+ (NSUInteger)detectDataTypesCount:(NSString *)text stripEmpty:(BOOL)stripEmpty;

@end
