//
//  BENote.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <AddressBook/AddressBook.h>
#import <Foundation/Foundation.h>
#import "BEModel.h"


@interface BENote : BEModel

+ (UIImage *)createThumbnail:(UIImage *)image;
+ (void)replaceMostRecentDrafts:(BENote *)note;

@property (nonatomic) NSUInteger pk;

@property (nonatomic) BOOL archived;

@property (nonatomic) BOOL userSaved;

@property (nonatomic, retain) UIImage *rawImage;
@property (nonatomic, retain) NSDate *rawImageTimestamp;

@property (nonatomic, retain) UIImage *thumbnailImage;
@property (nonatomic, retain) NSDate *thumbnailImageTimestamp;

@property (nonatomic, retain) UIImage *croppedImage;
@property (nonatomic, retain) NSDate *croppedImageTimestamp;
@property (nonatomic) CGRect croppedImageFrame;
@property (nonatomic) CGAffineTransform croppedImageTransform;
@property (nonatomic) CGPoint croppedImageOffset;
@property (nonatomic) CGFloat croppedImageScale;
@property (nonatomic) CGFloat croppedImageRotation;

@property (nonatomic, retain) NSArray *codeScanData;
@property (nonatomic, retain) NSString *codeScanText;
@property (nonatomic, retain) NSDate *codeScanTimestamp;

@property (nonatomic, retain) UIImage *preOcrImage;
@property (nonatomic, retain) NSDate *preOcrImageTimestamp;

@property (nonatomic, retain) UIImage *ocrImage;
@property (nonatomic, retain) NSDate *ocrImageTimestamp;

@property (nonatomic, retain) NSString *ocrText;
@property (nonatomic, retain) NSDate *ocrTextTimestamp;

@property (nonatomic, retain) NSString *hocrText;
@property (nonatomic, retain) NSDate *hocrTextTimestamp;

@property (nonatomic, retain) NSString *postOcrText;
@property (nonatomic, retain) NSDate *postOcrTextTimestamp;

@property (nonatomic, retain) NSString *userText;
@property (nonatomic, retain) NSDate *userTextTimestamp;

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSDictionary *dataTypes;
@property (nonatomic, readonly) BOOL hasDataTypes;

@property (nonatomic, readonly) BOOL hasPerson;
@property (nonatomic, readonly) BOOL hasVCards;
@property (nonatomic, readonly) NSArray *vCards;
@property (nonatomic, readonly) NSUInteger vCardCount;

@property (nonatomic, readonly) NSString *firstNonDataTypeLine;

- (ABRecordRef)createPerson CF_RETURNS_RETAINED;

@end
