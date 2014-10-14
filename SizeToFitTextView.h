//
//  SizeToFitTextView.h
//  AttributedStrings
//
//  Created by John Green on 31/01/2014.
//  Copyright (c) 2014 Compsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SizeToFitTextView : UITextView

/*!
 *  @abstract Measure the size of the string constrained by given width
 *
 *  @discussion
 *  If the string contains styles they are extracted but not applied as the font size does not change.
 */
+ (CGSize) measureSizeForString:(NSString *) string withWidth:(CGFloat) width;

/*!
 *  @abstract Measure the size of the attributed string constrained by given width
 *
 *  @discussion
 *  If the attributed string has styles the are ignored as the font size will not change.
 */
+ (CGSize) measureSizeForAttributedString:(NSAttributedString *) attributedString withWidth:(CGFloat) width;

/*!
 @property maxWidth
 
 @abstract Defines the max width of the UITextView
 */
@property (nonatomic) CGFloat maxWidth;


@end


/*!
 @header RichTextComponent
 @abstract   Represents the style component for application to an NSAttributedString
 */

/*!
 *  @class RichTextExtractedComponent
 *  @abstract   Represents the style component for application to an NSAttributedString
 *
 *  @discussion
 */
@interface RichTextComponent : NSObject
@property (nonatomic, assign) int componentIndex;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *tagLabel;
@property (nonatomic) NSMutableDictionary *attributes;
@property (nonatomic, assign) int position;

/*!
 *  @abstract Initialize with string
 *
 *  @discussion
 *  Initialize with string
 */
- (id)initWithString:(NSString*)string andTag:(NSString*)tag andAttributes:(NSMutableDictionary*)attributes;

/*!
 *  @abstract Creates instance initialized with string
 *
 *  @discussion
 *  Creates instance initialized with string
 */
+ (id)componentWithString:(NSString*)string andTag:(NSString*)tag andAttributes:(NSMutableDictionary*)attributes;

/*!
 *  @abstract Initialize with tag
 *
 *  @discussion
 *  Initialize with tag
 */
- (id)initWithTag:(NSString*)tag atPosition:(int)position andAttributes:(NSMutableDictionary*)attributes;

/*!
 *  @abstract Creates instance initialized with tag
 *
 *  @discussion
 *  Creates instance initialized with tag
 */
+ (id)componentWithTag:(NSString*)tag atPosition:(int)position andAttributes:(NSMutableDictionary*)attributes;

@end

/*!
 @header RichTextExtractedComponent
 @abstract   Represents plain text and text styling components to create a rich text representation
 */

/*!
 *  @class RichTextExtractedComponent
 *  @abstract Represents data required to create rich text
 *
 *  @discussion
 */
@interface RichTextExtractedComponent : NSObject

/*!
 *  @abstract Style components
 *
 *  @discussion
 *  Use these to apply the styles at the correct locations
 */
@property (nonatomic, strong) NSMutableArray *textComponents;

/*!
 *  @abstract Plain text version of the process text
 *
 *  @discussion
 *  The plain text version of the text without the style markup
 */
@property (nonatomic, copy) NSString *plainText;

/*!
 *  @abstract Initializes an instance with given parameters
 *
 *  @discussion
 */
+ (RichTextExtractedComponent*) extractComponentsWithTextComponent:(NSMutableArray*)textComponents plainText:(NSString*)plainText;

/*!
 *  @abstract Process the supplied string
 *
 *  @discussion
 *  Parses the style information and compiles the text style components
 */
+ (RichTextExtractedComponent*) extractTextStyleFromText:(NSString*)data;
@end


@interface NSString (RichTextStringExtension)
/*!
 *  @abstract Formats the rich text for new lines
 *
 *  @discussion
 *  Removes occurances of rich text new line (<br>) to plane text new line (\n)
 */
- (NSString *)formatNewLines;
@end
