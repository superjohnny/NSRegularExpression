//
//  VenereValidationUtils.h
//  Venere
//
//  Created by David Taylor on 14/08/2013.
//
//
// Validation taken from https://docs.google.com/spreadsheet/ccc?key=0AmnaguHIf6JjdFZuUnVtbnRLMWVxR3c3VF8ySkZCTWc#gid=0

#import <Foundation/Foundation.h>

@interface VenereValidationUtils : NSObject

// Name
+ (BOOL)nameTitleless:(NSString *)name;
+ (BOOL)nameTitleless:(NSString *)name message:(NSString **)message;
+ (BOOL)firstNameValid:(NSString *)name;
+ (BOOL)firstNameValid:(NSString *)name message:(NSString **)message;
+ (BOOL)lastNameValid:(NSString *)name;
+ (BOOL)lastNameValid:(NSString *)name message:(NSString **)message;

// Email
+ (BOOL)emailValid:(NSString *)email;
+ (BOOL)emailValid:(NSString *)email message:(NSString **)message;

// Phone Number
+ (BOOL)phoneNumberValid:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix;
+ (BOOL)phoneNumberValid:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix message:(NSString **)message;
+ (BOOL)phoneNumberCorrectLength:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix;
+ (BOOL)phoneNumberCorrectLength:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix message:(NSString **)message;

// Address
+ (BOOL)postalCodeValid:(NSString *)postalCode forCountryCode:(NSString *)countryCode;
+ (BOOL)postalCodeValid:(NSString *)postalCode forCountryCode:(NSString *)countryCode message:(NSString **)message;

// Credit Card
+ (NSString *)ccTypeFromCCNumber:(NSString *)ccNumber message:(NSString **)message;
+ (BOOL)ccNumberValid:(NSString *)ccNumber ccType:(NSString *)ccType;
+ (BOOL)ccNumberValid:(NSString *)ccNumber ccType:(NSString *)ccType message:(NSString **)message;
+ (BOOL)ccCVVNumberValid:(NSString *)ccCVVNumber ccType:(NSString *)ccType;
+ (BOOL)ccCVVNumberValid:(NSString *)ccCVVNumber ccType:(NSString *)ccType message:(NSString **)message;
+ (BOOL)ccExpiryDateValidMonth:(NSNumber *)month year:(NSNumber *)year andAfterCheckIn:(NSDate *) checkInDate;
+ (BOOL)ccExpiryDateValidMonth:(NSNumber *)month year:(NSNumber *)year andAfterCheckIn:(NSDate *) checkInDate message:(NSString **)message;
+ (BOOL)ccCountryIssuedValid:(NSString *)ccCountryIssued;
+ (BOOL)ccCountryIssuedValid:(NSString *)ccCountryIssued message:(NSString **)message;

@end
