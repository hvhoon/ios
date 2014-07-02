
#import <QuartzCore/QuartzCore.h>
#import "AttributedTableViewCell.h"
#import "TTTAttributedLabel.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"#([^#(#)]+#)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

@implementation AttributedTableViewCell
@synthesize summaryText = _summaryText;
@synthesize summaryLabel = _summaryLabel;
@synthesize lbltime,timeText,notificationType,isANewNotification;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.summaryLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.summaryLabel.textColor= [BeagleUtilities returnBeagleColor:2];
    self.summaryLabel.numberOfLines = 2;
    self.summaryLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.summaryLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    self.summaryLabel.highlightedTextColor = [UIColor whiteColor];
    self.summaryLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    
    self.lbltime=[[UILabel alloc] init];
    self.lbltime.textColor=[BeagleUtilities returnBeagleColor:6];
    self.lbltime.font =[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
    self.lbltime.lineBreakMode = UILineBreakModeWordWrap;
    self.lbltime.numberOfLines = 0;
    self.lbltime.highlightedTextColor = [BeagleUtilities returnBeagleColor:6];

    [self.contentView addSubview:self.lbltime];
    [self.contentView addSubview:self.summaryLabel];
    
    return self;
}


- (void)setSummaryText:(NSString *)text {
    [self willChangeValueForKey:@"summaryText"];
    _summaryText = [text copy];
    [self didChangeValueForKey:@"summaryText"];
    
    
   [self.summaryLabel setText:self.summaryText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);
        
        NSRegularExpression *regexp = NameRegularExpression();
        
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            
            UIFont *boldSystemFont =[UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f];
            CTFontRef boldFont = CTFontCreateWithName(( CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
            
            if (boldFont) {
                [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:result.range];
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge  id)boldFont range:result.range];
                CFRelease(boldFont);
                
                [mutableAttributedString removeAttribute:(NSString *)kCTForegroundColorAttributeName range:result.range];
                [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[[UIColor whiteColor] CGColor] range:result.range];
            }
            
            
        }];
    
       NSInteger hashCount = [[self.summaryText componentsSeparatedByString:@"#"] count]-1;
        
        for (NSInteger i=0; i<hashCount; i++)
        {
            NSRange range = [[mutableAttributedString string] rangeOfString:@"#"];
            
            [mutableAttributedString replaceCharactersInRange:NSMakeRange(range.location, 1) withString:@""];
            
        }
        
        return mutableAttributedString;
    }];
}

- (void)setTimeText:(NSString *)text {
    self.lbltime.text=text;
}

+ (CGFloat)heightForNotificationText:(NSString *)text {
    CGFloat height = 0.0f;
    
    // What's the height of the notification text
    height += ceilf([text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f] constrainedToSize:CGSizeMake(195, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height);
    
    // Limit Summary to 2 lines only
    if(height > 35.0f)
        height = 35.0f;
    
    return height;
}
+(CGFloat)heightForNewInterestText:(NSString*)what {
    CGFloat height = 0.0f; // Everything else on the screen that takes up height other than the notification text and new interest text
    
    // What's the height of the new interest text
    height += ceilf([what sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f] constrainedToSize:CGSizeMake(238.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height);
    
    return height;
}
+ (CGFloat)heightForTimeStampText:(NSString *)when {
    CGFloat height = 0.0f;
    
    // What's the height of the time stamp text
    height += ceilf([when sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f] constrainedToSize:CGSizeMake(195, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height);
    
    return height;
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
    
    self.summaryLabel.frame=CGRectMake(58, 12, ceilf([self.summaryText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f] constrainedToSize:CGSizeMake(195, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].width), [AttributedTableViewCell heightForNotificationText:self.summaryText]);
        
    self.lbltime.frame=CGRectMake(58, 12+self.summaryLabel.frame.size.height+2, ceilf([self.lbltime.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f] constrainedToSize:CGSizeMake(195, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].width), 15);
    
    // show the lil yellow dot if this is a new notification!
    if(self.isANewNotification){
        UIImageView *actionImageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"New-Notification"]];
        actionImageView.frame=CGRectMake(self.lbltime.frame.size.width+58+5, 12+self.summaryLabel.frame.size.height+6, 9, 9);
        [self addSubview:actionImageView];

    }
}

@end

#pragma clang diagnostic pop
