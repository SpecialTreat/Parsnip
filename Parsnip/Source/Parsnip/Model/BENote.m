//
//  BENote.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BENote.h"

#import "NSString+Tools.h"
#import "FMDatabase.h"
#import "BEDB.h"
#import "BETextData.h"
#import "BETextDataDetector.h"
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

@dynamic codeScanData;
@dynamic codeScanText;
@dynamic codeScanTimestamp;

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
    } else if (self.codeScanText) {
        return self.codeScanText;
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
        _dataTypes = [BETextDataDetector detectDataTypes:dataTypesText stripEmpty:YES];
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
    ABRecordRef person = [BETextDataDetector createPersonWithDataTypes:self.dataTypes];
    if ([self internalValueForProperty:@"rawImage"] && self.rawImage) {
        NSData *data = UIImagePNGRepresentation(self.rawImage);
        CFDataRef imageData = CFDataCreate(NULL, (UInt8 *)data.bytes, data.length);
        ABPersonSetImageData(person, imageData, nil);
        CFRelease(imageData);
    }

    NSString *name = self.firstNonDataTypeLine;
    ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef)name, nil);

    NSString *note = [BEUI.theme stringForKey:@"CreateContactNoteText"];
    ABRecordSetValue(person, kABPersonNoteProperty, (__bridge CFStringRef)note, nil);

    return person;
}

- (NSArray *)vCards
{
    NSMutableArray *vCards = [NSMutableArray array];
    NSArray *codeScanData = self.codeScanData;
    if (codeScanData) {
        for (NSDictionary *data in codeScanData) {
            if (data[@"VCards"] && [data[@"VCards"] count]) {
                [vCards addObjectsFromArray:data[@"VCards"]];
            }
        }
    }
    return vCards;
}

- (NSUInteger)vCardCount
{
    NSUInteger count = 0;
    NSArray *codeScanData = self.codeScanData;
    if (codeScanData) {
        for (NSDictionary *data in codeScanData) {
            if (data[@"VCards"]) {
                count += [data[@"VCards"] count];
            }
        }
    }
    return count;
}

- (BOOL)hasVCards
{
    NSArray *codeScanData = self.codeScanData;
    if (codeScanData) {
        for (NSDictionary *data in codeScanData) {
            if (data[@"VCards"] && [data[@"VCards"] count]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)hasPerson
{
    return (self.hasVCards ||
            [self.dataTypes[@"Address"] count] ||
            [self.dataTypes[@"Email"] count] ||
            [self.dataTypes[@"URL"] count] ||
            [self.dataTypes[@"PhoneNumber"] count]);
}

- (NSString *)firstNonDataTypeLine
{
    if ([self.dataTypes[@"Text"] count]) {
        BETextData *textData = self.dataTypes[@"Text"][0];
        return textData.matchedText.firstLine;
    } else {
        return self.text.firstLine;
    }
}

@end