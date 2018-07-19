#import <Foundation/Foundation.h>
#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif
#import "BTPaymentFlowRequest.h"
#import "BTPaymentFlowDriver.h"

NS_ASSUME_NONNULL_BEGIN

@class BTIdealResult;
@protocol BTIdealRequestDelegate;

/**
 Used to initialize an iDEAL payment flow
 */
@interface BTIdealRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

/**
 Optional: The address of the customer. An error will occur if this address is not valid.
 */
@property (nonatomic, nullable, strong) BTPostalAddress *address;

/**
 The amount for the transaction.
 */
@property (nonatomic, copy) NSString *amount;

/**
 Optional: A valid ISO currency code to use for the transaction. Defaults to merchant currency code if not set.
 */
@property (nonatomic, nullable, copy) NSString *currencyCode;

/**
 Payer email of the customer.
 */
@property (nonatomic, copy) NSString *email;

/**
 First name of the customer.
 */
@property (nonatomic, copy) NSString *firstName;

/**
 Last name of the customer.
 */
@property (nonatomic, copy) NSString *lastName;

/**
 Phone number of the customer.
 */
@property (nonatomic, copy) NSString *phone;

/**
 A delegate for receiving information about the iDEAL payment.
 */
@property (nonatomic, weak) id<BTIdealRequestDelegate> idealPaymentFlowDelegate;

@end

/**
 Protocol for iDEAl payment flow
 */
@protocol BTIdealRequestDelegate

@required

/**
 Returns the BTIdealResult with the iDEAL ID and status of `PENDING` before the flow starts. The ID should be used in conjunction with webhooks to detect the change in status.
 */
- (void)idealPaymentStarted:(BTIdealResult *)result;

@end

NS_ASSUME_NONNULL_END
