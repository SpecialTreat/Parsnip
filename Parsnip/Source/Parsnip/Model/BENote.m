#import "BENote.h"

#import "NSString+Tools.h"
#import "FMDatabase.h"
#import "BEDB.h"
#import "BEOcr.h"
#import "BETextData.h"
#import "BEThread.h"
#import "BEUI.h"
#import "UIImage+Manipulation.h"


@implementation BENote
{
    NSString *dataTypesText;
}

+ (NSArray *)getIndexes
{
    return @[@"archived",
             @"croppedImageTimestamp",
             @"userSaved",
             @[@"archived", @"croppedImageTimestamp"],
             @[@"croppedImageTimestamp", @"archived"]];
}

+ (NSString *)sqlForColumn:(NSString *)column
{
    NSString *sql = [super sqlForColumn:column];
    if ([column isEqualToString:BENote.propertyToColumnMap[@"archived"]]) {
        return [NSString stringWithFormat:@"%@ NOT NULL DEFAULT 0", sql];
    } else if ([column isEqualToString:BENote.propertyToColumnMap[@"userSaved"]]) {
        return [NSString stringWithFormat:@"%@ NOT NULL DEFAULT 0", sql];
    } else if ([column isEqualToString:BENote.propertyToColumnMap[@"croppedImageTimestamp"]]) {
        return [NSString stringWithFormat:@"%@ NOT NULL DEFAULT 0", sql];
    } else {
        return sql;
    }
}

+ (UIImage *)createThumbnail:(UIImage *)image
{
    return [image thumbnail:[BEUI.theme sizeForKey:@"NoteThumbnailSize"]];
}

+ (void)replaceMostRecentDrafts:(BENote *)note
{
    [BEDB.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *column = BENote.propertyToColumnMap[@"userSaved"];
        NSNumber *columnValue = [NSNumber numberWithChar:NO];
        NSArray* models = [BEDB getInDatabase:db modelClass:BENote.class parameters:@{column: columnValue} orderBy:nil asc:YES limit:0 offset:0];
        BOOL success = YES;
        for (BENote *model in models) {
            success = [BEDB removeInDatabase:db model:model removeFiles:NO];
            if(success) {
                success = [model markFilesForDeletion];
            }
            if (!success) {
                break;
            }
        }
        if (success) {
            note.userSaved = NO;
            success = [BEDB saveInDatabase:db model:note];
        }
        for (BEModel *model in models) {
            if (success) {
                [model deleteFiles];
            } else {
                [model restoreFilesMarkedForDeletion];
            }
        }
        if (!success) {
            *rollback = YES;
            return;
        }
    }];
}

@dynamic pk;

@dynamic archived;

@dynamic userSaved;

@dynamic rawImage;
@dynamic rawImageTimestamp;

@dynamic thumbnailImage;
@dynamic thumbnailImageTimestamp;

@dynamic croppedImage;
@dynamic croppedImageTimestamp;
@dynamic croppedImageFrame;
@dynamic croppedImageTransform;
@dynamic croppedImageOffset;
@dynamic croppedImageScale;
@dynamic croppedImageRotation;

@dynamic preOcrImage;
@dynamic preOcrImageTimestamp;

@dynamic ocrImage;
@dynamic ocrImageTimestamp;

@dynamic ocrText;
@dynamic ocrTextTimestamp;

@dynamic hocrText;
@dynamic hocrTextTimestamp;

@dynamic postOcrText;
@dynamic postOcrTextTimestamp;

@dynamic userText;
@dynamic userTextTimestamp;

@synthesize dataTypes = _dataTypes;

- (NSString *)text
{
    if (self.userText) {
        return self.userText;
    } else if(self.postOcrText) {
        return self.postOcrText;
    } else {
        return self.ocrText;
    }
}

- (NSDictionary *)dataTypes
{
    if([self isDataTypesStale] && self.text) {
        dataTypesText = self.text;
        _dataTypes = [BETextData detectDataTypes:dataTypesText stripEmpty:YES];
    }
    return _dataTypes;
}

- (BOOL)hasDataTypes
{
    for(NSString *dataType in self.dataTypes) {
        if([self.dataTypes[dataType] count]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDataTypesStale
{
    return (!_dataTypes || ![self.text isEqualToString:dataTypesText]);
}

- (ABRecordRef)createPerson
{
    ABRecordRef person = [BETextData createPersonWithDataTypes:self.dataTypes];
    if ([self internalValueForProperty:@"rawImage"] && self.rawImage) {
        NSData *data = UIImagePNGRepresentation(self.rawImage);
        CFDataRef imageData = CFDataCreate(NULL, (UInt8 *)data.bytes, data.length);
        ABPersonSetImageData(person, imageData, nil);
        CFRelease(imageData);
    }

    NSString *name = self.text.firstLine;
    ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef)name, nil);

    NSString *note = [BEUI.theme stringForKey:@"CreateContactNote"];
    ABRecordSetValue(person, kABPersonNoteProperty, (__bridge CFStringRef)note, nil);

    return person;
}

- (BOOL)hasPerson
{
    return (((NSArray *)self.dataTypes[@"Address"]).count ||
            ((NSArray *)self.dataTypes[@"Email"]).count ||
            ((NSArray *)self.dataTypes[@"URL"]).count ||
            ((NSArray *)self.dataTypes[@"PhoneNumber"]).count);
}

@end