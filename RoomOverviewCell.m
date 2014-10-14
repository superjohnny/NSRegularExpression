//
//  RoomOverviewCell.m
//  Venere
//
//  Created by John Green on 14/11/2012.
//
//

#import "RoomOverviewCell.h"
#import "NSNumber+Extension.h"
#import "UIView+Animation.h"
#import "UIView+Extension.h"
#import "FormattingProvider.h"
#import "NSString+Extension.h"

#define ROOM_OVERVIEWCELL_MINHEIGHT 24 //the y position of the where the value adds start
#define ANIMATION_DURATION          0.3
#define BOTTOM_MARGIN               10
#define BOOK_BUTTOM_HEIGHT          36
#define VALUE_ADDS_HEIGHT           21
#define DEAL_BANNER_HEIGHT          16
#define PRICE_CONTAINER_HEIGHT      35

@implementation RoomOverviewCell {
    float _minHeight;
    float _maxHeight;
    
    UIView *tappedView;
}

@synthesize delegate;
@synthesize isExpanded = _expanded;

+ (float) measureCellHeight: (RoomResult *) room withWidth:(float) width {
    float height = ROOM_OVERVIEWCELL_MINHEIGHT;
    
//    height += [RoomValueAddsView measureValueAdds:room.valueAdds]; //measure value adds
    height += BOOK_BUTTOM_HEIGHT;
    height += BOTTOM_MARGIN;
    
    //measure blocks
    
    /*
    height += [TitledDetailBlock measureBlock:@"Room" andDetail:room.descr forWidth:width];
    height += [TitledDetailBlock measureBlock:@"Room" andDetail:room.amenities forWidth:width];
    height += [TitledDetailBlock measureBlock:@"Room" andDetail:room.includes forWidth:width];
    height += [TitledDetailBlock measureBlock:@"Room" andDetail:room.cancellationPolicy forWidth:width];
    */
    
    //is there value adds?
    if (room.valueAdds.count > 0){
        height += VALUE_ADDS_HEIGHT;
    }
    
    //is there deals
    if (![NSString isNilOrEmpty:room.deal]) {
        height += DEAL_BANNER_HEIGHT;
    }
    
    height += PRICE_CONTAINER_HEIGHT;
    
    return height;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
        
        [self.contentView addGestureRecognizer:tap];
        
        _expanded = NO;
        self.titledDetailBlock.hidden = !_expanded;
        self.clipsToBounds = YES;

        
        
    }
    return self;
}

- (void) update:(RoomResult *) room andIsExpanded: (BOOL) isExpanded {
    self.titleLabel.text = room.name;
    
    //self.subtitleLabel.text = room.valueAdds;
    [self.priceLabel update:room.priceDisplay andStrikePrice:room.strikePriceDisplay forCurrencySymbol:@"£"];// andDeal:room.deal shouldDisplayDeal:YES];
    self.occupancyLabel.value = [room.maxPersons intValue];
    self.totalPriceDescriptionLabel.text = room.nightsDisplay;
    
    self.roomValueAddsView.text = [self buildValueAdds:room.valueAdds];
    self.roomValueAddsView.hidden = self.roomValueAddsView.text == nil;
    
//    self.dealBanner.text = room.deal;
//    self.dealBanner.hidden = self.dealBanner.text == nil;
//    self.dealBanner.leftMargin = 0;
    
    self.scarcityLabel.text = [FormattingProvider formatScarcity:room.scarcity];
    self.scarcityLabel.hidden = self.scarcityLabel.text == nil;
    
    
    //[self.roomValueAddsView updateWithValueAdds:room.valueAdds];
    //[self.titledDetailBlock moveTop:[self.roomValueAddsView bottom]];
    
    [self.titledDetailBlock clear];
    
    //TODO JCG: Localise
    [self.titledDetailBlock addBlock:@"Room Description" andDetail:room.descr];
    [self.titledDetailBlock addBlock:@"Room Amenities" andDetail:room.amenities];
    [self.titledDetailBlock addBlock:@"Included and Not Included" andDetail:room.includes];
    [self.titledDetailBlock addBlock:@"Cancellation Policy" andDetail:room.cancellationPolicy];
    
    //move items
    [self.dealBanner moveTop:[self.roomValueAddsView bottomIfVisible]];
    [self.priceContainer moveTop:[self.dealBanner bottomIfVisible]];
    [self.titledDetailBlock moveTop:[self.priceContainer bottom]];

    //the book button is anchored to the bottom of the view and so doesnt need moving
    
    
    //establish the min and max heights for this cell
    //_minHeight = ROOM_OVERVIEWCELL_MINHEIGHT + PRICE_CONTAINER_HEIGHT + BOOK_BUTTOM_HEIGHT + BOTTOM_MARGIN;
    _minHeight = [RoomOverviewCell measureCellHeight:room withWidth:self.frame.size.width];
    _maxHeight = [self.titledDetailBlock bottom] + BOTTOM_MARGIN + BOOK_BUTTOM_HEIGHT + BOTTOM_MARGIN;

    _expanded = isExpanded;

    self.titledDetailBlock.hidden = !_expanded; //hide if not expanded
    
}

- (void) toggleExpanded {
    _expanded = !_expanded;
    
    if (_expanded)
        [self.titledDetailBlock fadeIn:ANIMATION_DURATION];
    else
        [self.titledDetailBlock fadeOut:ANIMATION_DURATION];
    
}

- (float) minHeight {
    return _minHeight;
}
- (float) maxHeight {
    //the max height of the cell depending on its expanded state
    if (_expanded)
        return _maxHeight;
    else
        return _minHeight;
}


#pragma mark - Delegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    tappedView = touch.view;
    return YES;
    
}

-(void) didTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
    
    if (self.bookButton == tappedView) {
        tappedView = nil;
        [self.bookButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else {
        if (self.delegate != nil) {
             [self.delegate didTapRoomOverviewCell:self];
        }
           
    }
    
}

#pragma mark - Methods
- (NSString *) buildValueAdds:(NSArray *)valueAdds {

    if (valueAdds.count == 0)
        return nil;
    
    NSMutableArray *lines = [NSMutableArray new];
    
    for (RoomValueAdd *item in valueAdds) {
        [lines addObject:item.label];
    }
    
    return [lines componentsJoinedByString:@", " ];
}

#pragma mark - Actions

- (IBAction)bookButtonPressed:(id)sender {
    if (self.delegate != nil)
        [self.delegate didPressBookOnRoomOverviewCell: self];
}


@end
