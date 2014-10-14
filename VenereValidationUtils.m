//
//  VenereValidationUtils.m
//  Venere
//
//  Created by David Taylor on 14/08/2013.
//
//

#import "VenereValidationUtils.h"
#import "LocalizationProvider.h"
#import "NSString+Extension.h"

@implementation VenereValidationUtils

#pragma mark - Name

+ (BOOL)nameTitleless:(NSString *)name {
    NSString *msg;
    return [VenereValidationUtils nameTitleless:name message:&msg];
}
+ (BOOL)nameTitleless:(NSString *)name message:(NSString **)message
{    
    NSRange range = [name rangeOfString:@"^((\b((mrs?)|miss|ms|dr|phd|rev)\\b)\\.?)|(\b(inc|(co(mpany)?)|llc|lp|ltd)\b)\\.?\\s*$" options:NSRegularExpressionSearch];
    
    if (range.location != NSNotFound) {
        *message = [LocalizationProvider stringForKey:@"GUEST_WITH_TITLE" withDefault:@"Please delete title (i.e. Mr or Dr) from full name"];
    }
    return message == nil;
}
+ (BOOL)firstNameValid:(NSString *)name {
    NSString *msg;
    return [VenereValidationUtils firstNameValid:name message:&msg];
}
+ (BOOL)firstNameValid:(NSString *)name message:(NSString **)message
{
    if ([NSString isNilOrEmpty:name]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_FIRST_NAME_EMPTY" withDefault:@"Enter guest first name"];
        return NO;
    }
    
    NSMutableCharacterSet *goodSet = [[NSCharacterSet letterCharacterSet] mutableCopy];
    [goodSet addCharactersInString:@" -'`"]; //include special name chars
    NSCharacterSet *badSet = [goodSet invertedSet];
    if ([name rangeOfCharacterFromSet:badSet].location != NSNotFound || [name length] < 2) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_FIRST_NAME_WRONG_FORMAT" withDefault:@"First name should contain at least two letters and no punctuation"];
    }
    
    return [NSString isNilOrEmpty:*message];
}
+ (BOOL)lastNameValid:(NSString *)name {
    NSString *msg;
    return [VenereValidationUtils lastNameValid:name message:&msg];
}
+ (BOOL)lastNameValid:(NSString *)name message:(NSString **)message
{
    if ([NSString isNilOrEmpty:name]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_LAST_NAME_EMPTY" withDefault:@"Enter guest last name"];
        return NO;
    }
    
    BOOL isValid = YES;
    
    // Most of the rules are the same as those for first names
    [self firstNameValid:name message:message];
    if (*message != nil) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_LAST_NAME_WRONG_FORMAT" withDefault:@"Last name should contain at least two letters and no punctuation"];
    }
    
    if ([name length] > 0) {
        // The first Character must be a letter
        NSString *firstChar = [name substringToIndex:1];
        if ([firstChar rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound) {
            isValid = NO;
        }
    }
    
    // Must not contain \ or .
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"\\."];
    if ([name rangeOfCharacterFromSet:set].location != NSNotFound) {
        isValid = NO;
    }
    
    if (!isValid) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_LAST_NAME_WRONG_FORMAT" withDefault:@"Last name should contain at least two letters and no punctuation"];
    }
    
    return isValid;
}


#pragma mark - Email

+ (BOOL)emailValid:(NSString *)email {
    NSString *msg;
    return [VenereValidationUtils emailValid:email message:&msg];
}
+ (BOOL)emailValid:(NSString *)email message:(NSString **)message
{
    if ([NSString isNilOrEmpty:email]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_EMAIL_EMPTY" withDefault:@"Enter valid guest email address"];
        return NO;
    }
    
    BOOL isValid = YES;

    // Check that email is between 5 and 50 characters long
    if ([email length] < 5 || [email length] > 50) {
        isValid = NO;
    }
    
    // Check regex
    NSRange range = [email rangeOfString:@"^[a-z0-9!#$%&'*+\\/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+\\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2}(?:[a-z]*[a-z])?$" options:NSCaseInsensitiveSearch | NSRegularExpressionSearch];

    if (range.location == NSNotFound)
        isValid = NO;
    

    
    // Check that the email only contains one @
    range = [email rangeOfString:@"@" options:0];
    if (range.location != NSNotFound) {
        range = NSMakeRange(range.location + range.length, [email length] - (range.location + range.length));
        range = [email rangeOfString:@"@" options:0 range:range];
        if (range.location != NSNotFound) {
            isValid = NO;
        }
    }
    
    if (!isValid) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_GUEST_EMAIL_WRONG_FORMAT" withDefault:@"Address not valid (e.g. name@domain.com)"];
    }
    
    return isValid;
}

#pragma mark - Phone Number

+ (BOOL)phoneNumberValid:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix {
    NSString *msg;
    return [VenereValidationUtils phoneNumberValid:phoneNumber phonePrefix:phonePrefix message:&msg];
}
+ (BOOL)phoneNumberValid:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix message:(NSString **)message
{
    if ([NSString isNilOrEmpty:phoneNumber]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_PHONE_EMPTY" withDefault:@"Enter phone number without country code"];
        return NO;
    }
    
    BOOL isValid = YES;
    
    if ([phonePrefix isEqualToString:@"+1"] && phoneNumber.length > 2) {
        NSString *firstThreeDigits = [phoneNumber substringToIndex:3];
        if ([firstThreeDigits isEqualToString:@"555"]) {
            isValid = NO;
        }
    }
    
    NSMutableCharacterSet *goodSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    [goodSet addCharactersInString:@"-\\/+ "];
    
    NSCharacterSet *badSet = [goodSet invertedSet];
    if ([phoneNumber rangeOfCharacterFromSet:badSet].location != NSNotFound) {
        isValid = NO;
    }
    
    if ([phoneNumber length] > 2) {
        NSCharacterSet *set = [[NSCharacterSet characterSetWithCharactersInString:[phoneNumber substringToIndex:1]] invertedSet];
        if ([phoneNumber rangeOfCharacterFromSet:set options:0 range:NSMakeRange(1, [phoneNumber length] - 1)].location == NSNotFound) {
            isValid = NO;
        }
    }
    
    if (!isValid) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_PHONE_WRONG_FORMAT" withDefault:@"Phone number should contain only digits, no letters or punctuation marks"];
    }
    
    return isValid;
}

+ (BOOL)phoneNumberCorrectLength:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix {
    NSString *msg;
    return [VenereValidationUtils phoneNumberCorrectLength:phoneNumber phonePrefix:phonePrefix message:&msg];
}
+ (BOOL)phoneNumberCorrectLength:(NSString *)phoneNumber phonePrefix:(NSString *)phonePrefix message:(NSString **)message
{
    if ([NSString isNilOrEmpty:phoneNumber]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_PHONE_EMPTY" withDefault:@"Enter phone number without country code"];
        return NO;
    }
    
    BOOL isValid = YES;

    if ([phoneNumber length] > 25) {
        isValid = NO;
    }
    
    if ([phonePrefix isEqualToString:@"+1"]) {
        if ([phoneNumber length] < 10) {
            isValid = NO;
        }
    } else {
        if ([phoneNumber length] < 7) {
            isValid = NO;
        }
    }
    
    if (!isValid) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_PHONE_WRONG_FORMAT" withDefault:@"Phone number should contain only digits, no letters or punctuation marks"];
    }
    
    return isValid;
}

#pragma mark - Address
+ (BOOL)postalCodeValid:(NSString *)postalCode forCountryCode:(NSString *)countryCode {
    NSString *msg;
    return [VenereValidationUtils postalCodeValid:postalCode forCountryCode:countryCode message:&msg];
}
+ (BOOL)postalCodeValid:(NSString *)postalCode forCountryCode:(NSString *)countryCode message:(NSString **)message
{
    BOOL isValid = YES;

    if ([countryCode isEqualToString:@"US"]) {
        // US ZipCodes are between 5 and 10 characters long
        if ([postalCode length] < 5 || [postalCode length] > 10) {
            isValid = NO;
        }
    
        // US ZipCodes only contain numbers and dashes
        NSMutableCharacterSet *goodSet = [NSMutableCharacterSet decimalDigitCharacterSet];
        [goodSet addCharactersInString:@"-"];
        
        NSCharacterSet *badSet = [goodSet invertedSet];
        if ([postalCode rangeOfCharacterFromSet:badSet].location != NSNotFound) {
            isValid = NO;
        }
    } else if ([countryCode isEqualToString:@"CA"]) {
        
        if ([postalCode length] < 3 || [postalCode length] > 10) {
            isValid = NO;
        }
        
        // Check postal code only has numbers, letters, space and dashes
        NSMutableCharacterSet *goodSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [goodSet addCharactersInString:@" -"];
        
        NSCharacterSet *badSet = [goodSet invertedSet];
        if ([postalCode rangeOfCharacterFromSet:badSet].location != NSNotFound) {
            isValid = NO;
        }
    } else {
        // Non US/Canadian zip codes are not required
        if ([NSString isNilOrEmpty:postalCode]) {
            return YES;
        }
    }
    
    if (!isValid) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_ZIPCODE_WRONG_FORMAT" withDefault:@"Please enter a valid zip code"];
    }
    
    return isValid;
}

#pragma mark - Credit Card
+ (NSString *)ccTypeFromCCNumber:(NSString *)ccNumber {
    NSString *msg;
    return [VenereValidationUtils ccTypeFromCCNumber:ccNumber message:&msg];
}
+ (NSString *)ccTypeFromCCNumber:(NSString *)ccNumber message:(NSString **)message
{
    if ([self isValidCCNumber:ccNumber regex:@"^(34[0-9]{13}|37[0-9]{13})$"]) {
        return CC_TYPE_AMEX;
    }
    
    if ([self isValidCCNumber:ccNumber regex:@"^(30[0-5][0-9]{11}|309[0-9]{11}|36[0-9]{12}|38[0-9]{12}|39[0-9]{12})$"]) {
        return CC_TYPE_DINERS;
    }
    
    if ([self isValidCCNumber:ccNumber regex:@"^(60[0-9]{14}|62[0-9]{14}|6[4-5][0-9]{14}|60[0-9]{17}|62[0-9]{17}|6[4-5][0-9]{17})$"]) {
        return CC_TYPE_DISCOVER;
    }
    
    if ([self isValidCCNumber:ccNumber regex:@"^(35[0-9]{13}|35[0-9]{14})$"]) {
        return CC_TYPE_JCB;
    }
    
    if ([self isValidCCNumber:ccNumber regex:@"^(5[1-5][0-9]{14})$"]) {
        return CC_TYPE_MASTERCARD;
    }
    
    if ([self isValidCCNumber:ccNumber regex:@"^(4[0-9]{12}|4[0-9]{15})$"]) {
        return CC_TYPE_VISA;
    }
    
    if ([self isValidCCNumber:ccNumber regex:@"^(5018[0-9]{8}|5020[0-9]{8}|5038[0-9]{8}|5893[0-9]{8}|6304[0-9]{8}|6759[0-9]{8}|676[1-3][0-9]{8}|0604[0-9]{8}|5018[0-9]{9}|5020[0-9]{9}|5038[0-9]{9}|5893[0-9]{9}|6304[0-9]{9}|6759[0-9]{9}|676[1-3][0-9]{9}|0604[0-9]{9}|5018[0-9]{10}|5020[0-9]{10}|5038[0-9]{10}|5893[0-9]{10}|6304[0-9]{10}|6759[0-9]{10}|676[1-3][0-9]{10}|0604[0-9]{10}|5018[0-9]{11}|5020[0-9]{11}|5038[0-9]{11}|5893[0-9]{11}|6304[0-9]{11}|6759[0-9]{11}|676[1-3][0-9]{11}|0604[0-9]{11}|5018[0-9]{12}|5020[0-9]{12}|5038[0-9]{12}|5893[0-9]{12}|6304[0-9]{12}|6759[0-9]{12}|676[1-3][0-9]{12}|0604[0-9]{12}|5018[0-9]{13}|5020[0-9]{13}|5038[0-9]{13}|5893[0-9]{13}|6304[0-9]{13}|6759[0-9]{13}|676[1-3][0-9]{13}|0604[0-9]{13}|5018[0-9]{14}|5020[0-9]{14}|5038[0-9]{14}|5893[0-9]{14}|6304[0-9]{14}|6759[0-9]{14}|676[1-3][0-9]{14}|0604[0-9]{14}|5018[0-9]{15}|5020[0-9]{15}|5038[0-9]{15}|5893[0-9]{15}|6304[0-9]{15}|6759[0-9]{15}|676[1-3][0-9]{15}|0604[0-9]{15})$"]) {
        return CC_TYPE_MASTERCARD;
    }
    
    // No card type found so the card number must have been entered incorrectly
    *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_NUMBER_EMPTY" withDefault:@"Enter card number (no punctuation or spaces)"];
    
    return nil;
}

+ (BOOL)isValidCCNumber:(NSString *)ccNumber regex:(NSString *)regex
{
    NSRange range = [ccNumber rangeOfString:regex options:NSRegularExpressionSearch];
    
    if (range.location == NSNotFound) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)ccNumberValid:(NSString *)ccNumber ccType:(NSString *)ccType {
    NSString *msg;
    return [VenereValidationUtils ccNumberValid:ccNumber ccType:ccType message:&msg];
}
+ (BOOL)ccNumberValid:(NSString *)ccNumber ccType:(NSString *)ccType message:(NSString **)message
{
    if ([NSString isNilOrEmpty:ccNumber]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_NUMBER_EMPTY" withDefault:@"Enter card number (no punctuation or spaces)"];
        return NO;
    }
    
    if (![self doesCCNumberPassLuhnCheck:ccNumber]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_NUMBER_WRONG_FORMAT" withDefault:@"Card number should contain only digits, no spaces or punctuation marks"];
        return NO;
    }
    
    NSString *regex;
    if ([ccType isEqualToString:CC_TYPE_AMEX]) {
        regex = @"^(34[0-9]{13}|37[0-9]{13})$";
    } else if ([ccType isEqualToString:CC_TYPE_DINERS]) {
        regex = @"^(30[0-5][0-9]{11}|309[0-9]{11}|36[0-9]{12}|38[0-9]{12}|39[0-9]{12})$";
    } else if ([ccType isEqualToString:CC_TYPE_DISCOVER]) {
        regex = @"^(60[0-9]{14}|62[0-9]{14}|6[4-5][0-9]{14}|60[0-9]{17}|62[0-9]{17}|6[4-5][0-9]{17})$";
    } else if ([ccType isEqualToString:CC_TYPE_JCB]) {
        regex = @"^(35[0-9]{13}|35[0-9]{14})$";
    } else if ([ccType isEqualToString:CC_TYPE_MASTERCARD]) {
        // This regex is MasterCard and MAESTRO combined
        regex = @"^(5[1-5][0-9]{14}|5018[0-9]{8}|5020[0-9]{8}|5038[0-9]{8}|5893[0-9]{8}|6304[0-9]{8}|6759[0-9]{8}|676[1-3][0-9]{8}|0604[0-9]{8}|5018[0-9]{9}|5020[0-9]{9}|5038[0-9]{9}|5893[0-9]{9}|6304[0-9]{9}|6759[0-9]{9}|676[1-3][0-9]{9}|0604[0-9]{9}|5018[0-9]{10}|5020[0-9]{10}|5038[0-9]{10}|5893[0-9]{10}|6304[0-9]{10}|6759[0-9]{10}|676[1-3][0-9]{10}|0604[0-9]{10}|5018[0-9]{11}|5020[0-9]{11}|5038[0-9]{11}|5893[0-9]{11}|6304[0-9]{11}|6759[0-9]{11}|676[1-3][0-9]{11}|0604[0-9]{11}|5018[0-9]{12}|5020[0-9]{12}|5038[0-9]{12}|5893[0-9]{12}|6304[0-9]{12}|6759[0-9]{12}|676[1-3][0-9]{12}|0604[0-9]{12}|5018[0-9]{13}|5020[0-9]{13}|5038[0-9]{13}|5893[0-9]{13}|6304[0-9]{13}|6759[0-9]{13}|676[1-3][0-9]{13}|0604[0-9]{13}|5018[0-9]{14}|5020[0-9]{14}|5038[0-9]{14}|5893[0-9]{14}|6304[0-9]{14}|6759[0-9]{14}|676[1-3][0-9]{14}|0604[0-9]{14}|5018[0-9]{15}|5020[0-9]{15}|5038[0-9]{15}|5893[0-9]{15}|6304[0-9]{15}|6759[0-9]{15}|676[1-3][0-9]{15}|0604[0-9]{15})$";
    } else if ([ccType isEqualToString:CC_TYPE_VISA]) {
        regex = @"^(4[0-9]{12}|4[0-9]{15})$";
    } else {
        regex = @"^(402360[0-9]{7}|402360[0-9]{10})$";
    }
    
    NSRange range = [ccNumber rangeOfString:regex options:NSRegularExpressionSearch];

    if (range.location == NSNotFound) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_INVALID_CARD_TYPE" withDefault:@"Card type and card number don't match"];
    }
    
    return [NSString isNilOrEmpty:*message];
}

// http://rosettacode.org/wiki/Luhn_test_of_credit_card_numbers#Objective-C
+ (BOOL)doesCCNumberPassLuhnCheck:(NSString *)ccNumber
{
    NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[ccNumber length]];
	for (int i=0; i < [ccNumber length]; i++) {
		NSString *ichar  = [NSString stringWithFormat:@"%c", [ccNumber characterAtIndex:i]];
		[characters addObject:ichar];
	}
    
    NSArray *stringAsChars = [characters copy];
    
	BOOL isOdd = YES;
	int oddSum = 0;
	int evenSum = 0;
    
	for (int i = [ccNumber length] - 1; i >= 0; i--) {
        
		int digit = [(NSString *)[stringAsChars objectAtIndex:i] intValue];
        
		if (isOdd)
			oddSum += digit;
		else
			evenSum += digit/5 + (2*digit) % 10;
        
		isOdd = !isOdd;
	}
    
	return ((oddSum + evenSum) % 10 == 0);
}

+ (BOOL)ccCVVNumberValid:(NSString *)ccCVVNumber ccType:(NSString *)ccType {
    NSString *msg;
    return [VenereValidationUtils ccCVVNumberValid:ccCVVNumber ccType:ccType message:&msg];
}
+ (BOOL)ccCVVNumberValid:(NSString *)ccCVVNumber ccType:(NSString *)ccType message:(NSString **)message
{
    if ([NSString isNilOrEmpty:ccCVVNumber]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_CVV_EMPTY" withDefault:@"Enter CVV code (4 digits for American Express, 3 for all others)"];
        return NO;
    }
    
    NSCharacterSet *set = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    if (([ccType isEqualToString:CC_TYPE_AMEX] && [ccCVVNumber length] != 4) || (![ccType isEqualToString:CC_TYPE_AMEX] && [ccCVVNumber length] != 3) || [ccCVVNumber rangeOfCharacterFromSet:set].location != NSNotFound) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_CVV_WRONG_FORMAT" withDefault:@"Check the security code on the back of your card (last 3 digits, 4 for  American Express)"];
    }
    
    return [NSString isNilOrEmpty:*message];
}

+ (BOOL)ccExpiryDateValidMonth:(NSNumber *)month year:(NSNumber *)year andAfterCheckIn:(NSDate *) checkInDate {
    NSString *msg;
    return [VenereValidationUtils ccExpiryDateValidMonth:month year:year andAfterCheckIn:checkInDate message:&msg];
}
+ (BOOL)ccExpiryDateValidMonth:(NSNumber *)month year:(NSNumber *)year andAfterCheckIn:(NSDate *) checkInDate message:(NSString **)message
{
    if (month == nil || year == nil) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_EXPIRY_DATE_EMPTY" withDefault:@"Select card expiration date"];
        return NO;
    }
    
    NSDate *now = [NSDate new];
    NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:now];
    if ([year integerValue] < dateComponents.year || ([year integerValue] == dateComponents.year && [month integerValue] < dateComponents.month)) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_EXPIRY_DATE_PASSED" withDefault:@"The date you've selected is in the past. Please correct it or check if your card has expired"];
    }
    
    
    //check the expiry date is after the check in date
    NSDateComponents *expiryComponents = [[NSDateComponents alloc] init];
    [expiryComponents setYear:[year integerValue]];
    [expiryComponents setMonth:[month integerValue]];
    
    NSDate *expiryDate = [[NSCalendar currentCalendar] dateFromComponents:expiryComponents];
    
    NSRange daysRange = [[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:expiryDate];
    
    [expiryComponents setDay:daysRange.length];
    
    expiryDate = [[NSCalendar currentCalendar] dateFromComponents:expiryComponents];
    
    if ([expiryDate compare:checkInDate] == NSOrderedAscending) {
        //card expires before checkin
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_EXPIRY_DATE_PASSED" withDefault:@"The date you've selected is in the past. Please correct it or check if your card has expired"];
    }
        
    
    return [NSString isNilOrEmpty:*message];
}

+ (BOOL)ccCountryIssuedValid:(NSString *)ccCountryIssued {
    NSString *msg;
    return [VenereValidationUtils ccCountryIssuedValid:ccCountryIssued message:&msg];
}
+ (BOOL)ccCountryIssuedValid:(NSString *)ccCountryIssued message:(NSString **)message
{
    if ([NSString isNilOrEmpty:ccCountryIssued]) {
        *message = [LocalizationProvider stringForKey:@"BF_BOOKING_FORM_PAYMENT_COUNTRY_EMPTY" withDefault:@"Select country of issue"];
    }
    
    return [NSString isNilOrEmpty:*message];
}

@end
