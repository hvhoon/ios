
#import <QuartzCore/QuartzCore.h>
#import "AttributedTableViewCell.h"
#import "TTTAttributedLabel.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static CGFloat const kEspressoDescriptionTextFontSize = 14;
static CGFloat const kAttributedTableViewCellVerticalMargin = 17.0f;

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"#([^#(#)]+#)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

static NSRegularExpression *__parenthesisRegularExpression;
static inline NSRegularExpression * ParenthesisRegularExpression() {
    if (!__parenthesisRegularExpression) {
        __parenthesisRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\([^\\(\\)]+\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __parenthesisRegularExpression;
}

@implementation AttributedTableViewCell
@synthesize summaryText = _summaryText;
@synthesize summaryLabel = _summaryLabel;
@synthesize lbltime,timeText,notificationType;

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
                [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[[UIColor darkGrayColor] CGColor] range:result.range];
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
    CGFloat height = 10.0f;
    height += ceilf([text sizeWithFont:[UIFont systemFontOfSize:kEspressoDescriptionTextFontSize] constrainedToSize:CGSizeMake(238.0f, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height);
    height += kAttributedTableViewCellVerticalMargin;
    return height;
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
    
    CGRect rect1=CGRectMake(0, 10, 335, [AttributedTableViewCell heightForCellWithText:self.summaryText]-10);
    self.summaryLabel.frame =  CGRectOffset(CGRectInset(rect1, 60, 5), 0.0f, 0.0f);

    CGRect rect2=CGRectMake(0, self.summaryLabel.frame.size.height+5, 335, 35);
    
    self.lbltime.frame=CGRectOffset(CGRectInset(rect2, 60, 5), 0.0f, 0.0f);
    
}

@end

#pragma clang diagnostic pop
