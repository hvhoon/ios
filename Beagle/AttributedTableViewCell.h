
#import <UIKit/UIKit.h>

@class TTTAttributedLabel;

@interface AttributedTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString *summaryText;
@property (nonatomic, retain) TTTAttributedLabel *summaryLabel;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, retain) UILabel *lbltime;
@property (nonatomic, assign) NSInteger notificationType;
@property (nonatomic, assign) NSInteger isANewNotification;
+ (CGFloat)heightForCellWithText:(NSString *)text;
+(CGFloat)heightForCellWithNewInterest:(NSString*)text what:(NSString*)what;
@end
