//
//  RoomOverviewCell.h
//  Venere
//
//  Created by John Green on 14/11/2012.
//
//

#import "HotelSearchResult.h"
#import "PriceLabel.h"
#import "OccupancyIndicator.h"
#import "TitledDetailBlock.h"
#import "RoomValueAddsView.h"
#import "DealBanner.h"

@class RoomOverviewCell;

@protocol RoomOverviewDelegate

- (void) didPressBookOnRoomOverviewCell:(RoomOverviewCell *) roomOverViewCell;
- (void) didTapRoomOverviewCell:(RoomOverviewCell *) roomOverviewCell;

@end


@interface RoomOverviewCell : UITableViewCell

+ (float) measureCellHeight: (RoomResult *) room withWidth:(float) width;

    
@property (assign, nonatomic) id<RoomOverviewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *scarcityLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet DealBanner *dealBanner;
@property (weak, nonatomic) IBOutlet PriceLabel *priceLabel;
@property (weak, nonatomic) IBOutlet OccupancyIndicator *occupancyLabel;
@property (weak, nonatomic) IBOutlet UIImageView *roomImage;

@property (weak, nonatomic) IBOutlet UILabel *totalPriceDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *feeDescriptionLabel;
@property (weak, nonatomic) IBOutlet TitledDetailBlock *titledDetailBlock;
@property (weak, nonatomic) IBOutlet UILabel *roomValueAddsView;
@property (weak, nonatomic) IBOutlet UIButton *bookButton;
@property (weak, nonatomic) IBOutlet UIView *priceContainer;

@property (readonly) float minHeight;
@property (readonly) float maxHeight;
@property (readonly) BOOL isExpanded;

- (void) update:(RoomResult *) room andIsExpanded: (BOOL) isExpanded ;
- (void) toggleExpanded;


- (IBAction)bookButtonPressed:(id)sender;

@end
