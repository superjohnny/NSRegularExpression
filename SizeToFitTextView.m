//
//  SizeToFitTextView.m
//  AttributedStrings
//
//  Created by John Green on 31/01/2014.
//  Copyright (c) 2014 Compsoft. All rights reserved.
//

#import "SizeToFitTextView.h"
#import <CoreText/CoreText.h>



@interface SizeToFitTextView()
@property (nonatomic, readonly, weak) UIFont *boldFont;
@property (nonatomic, readonly, weak) UIFont *boldItalicFont;
@property (nonatomic, readonly, weak) UIFont *italicFont;
@end

@implementation SizeToFitTextView

{
    NSString *_text;
    RichTextExtractedComponent *_extractedComponents;
    UIFont *_boldFont, *_boldItalicFont, *_italicFont;
}

#pragma mark - Statics

+ (CGSize) measureSizeForString:(NSString *) string withWidth:(CGFloat) width {
    
    //format the new lines to get the correct amount of lines
    NSString *formatted = [string formatNewLines];
    
    //seperate the styles from the text, so that the height can be established
    RichTextExtractedComponent *extracted = [RichTextExtractedComponent extractTextStyleFromText:formatted];
    
    //seeing as the styles that are applied do not change the line height,
    //we could estimate the height without the styles applied, and just use the plain text
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:extracted.plainText];
    
    return [SizeToFitTextView measureSizeForAttributedString:attributedString withWidth:width];
}

+ (CGSize) measureSizeForAttributedString:(NSAttributedString *) attributedString withWidth:(CGFloat) width {
    
    
    CGRect rect = [attributedString boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    
    //round up to nearest whole size
    return CGSizeMake(ceilf(rect.size.width), ceilf(rect.size.height));
}


#pragma mark - Properties

- (UIFont*)boldFont {
    if (!_boldFont){
        
        CTFontRef fontRef = (__bridge CTFontRef)self.font;
        CTFontRef fontBoldRef = CTFontCreateCopyWithSymbolicTraits(fontRef, 0.0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
        
        if (!fontBoldRef) // fall back
            _boldFont = [UIFont boldSystemFontOfSize:CTFontGetSize(fontRef)];
        else {
            _boldFont = (__bridge UIFont*)fontBoldRef;
            CFRelease(fontBoldRef);
        }
        
    }
    
    return _boldFont;
}

- (UIFont*)boldItalicFont {
    if (!_boldItalicFont){
        
        CTFontRef fontRef = (__bridge CTFontRef)self.font;
        CTFontRef fontBoldItalicRef = CTFontCreateCopyWithSymbolicTraits(fontRef, 0.0, NULL, kCTFontBoldTrait | kCTFontItalicTrait, kCTFontBoldTrait | kCTFontItalicTrait);
        
        if (!fontBoldItalicRef) // fall back
            _boldItalicFont = [UIFont boldSystemFontOfSize:CTFontGetSize(fontRef)];
        else {
            _boldItalicFont = (__bridge UIFont*)fontBoldItalicRef;
            CFRelease(fontBoldItalicRef);
        }
    }
    
    return _boldItalicFont;
}


- (UIFont*)italicFont {
    if (!_italicFont){
        
        CTFontRef fontRef = (__bridge CTFontRef)self.font;
        CTFontRef fontItalicRef = CTFontCreateCopyWithSymbolicTraits(fontRef, 0.0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
        
        if (!fontItalicRef) // fall back
            _italicFont = [UIFont boldSystemFontOfSize:CTFontGetSize(fontRef)];
        else {
            _italicFont = (__bridge UIFont*)fontItalicRef;
            CFRelease(fontItalicRef);
        }
    }
    
    return _italicFont;
}


//
//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    
//    // Need to remove padding from iOS 7+
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
//        self.textContainer.lineFragmentPadding = 0;
//        self.textContainerInset = UIEdgeInsetsZero;
//    }
//}
//
//- (void)layoutSubviews
//{
//    [super layoutSubviews];
//    
//    // Need to remove padding from iOS 6
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0f) {
//        
//        CGFloat textHeight = [self.attributedText boundingRectWithSize:CGSizeMake(self.maxWidth, FLT_MAX) options:NSStringDrawingUsesDeviceMetrics context:NULL].size.height;
//        
//        // There is no constant top or bottom padding values for TextViews so we have to aproximate as best we can
//        CGFloat verticalInset = -ceilf(3.0f * textHeight / 4.0f);
//        CGFloat horizontalInset = -8.0f;
//        self.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
//    }
//    
//    if (!CGSizeEqualToSize(self.bounds.size, [self intrinsicContentSize])) {
//        [self invalidateIntrinsicContentSize];
//    }
//}
//
//- (CGSize)intrinsicContentSize
//{
//    
//    //using the styled text here, maybe slightly different to the static methods as they use
//    //a plain string of an attributed string without the styling applied, and at this point
//    //self.attributedString should have all the styles applied
//    CGSize intrinsicContentSize = [SizeToFitTextView measureSizeForAttributedString:self.attributedText withWidth:FLT_MAX];
//    
//    
//    intrinsicContentSize.width = ceilf(intrinsicContentSize.width) - self.contentInset.left - self.contentInset.right;
//    intrinsicContentSize.height = ceilf(intrinsicContentSize.height);
//    
//    return intrinsicContentSize;
//}


- (void) setText:(NSString *)text {
    
    
    
    //this property can accept mml, but it must only be the body content
    //in order to extract the body content from the mml message use the following:
    /*
     NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<body>(.*)</body>" options:NSRegularExpressionCaseInsensitive error:NULL];
     
     NSTextCheckingResult *match = [regex firstMatchInString:input options:0 range:NSMakeRange(0, [input length])];
     
     NSString *output = [input substringWithRange:[match rangeAtIndex:1]];
     */
    
    
    
    //format rich text new lines as plain text new lines
    _text = [text formatNewLines];
    
    //parse for rich text styles
    _extractedComponents = [RichTextExtractedComponent extractTextStyleFromText:_text];
    
    //apply the styles discovered
    self.attributedText = [self applyStyles];
    
    
    [self setNeedsDisplay];
    
}



- (NSAttributedString *)applyStyles
{
    if (!_extractedComponents.plainText) return nil;
	
	// Initialize an attributed string.
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_extractedComponents.plainText];
    
    UIColor *textColour = self.textColor ? self.textColor : [UIColor blackColor];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:textColour range:NSMakeRange(0, [attributedString length])];
    [attributedString addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, [attributedString length])];
    
    
    
	for (RichTextComponent *component in _extractedComponents.textComponents)
	{
		if ([component.tagLabel caseInsensitiveCompare:@"i"] == NSOrderedSame)
		{
			// make font italic
			[self applyItalicStyleToText:attributedString atPosition:component.position withLength:[component.text length]];
		}
		else if ([component.tagLabel caseInsensitiveCompare:@"b"] == NSOrderedSame)
		{
			// make font bold
			[self applyBoldStyleToText:attributedString atPosition:component.position withLength:[component.text length]];
		}
        else if ([component.tagLabel caseInsensitiveCompare:@"bi"] == NSOrderedSame)
        {
            [self applyBoldItalicStyleToText:attributedString atPosition:component.position withLength:[component.text length]];
        }
        
		// underline
        else if ([component.tagLabel caseInsensitiveCompare:@"u"] == NSOrderedSame)
        {
            [self applySingleUnderlineText:attributedString atPosition:component.position withLength:[component.text length]];
        }
        
        //apply font properties
		else if ([component.tagLabel caseInsensitiveCompare:@"font"] == NSOrderedSame)
		{
			[self applyFontAttributes:component.attributes toText:attributedString atPosition:component.position withLength:[component.text length]];
		}
		
	}
    
    return attributedString;
    
}


#pragma mark - Methods


- (NSArray*)colorForHex:(NSString *)hexColor
{
	hexColor = [[hexColor stringByTrimmingCharactersInSet:
				 [NSCharacterSet whitespaceAndNewlineCharacterSet]
				 ] uppercaseString];
	
    // find rgb values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:[self extractRGBValue:hexColor atLocation:0]] scanHexInt:&r];
    [[NSScanner scannerWithString:[self extractRGBValue:hexColor atLocation:2]] scanHexInt:&g];
    [[NSScanner scannerWithString:[self extractRGBValue:hexColor atLocation:4]] scanHexInt:&b];
	
	NSArray *components = [NSArray arrayWithObjects:[NSNumber numberWithFloat:((float) r / 255.0f)],[NSNumber numberWithFloat:((float) g / 255.0f)],[NSNumber numberWithFloat:((float) b / 255.0f)],[NSNumber numberWithFloat:1.0],nil];
	return components;
}

- (NSString *) extractRGBValue:(NSString *) fromString atLocation:(int) location {
    
    NSRange range;
    range.length = 2;
    range.location = location;
    
    return [fromString substringWithRange:range];
}

#pragma mark - Styling

- (void)applyItalicStyleToText:(NSMutableAttributedString *)text atPosition:(int)position withLength:(NSInteger)length
{
    [text addAttribute:NSFontAttributeName value:self.italicFont range:NSMakeRange(position, length)];
}



- (void)applyFontAttributes:(NSDictionary*)attributes toText:(NSMutableAttributedString *)text atPosition:(int)position withLength:(NSInteger)length {
    for (NSString *key in attributes)
	{
		NSString *value = [attributes objectForKey:key];
		value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
		
		if ([key caseInsensitiveCompare:@"color"] == NSOrderedSame)
		{
			[self applyColor:value toText:text atPosition:position withLength:length];
		}
    }
}

- (void)applyBoldStyleToText:(NSMutableAttributedString *)text atPosition:(int)position withLength:(NSInteger)length {
    [text addAttribute:NSFontAttributeName value:self.boldFont range:NSMakeRange(position, length)];
}


- (void)applyBoldItalicStyleToText:(NSMutableAttributedString *)text atPosition:(int)position withLength:(NSInteger)length {
    [text addAttribute:NSFontAttributeName value:self.boldItalicFont range:NSMakeRange(position, length)];
}

- (void)applySingleUnderlineText:(NSMutableAttributedString *)text atPosition:(int)position withLength:(NSInteger)length
{
    [text addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt: NSUnderlineStyleSingle] range:NSMakeRange(position, length)];
}


- (void)applyColor:(NSString*)value toText:(NSMutableAttributedString *)text atPosition:(int)position withLength:(NSInteger)length
{
	
	if ([value rangeOfString:@"#"].location==0)
	{
		value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
		NSArray *colorComponents = [self colorForHex:value];
        
        UIColor *_colour = [UIColor colorWithRed:[[colorComponents objectAtIndex:0] floatValue]
                                           green:[[colorComponents objectAtIndex:1] floatValue]
                                            blue:[[colorComponents objectAtIndex:2] floatValue]
                                           alpha:1];
        [text addAttribute:NSForegroundColorAttributeName value:_colour range:NSMakeRange(position, length)];
	} else {
		value = [value stringByAppendingString:@"Color"];
		SEL colorSel = NSSelectorFromString(value);
		UIColor *_color = nil;
		if ([UIColor respondsToSelector:colorSel]) {
			_color = [UIColor performSelector:colorSel];
            [text addAttribute:NSForegroundColorAttributeName value:_color range:NSMakeRange(position, length)];
		}
	}
}

@end



@implementation RichTextComponent

- (id)initWithString:(NSString*)string andTag:(NSString*)tag andAttributes:(NSMutableDictionary*)attributes
{
    self = [super init];
	if (self) {
		_text = string;
		_tagLabel = tag;
		_attributes = attributes;
	}
	return self;
}

+ (id)componentWithString:(NSString*)string andTag:(NSString*)tag andAttributes:(NSMutableDictionary*)attributes
{
	return [[self alloc] initWithString:string andTag:tag andAttributes:attributes];
}

- (id)initWithTag:(NSString*)tag atPosition:(int)position andAttributes:(NSMutableDictionary*)attributes
{
    self = [super init];
    if (self) {
        _tagLabel = tag;
		_position = position;
		_attributes = attributes;
    }
    return self;
}

+ (id)componentWithTag:(NSString*)tag atPosition:(int)position andAttributes:(NSMutableDictionary*)attributes
{
	return [[self alloc] initWithTag:tag atPosition:position andAttributes:attributes];
}

- (NSString*)description
{
	NSMutableString *desc = [NSMutableString string];
	[desc appendFormat:@"text: %@", self.text];
	[desc appendFormat:@", position: %i", self.position];
	if (self.tagLabel) [desc appendFormat:@", tag: %@", self.tagLabel];
	if (self.attributes) [desc appendFormat:@", attributes: %@", self.attributes];
	return desc;
}


@end

@implementation RichTextExtractedComponent

+ (RichTextExtractedComponent*) extractComponentsWithTextComponent:(NSMutableArray*)textComponents plainText:(NSString*)plainText
{
    RichTextExtractedComponent *component = [[RichTextExtractedComponent alloc] init];
    [component setTextComponents:textComponents];
    [component setPlainText:plainText];
    return component;
}


+ (RichTextExtractedComponent*) extractTextStyleFromText:(NSString*)data
{
	NSScanner *scanner = nil;
	NSString *text = nil;
	NSString *tag = nil;
	
	NSMutableArray *components = [NSMutableArray array];
	
	NSInteger last_position = 0;
	scanner = [NSScanner scannerWithString:data];
	while (![scanner isAtEnd])
    {
		[scanner scanUpToString:@"<" intoString:NULL];
		[scanner scanUpToString:@">" intoString:&text];
		
		NSString *delimiter = [NSString stringWithFormat:@"%@>", text];
		NSInteger position = [data rangeOfString:delimiter].location;
		if (position!=NSNotFound)
		{
            
            data = [data stringByReplacingOccurrencesOfString:delimiter withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position+delimiter.length-last_position)];
            
			
			data = [data stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
			data = [data stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
		}
		
		if ([text rangeOfString:@"</"].location==0)
		{
			// end of tag
			tag = [text substringFromIndex:2];
			if (position!=NSNotFound)
			{
				for (NSInteger i = [components count] - 1; i >= 0; i--)
				{
					RichTextComponent *component = [components objectAtIndex:i];
					if (component.text==nil && [component.tagLabel isEqualToString:tag])
					{
						NSString *text2 = [data substringWithRange:NSMakeRange(component.position, position-component.position)];
						component.text = text2;
						break;
					}
				}
			}
		}
		else
		{
			// start of tag
			NSArray *textComponents = [[text substringFromIndex:1] componentsSeparatedByString:@" "];
			tag = [textComponents objectAtIndex:0];
			//NSLog(@"start of tag: %@", tag);
			NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
			for (NSUInteger i=1; i<[textComponents count]; i++)
			{
				NSArray *pair = [[textComponents objectAtIndex:i] componentsSeparatedByString:@"="];
				if ([pair count] > 0) {
					NSString *key = [[pair objectAtIndex:0] lowercaseString];
					
					if ([pair count]>=2) {
						// Trim " charactere
						NSString *value = [[pair subarrayWithRange:NSMakeRange(1, [pair count] - 1)] componentsJoinedByString:@"="];
						value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 1)];
						value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange([value length]-1, 1)];
						
						[attributes setObject:value forKey:key];
					} else if ([pair count]==1) {
						[attributes setObject:key forKey:key];
					}
				}
			}
			RichTextComponent *component = [RichTextComponent componentWithString:nil andTag:tag andAttributes:attributes];
			component.position = position;
			[components addObject:component];
		}
		last_position = position;
	}
	
    return [RichTextExtractedComponent extractComponentsWithTextComponent:components plainText:data];
}

@end

@implementation NSString(RichTextStringExtension)

-(NSString *)formatNewLines {
    return [self stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
}

@end
