//
//  BEInAppPurchaser.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEInAppPurchaser.h"

#import "BEAppDelegate.h"
#import "BEDialogView.h"
#import "BEUI.h"
#import "Reachability.h"


NSString *const BEInAppPurchaserProductPurchasedNotification = @"BEInAppPurchaserProductPurchasedNotification";
NSString *const BEInAppPurchaserParsnipPro = @"com.bracingeffect.Parsnip.Pro";


typedef void (^RequestProductsCompletion)(NSArray *products,
                                          NSArray *invalidProductIdentifiers,
                                          NSError *error);

@interface BEInAppPurchaser () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end


@implementation BEInAppPurchaser
{
    BEDialogView *dialog;
    SKProductsRequest *_productsRequest;
    RequestProductsCompletion _requestProductsCompletion;
    SuccessCompletion _purchaseProductsCompletion;
    SKProduct *_productToPurchase;
    NSSet *_productIdentifiers;
    NSMutableSet *_purchasedProductIdentifiers;
    NSMutableDictionary *_products;
}

static BOOL _requireInAppPurchase = YES;

+ (void)initialize
{
    _requireInAppPurchase = [BEUI.theme boolForKey:@"RequireInAppPurchase"];
}

+ (BEInAppPurchaser *)parsnipPurchaser
{
    static dispatch_once_t once;
    static BEInAppPurchaser *_parsnipPurchaser;
    dispatch_once(&once, ^{
        NSSet *productIdentifiers = [NSSet setWithObjects:BEInAppPurchaserParsnipPro, nil];
        _parsnipPurchaser = [[BEInAppPurchaser alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return _parsnipPurchaser;
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers
{
    if ((self = [super init])) {
        _productIdentifiers = productIdentifiers;
        _purchasedProductIdentifiers = [NSMutableSet set];

        for (NSString *productIdentifier in _productIdentifiers) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier]) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
            }
        }
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (NSString *)localizedPrice:(NSNumber *)price locale:(NSLocale *)priceLocale
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:priceLocale];
    return [numberFormatter stringFromNumber:price];
}

- (void)requestProducts:(RequestProductsCompletion)completion
{
    _requestProductsCompletion = [completion copy];
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (BOOL)isProductPurchased:(NSString *)productIdentifier
{
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)checkForProduct:(NSString *)productIdentifier completion:(SuccessCompletion)completion
{
    if (!_requireInAppPurchase || [self isProductPurchased:productIdentifier]) {
        completion(YES);
    } else {
        BOOL canMakePayments = SKPaymentQueue.canMakePayments;
        _purchaseProductsCompletion = [completion copy];

        UIView *topView = BEAppDelegate.topController.view;
        dialog = [[BEDialogView alloc] initWithFrame:topView.bounds];
        dialog.maskAlpha = [BEUI.theme floatForKey:@"Dialog.MaskAlpha"];
        dialog.shadowColor = [BEUI.theme colorForKey:@"Dialog.ShadowColor"];
        dialog.size = [BEUI.theme sizeForKey:@"Dialog.BackgroundSize" withDefault:CGSizeMake(280.0f, 240.0f)];
        [topView addSubview:dialog];

        if (canMakePayments) {
            UIButton *purchaseButton = [BEUI buttonWithKey:@[@"InAppPurchaseDialogPurchaseButton", @"DialogButton"] target:self action:@selector(onDialogPurchaseButtonTouch:event:)];
            purchaseButton.enabled = NO;
            UIButton *cancelButton = [BEUI buttonWithKey:@[@"InAppPurchaseDialogCancelButton", @"DialogButton"] target:self action:@selector(onDialogCancelButtonTouch:event:)];
            dialog.buttons = @[cancelButton, purchaseButton];
            [dialog show:nil completion:^(BOOL finished) {
                [dialog startActivityIndicator];
                [self productForIdentifier:productIdentifier completion:^(SKProduct *product, NSError *error) {
                    [dialog stopActivityIndicator];
                    if (product) {
                        _productToPurchase = product;
                        dialog.title = [NSString stringWithFormat:@"%@ - %@", product.localizedTitle, [self localizedPrice:product.price locale:product.priceLocale]];
                        dialog.description = [NSString stringWithFormat:@"This feature requires %@.\n\n%@", product.localizedTitle, product.localizedDescription];
                        purchaseButton.enabled = YES;
                    } else {
                        Reachability *reachability = [Reachability reachabilityForInternetConnection];
                        NSString *errorText;
                        if ([reachability isReachable]) {
                            if (error) {
                                errorText = [NSString stringWithFormat:@"In-App Puchases aren't working right now: %@", error.localizedDescription];
                            } else {
                                errorText = @"For some reason, In-App Puchases aren't working right now.";
                            }
                        } else {
                            errorText = @"In-App purchases require an Internet connection. Please connect to the Internet and try again.";
                        }
                        NSString *upgradeName = [BEUI.theme stringForKey:@"UpgradeName"];
                        dialog.title = upgradeName;
                        dialog.description = [NSString stringWithFormat:@"This feature requires an In-App Purchase of %@.\n\n%@", upgradeName, errorText];
                    }
                }];
            }];
        } else {
            NSString *upgradeName = [BEUI.theme stringForKey:@"UpgradeName"];
            dialog.title = @"Device Restricted";
            dialog.description = [NSString stringWithFormat:@"This feature requires an In-App Purchase of %@.\n\nTo enable In-App Purchases, go to Settings -> General -> Restrictions.", upgradeName];
            UIButton *okButton = [BEUI buttonWithKey:@[@"InAppPurchaseDialogOkButton", @"DialogButton"] target:self action:@selector(onDialogCancelButtonTouch:event:)];
            dialog.buttons = @[okButton];
            [dialog show:nil completion:nil];
        }
    }
}

- (void)onDialogCancelButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (_purchaseProductsCompletion) {
        _purchaseProductsCompletion(NO);
    }
    _purchaseProductsCompletion = nil;

    if (dialog) {
        [dialog hide:nil completion:^(BOOL finished) {
            [dialog removeFromSuperview];
            dialog = nil;
        }];
    }
}

- (void)onDialogPurchaseButtonTouch:(UIButton *)sender event:(UIEvent *)event
{
    if (dialog) {
        [dialog fadeOutDialog:nil];
    }
    [self purchaseProduct:_productToPurchase];
}

- (void)productForIdentifier:(NSString *)productIdentifier completion:(ProductCompletion)completion
{
    @synchronized(self) {
        if (_products && _products[productIdentifier]) {
            completion(_products[productIdentifier], nil);
        } else {
            _products = [NSMutableDictionary dictionary];
            [self requestProducts:^(NSArray *products, NSArray *invalidProductIdentifiers, NSError *error) {
                for (SKProduct *product in products) {
                    _products[product.productIdentifier] = product;
                }
                completion(_products[productIdentifier], error);
            }];
        }
    }
}

- (void)purchaseProduct:(SKProduct *)product
{
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    _productsRequest = nil;

    if(_requestProductsCompletion) {
        _requestProductsCompletion(response.products, response.invalidProductIdentifiers, nil);
    }
    _requestProductsCompletion = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    _productsRequest = nil;

    if(_requestProductsCompletion) {
        _requestProductsCompletion(nil, nil, error);
    }
    _requestProductsCompletion = nil;
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    if (dialog) {
        [dialog hide:nil completion:^(BOOL finished) {
            [dialog removeFromSuperview];
            dialog = nil;
        }];
    }
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    if (dialog) {
        [dialog hide:nil completion:^(BOOL finished) {
            [dialog removeFromSuperview];
            dialog = nil;
        }];
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        if (dialog) {
            dialog.title = @"Purchase Error";
            dialog.description = [NSString stringWithFormat:@"There was an error during the purchase.\n\n%@", transaction.error.localizedDescription];
            UIButton *okButton = [BEUI buttonWithKey:@[@"InAppPurchaseDialogOkButton", @"DialogButton"] target:self action:@selector(onDialogCancelButtonTouch:event:)];
            dialog.buttons = @[okButton];
        } else {
            NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
        }
    }

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    if (dialog) {
        [dialog fadeInDialog:nil];
    }
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier
{
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:BEInAppPurchaserProductPurchasedNotification object:productIdentifier userInfo:nil];
    
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end