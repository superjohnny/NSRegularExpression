//
//  ExpandingTextCell.m
//  Venere
//
//  Created by John Green on 22/07/2013.
//
//

#import "ExpandingTextCell.h"
#import "UILabel+Extension.h"
#import "UIView+Extension.h"

#define H_PADDING 15
#define W_PADDING 20

@implementation ExpandingTextCell {
    BOOL _expanded;
    int _minTextHeight;
    int _maxTextHeight;
    int _minLines;
    int _maxLines;
}

static UIFont *font = nil;

+ (float) measureMinCellHeight:(NSString *) text withWidth:(float) width {
    //find height of cell for font
    
    width -= W_PADDING;
    width -= W_PADDING;
    
    CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(width, 33) lineBreakMode:NSLineBreakByWordWrapping];
    
    return size.height + H_PADDING + H_PADDING;
}

+ (void) initialize {
    if (self == [ExpandingTextCell class] ) {
        font = [UIFont systemFontOfSize:12];
    }
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
        
        [self.contentView addGestureRecognizer:tap];
        _expanded = NO;
        
    }
    return self;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

-(void) didTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.delegate != nil)
        [self.delegate didTapExpandingTextCell:self];
}

- (void) updateWithText:(NSString *) text andMinHeight:(CGFloat) minHeight {
    self.textLabel.font = font;
    self.textLabel.text = text;
    
    NSNumber * minHeightForText = [NSNumber numberWithFloat:minHeight - (H_PADDING * 2)];
    
    //how many lines fit the min height
    _minLines = [self.textLabel measureLinesForMaxHeight:&minHeightForText andWidth:self.textLabel.frame.size.width];
    _minTextHeight = [minHeightForText floatValue];
    
    
    //how big must it be to show all the text
    //this is the max height
    NSNumber * maxHeightForText = [NSNumber numberWithInt: 2000];
    _maxLines = [self.textLabel measureLinesForMaxHeight:&maxHeightForText andWidth:self.textLabel.frame.size.width];
    
    _maxTextHeight = [maxHeightForText floatValue];
    
    self.textLabel.numberOfLines = _minLines;
    
    _expanded = NO;
    /*
    if (_expanded)
        [self.textLabel resizeHeight:_maxTextHeight];
    else
        [self.textLabel resizeHeight:_minTextHeight];
     */
}

- (void) toggleExpanded {
    _expanded = !_expanded;
    
    //resize the text view
    self.textLabel.numberOfLines = _expanded ? _maxLines : _minLines;
    //[self.textLabel resizeHeight:_expanded ? _maxTextHeight : _minTextHeight];

}

- (NSNumber *) MaxHeight {
    return [NSNumber numberWithFloat: (_expanded ? _maxTextHeight : _minTextHeight) + ( H_PADDING * 2 ) ];
}
@end
