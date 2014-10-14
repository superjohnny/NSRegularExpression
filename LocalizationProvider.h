//
//  LocalizationProvider.h
//  Venere
//
//  Created by John Green on 27/11/2012.
//
//

#import <Foundation/Foundation.h>

@interface LocalizationProvider : NSObject

+ (NSString *) stringForKey:(NSString *)key withDefault:(NSString *)defaultString;
+ (NSString *) stringForKey:(NSString *)key withDefault:(NSString *)defaultString andReplacements:(NSDictionary *) replacements;
+ (NSString *) currencySymbolForCurrencyCode:(NSString *) code;
+ (void) loadTranslationsFile;
+ (void) getChanges;


+ (LocalizationProvider *) sharedProvider ;

@property (nonatomic, readonly, strong) NSString *valueAddFreeTitle;

@end
