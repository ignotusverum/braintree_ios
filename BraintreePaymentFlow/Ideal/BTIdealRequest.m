#import "BTIdealRequest.h"
#import "BTConfiguration+Ideal.h"
#if __has_include("BTLogger_Internal.h")
#import "BTLogger_Internal.h"
#else
#import <BraintreeCore/BTLogger_Internal.h>
#endif
#if __has_include("BTAPIClient_Internal.h")
#import "BTAPIClient_Internal.h"
#else
#import <BraintreeCore/BTAPIClient_Internal.h>
#endif
#import "BTPaymentFlowDriver_Internal.h"
#import "BTIdealRequest.h"
#import "Braintree-Version.h"
#import <SafariServices/SafariServices.h>
#import "BTIdealResult.h"
#import "BTPaymentFlowDriver+Ideal_Internal.h"

@interface BTIdealRequest ()

@property (nonatomic, copy, nullable) NSString *idealId;
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation BTIdealRequest

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    BTIdealRequest *idealRequest = (BTIdealRequest *)request;
    [apiClient fetchOrReturnRemoteConfiguration:^(__unused BTConfiguration *configuration, NSError *configurationError) {
        if (configurationError) {
            [delegate onPaymentComplete:nil error:configurationError];
            return;
        }

        if ([self.paymentFlowDriverDelegate returnURLScheme] == nil || [[self.paymentFlowDriverDelegate returnURLScheme] isEqualToString:@""]) {
            [[BTLogger sharedLogger] critical:@"iDEAL requires a return URL scheme to be configured via [BTAppSwitch setReturnURLScheme:]"];
            NSError *error = [NSError errorWithDomain:BTPaymentFlowDriverErrorDomain
                                                 code:BTPaymentFlowDriverErrorTypeInvalidReturnURL
                                             userInfo:@{NSLocalizedDescriptionKey: @"UIApplication failed to perform app or browser switch."}];
            [delegate onPaymentComplete:nil error:error];
            return;
        } else if (idealRequest.amount == nil) {
            [[BTLogger sharedLogger] critical:@"BTIdealRequest amount, currency, issuer and orderId can not be nil."];
            NSError *error = [NSError errorWithDomain:BTPaymentFlowDriverErrorDomain
                                                 code:BTPaymentFlowDriverErrorTypeIntegration
                                             userInfo:@{NSLocalizedDescriptionKey: @"Failed to begin iDEAL payment flow: BTIdealRequest amount, currency, issuer and orderId can not be nil."}];
            [delegate onPaymentComplete:nil error:error];
            return;
        }

        
        NSMutableDictionary *params = [@{
                                 @"amount": idealRequest.amount,
                                 @"funding_source": @"ideal",
                                 @"intent": @"sale"
                                 } mutableCopy];

        params[@"return_url"] = [NSString stringWithFormat:@"%@%@", [delegate returnURLScheme], @"://x-callback-url/braintree/ideal/success"];
        params[@"cancel_url"] = [NSString stringWithFormat:@"%@%@", [delegate returnURLScheme], @"://x-callback-url/braintree/ideal/cancel"];

        if (idealRequest.address) {
            params[@"line1"] = idealRequest.address.streetAddress;
            params[@"line2"] = idealRequest.address.extendedAddress;
            params[@"city"] = idealRequest.address.locality;
            params[@"state"] = idealRequest.address.region;
            params[@"postal_code"] = idealRequest.address.postalCode;
            params[@"country_code"] = idealRequest.address.countryCodeAlpha2;
        }

        if (idealRequest.currencyCode) {
            params[@"currency_iso_code"] = idealRequest.currencyCode;
        }

        if (idealRequest.firstName) {
            params[@"first_name"] = idealRequest.firstName;
        }

        if (idealRequest.lastName) {
            params[@"last_name"] = idealRequest.lastName;
        }

        if (idealRequest.email) {
            params[@"payer_email"] = idealRequest.email;
        }

        if (idealRequest.phone) {
            params[@"phone"] = idealRequest.phone;
        }

        [apiClient POST:@"v1/paypal_hermes/create_payment_resource"
                   parameters:params
                   completion:^(BTJSON *body, __unused NSHTTPURLResponse *response, NSError *error) {
             if (!error) {
                 BTIdealResult *idealResult = [[BTIdealResult alloc] init];
                 idealResult.idealId = [body[@"paymentResource"][@"paymentToken"] asString];
                 self.idealId = idealResult.idealId;
                 NSString *approvalUrl = [body[@"paymentResource"][@"redirectUrl"] asString];
                 NSURL *url = [NSURL URLWithString:approvalUrl];
                 if (self.idealPaymentFlowDelegate) {
                     [self.idealPaymentFlowDelegate idealPaymentStarted:idealResult];
                 }
                 [delegate onPaymentWithURL:url error:error];
             } else {
                 [delegate onPaymentWithURL:nil error:error];
             }
         }];
    }];
}

- (void)handleOpenURL:(__unused NSURL *)url {
    BTPaymentFlowDriver *paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:[self.paymentFlowDriverDelegate apiClient]];
    [paymentFlowDriver checkStatus:self.idealId completion:^(BTPaymentFlowResult * _Nonnull result, NSError * _Nonnull error) {
        [self.paymentFlowDriverDelegate onPaymentComplete:result error:error];
    }];
}

- (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/ideal"];
}

- (NSString *)paymentFlowName {
    return @"ideal";
}

@end
