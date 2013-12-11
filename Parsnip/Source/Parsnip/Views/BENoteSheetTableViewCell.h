#import <UIKit/UIKit.h>

#import "BETextData.h"


@interface BENoteSheetTableViewCell : UITableViewCell

@property (nonatomic) BETextData *textData;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *text;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSTimeZone *timeZone;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSDictionary *addressComponents;
@property (nonatomic) NSURL *URL;
@property (nonatomic) NSURL *email;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSDictionary *components;

- (void)addButtonWithKey:(NSString *)key
                  target:(id)target
                  action:(SEL)selector;

@end
