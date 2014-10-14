//
//  LocalizationProvider.m
//  Venere
//
//  Created by John Green on 27/11/2012.
//
//

#import "LocalizationProvider.h"
#import "VenereContext.h"
#import "Settings.h"
#import "CmsEngine.h"
#import "CmsVersionChange.h"
#import "AppDelegate.h"

@implementation LocalizationProvider
{
    NSMutableDictionary *_translations;
}


#pragma mark - Static methods

/*!
 * @discussion
 * gets translated value for key for the current language
 */
+ (NSString *) stringForKey:(NSString *)key withDefault:(NSString *)defaultString {
    
    LocalizationString *ls = [VenereContext localizationStringForLanguage:[Settings getLanguageCode] andKey:key];
    
    if (ls)
        return ls.value;
    else
    {

#ifdef DEBUG
        //for debug return the key for missing translations
        return key; //defaultString;
#endif
        
        //for release, fall back to EN then blank
        ls = [VenereContext localizationStringForLanguage:@0 andKey:key];//try for english
        return ls ? ls.value : @"";
    }
}

/*!
 * @discussion
 * gets translated value for key for the current language, with the replacements supplied in dictionary
 * Just use the replacement key without the % demarkations
 */
+ (NSString *) stringForKey:(NSString *)key withDefault:(NSString *)defaultString andReplacements:(NSDictionary *) replacements {
    
    NSString *translation = [self stringForKey:key withDefault:defaultString];//get translation from provider
    
    NSMutableString *output = [NSMutableString stringWithString:translation]; //mutable version to replace
    
    //regex to extract replacement fields
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"(%([a-zA-Z_]+)%)"  options:kNilOptions error:&error];
    
    NSArray *matches = [regex matchesInString:translation options:kNilOptions range:NSMakeRange(0, [translation length])];//extract
    
    for (NSTextCheckingResult *match in matches) {
        //extract the string to replace
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchReplacement = [translation substringWithRange:matchRange];
        //extract the key to find replacement in replacement dictionary
        matchRange = [match rangeAtIndex:2];
        NSString *matchKey = [translation substringWithRange:matchRange];
        
        //perform replacement
        NSObject *replacement = [replacements objectForKey:matchKey];
        if (replacement != nil) {
            [output replaceOccurrencesOfString: matchReplacement withString:[NSString stringWithFormat:@"%@", replacement] options:NSCaseInsensitiveSearch range:(NSRange) {0, [output length]}];
        }
    }
    
    return output;
}

/*!
 * @discussion
 * gets the currency symbol for the given currency code.
 * caches the result for repeated accessing of the same code.
 */
+ (NSString *) currencySymbolForCurrencyCode:(NSString *) currencyCode {
    static NSString *currentCurrencyCode = nil;
    static NSString *currentCurrencySymbol = nil;
    
    if (![currencyCode isEqualToString: currentCurrencyCode]) {
        Currency *currency = [VenereContext getCurrencyForCode:currencyCode];
        if (currency) {
            currentCurrencySymbol = currency.currencySymbol;
            currentCurrencyCode = [currencyCode copy];
        }
    }
    return currentCurrencySymbol;
    
}

+ (void) loadTranslationsFile {
    
    DLog();
    
    //if file exists
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"translations.csv"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        NSError *error = nil;
        
        //read in new file
        NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        
        NSArray *langs = [VenereContext getLanguages];
        NSMutableDictionary *langKeys = [NSMutableDictionary new];
        for (Language *lang in langs) {
            [langKeys setObject:lang.languageEnumId forKey:[lang.languageCode uppercaseString]];
        }
        
        
        if (error == nil) {
            //parse file
            NSArray *rows = [fileContent componentsSeparatedByString:@"\n"];
            
            for (NSString *row in rows) {
                NSArray *items = [row componentsSeparatedByString:@"|"]; //need to cater for values containing commas
                
                //replace / update
                if (items.count == 3) {
                    NSString *key = [items objectAtIndex:0];
                    NSString *langCode = [[items objectAtIndex:1] uppercaseString];
                    NSString *value = [items objectAtIndex:2];
                    
                    DLog(@"updating %@", key);
                    
                    NSNumber *langEnumId = [langKeys objectForKey:langCode];
                    if (langEnumId)
                        [VenereContext updateLocalizationStringForLanguage:langEnumId andKey:key withValue:value];
                }
            }
            
            
            //delete file
            [[NSFileManager defaultManager]removeItemAtPath:filePath error:&error];
            
            //mark the translation version as > 0 to stop it loading them again
            [Settings setLastVersionChange:1];
        }
        
    }
    
    
}


+ (void) getChanges {
    //update the translations from the cms service based on the last update held
    
    static MKNetworkOperation *currentOperation;
    [currentOperation cancel];
    
    currentOperation = [ApplicationDelegate.cmsEngine changesSinceVersion: [NSNumber numberWithInt: [Settings getLastVersionChange]] completionBlock: ^(NSArray *results) {
        
        __block NSArray *blockResults = results;
        
        [ApplicationDelegate.sharedQueue addOperationWithBlock:^{
            
            int version = [Settings getLastVersionChange];
            //update each change
            for (CmsVersionChange *change in blockResults) {
                DLog(@"change :%@\t%@\t%@", change.VersionId, change.Key, change.Language);
                
                //update
                [VenereContext updateLocalizationStringForLanguage:change.Language andKey:change.Key withValue:change.Value];
                
                if ([change.VersionId intValue] > version)
                    version = [change.VersionId intValue];
                
            }
            
            //update the last version received
            [Settings setLastVersionChange:version];
            
            
            //if there are changes returned, then there maybe some more. Keep trying until we are fully up to date
            if (results && results.count > 0) {
                
                //                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
                
                //                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_TRANSLATIONS object:nil];
                //                });
            }
        }];
        
        
    } onError:^(NSError *error) {
        
        DLog(@"Error");
        
    }];
}


#pragma mark - Singleton accessor

+ (LocalizationProvider *) sharedProvider {
    static LocalizationProvider *sharedProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProvider = [[self alloc] init];
    });
    return sharedProvider;
}


#pragma mark - instance methods

- (id) init {
    if (self == [super init]) {
        
        _translations = [NSMutableDictionary new];
        
        //attach notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChanged) name:NOTIFICATION_LANGUAGE_CHANGED object:nil];
    }
    return self;
}

#pragma mark - private methods

- (void) languageChanged {
    [_translations removeAllObjects];
}

#pragma mark - properties

- (NSString *) valueAddFreeTitle {
    NSString *value = [_translations objectForKey:@"ValueAddFreeTitle"];
    
    if (!value)
        [_translations setObject:[LocalizationProvider stringForKey:@"FREE_DISCLAIMER" withDefault:@"Free"]
                          forKey:@"ValueAddFreeTitle"];
    return value;
}



@end
