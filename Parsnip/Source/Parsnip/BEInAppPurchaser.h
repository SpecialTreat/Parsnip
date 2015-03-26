//
//  BEInAppPurchaser.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <StoreKit/StoreKit.h>


UIKIT_EXTERN NSString *const BEInAppPurchaserProductPurchasedNotification;
UIKIT_EXTERN NSString *const BEInAppPurchaserParsnipPro;


typedef void (^ProductCompletion)(SKProduct *product, NSError *error);
typedef void (^SuccessCompletion)(BOOL success);

@interface BEInAppPurchaser : NSObject

+ (BEInAppPurchaser *)parsnipPurchaser;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;

- (void)purchaseProduct:(SKProduct *)product;
- (BOOL)isProductPurchased:(NSString *)productIdentifier;
- (void)checkForProduct:(NSString *)productIdentifier completion:(SuccessCompletion)completion;

- (void)restoreCompletedTransactions;

@end