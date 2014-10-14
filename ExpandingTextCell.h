//
//  ExpandingTextCell.h
//  Venere
//
//  Created by John Green on 22/07/2013.
//
//

@class ExpandingTextCell;

@protocol ExpandingTextCellDelegate

- (void) didTapExpandingTextCell:(ExpandingTextCell *) expandingTextCell;

@end

@interface ExpandingTextCell : UITableViewCell <UIGestureRecognizerDelegate>
@property (assign, nonatomic) id<ExpandingTextCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic, readonly) NSNumber *MaxHeight;


+ (float) measureMinCellHeight:(NSString *) text withWidth:(float) width;

- (void) updateWithText:(NSString *) text andMinHeight:(CGFloat) minHeight;
- (void) toggleExpanded;

@end
