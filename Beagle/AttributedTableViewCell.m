
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
    self.summaryLabel.numberOfLines = 0;
    self.summaryLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.summaryLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
    self.summaryLabel.highlightedTextColor = [UIColor whiteColor];
    self.summaryLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    
    self.lbltime=[[UILabel alloc] init];
    self.lbltime.textColor=[BeagleUtilities returnBeagleColor:6];
    self.lbltime.font =[UIFont fontWithName:@"HelveticaNeue-Light" size:11.0f];
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
            
            UIFont *boldSystemFont =[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
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

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 0.0f;
    height += ceilf([text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f] constrainedToSize:CGSizeMake(179, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height);
    return height;
}
+(CGFloat)heightForCellWithNewInterest:(NSString*)text what:(NSString*)what{
    CGFloat height = 92.0f;
    height += ceilf([what sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f] constrainedToSize:CGSizeMake(238.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height);
    return height;
}
#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
    
    if(self.notificationType!=11){
        self.summaryLabel.frame=CGRectMake(59, 16, ceilf([self.summaryText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f] constrainedToSize:CGSizeMake(179, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].width), [AttributedTableViewCell heightForCellWithText:self.summaryText]+2);
        
    }
    else{
        self.summaryLabel.frame=CGRectMake(59, 16, ceilf([self.summaryText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f] constrainedToSize:CGSizeMake(179, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].width), [AttributedTableViewCell heightForCellWithText:self.summaryText]);

    }
    self.lbltime.frame=CGRectMake(59, 16+self.summaryLabel.frame.size.height+1, ceilf([self.lbltime.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:11.0f] constrainedToSize:CGSizeMake(179, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].width), 15);
    if(self.isANewNotification){
    UIImageView *actionImageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"New-Notification"]];
    actionImageView.frame=CGRectMake(self.lbltime.frame.size.width+59+5, 16+self.summaryLabel.frame.size.height+4, 9, 9);
    [self addSubview:actionImageView];

    }
}

@end

#pragma clang diagnostic pop
