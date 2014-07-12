
#import <UIKit/UIKit.h>

@class TTTAttributedLabel;

@interface AttributedTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString *summaryText;
@property (nonatomic, retain) TTTAttributedLabel *summaryLabel;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, retain) UILabel *lbltime;
@property (nonatomic, assign) NSInteger notificationType;
@property (nonatomic, assign) NSInteger isANewNotification;
+(CGFloat)heightForNotificationText:(NSString *)text;
+(CGFloat)heightForNewInterestText:(NSString*)what;
+(CGFloat)heightForTimeStampText:(NSString*)when;
@end
