//
//  InAppNotificationView.m
//  Beagle
//
//  Created by Kanav Gupta on 24/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "InAppNotificationView.h"
#import "TTTAttributedLabel.h"
#import "BeagleNotificationClass.h"
static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"#([^#(#)]+#)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

@implementation InAppNotificationView
@synthesize summaryLabel,delegate,notification;
UIWindowLevel windowLevel;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (id)initWithNotificationClass:(BeagleNotificationClass*)appNotification
{
    
    
        
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (!window)
            window = [[UIApplication sharedApplication].windows lastObject];
        
        CGRect viewBounds = [[[window subviews] lastObject] bounds];
        self = [super initWithFrame:CGRectMake(0, 0, viewBounds.size.width, 64)];

        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        // make your gesture recognizer priority
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];

        self.userInteractionEnabled = YES;
        
        self.notification=appNotification;
        self.backgroundColor=[BeagleUtilities returnBeagleColor:13];
        self.alpha=1.0;
        
        UIImageView *profileImageView=[[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 29)];
        
        self.summaryLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        summaryLabel.frame=CGRectMake(63, 14.5, 214, 49.5);
        summaryLabel.textColor=[UIColor whiteColor];
        summaryLabel.font =[UIFont fontWithName:@"HelveticaNueue" size:14.0f];
        summaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        summaryLabel.numberOfLines = 2;
        summaryLabel.highlightedTextColor = [UIColor whiteColor];
        summaryLabel.backgroundColor=[UIColor clearColor];
        
        [self setSummaryText:self.notification.notificationString];
        
        profileImageView.frame=CGRectMake(16, 14.5, 35, 35);
        profileImageView.image=[BeagleUtilities imageCircularBySize:appNotification.profileImage sqr:70.0f];
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2;
        profileImageView.clipsToBounds = YES;
        profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        profileImageView.layer.borderWidth = 1.5f;
    

        [self addSubview:profileImageView];
        [self addSubview:self.summaryLabel];
    
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(viewBounds.size.width - 43, 14.5, 35, 35)];
        [button setImage:[UIImage imageNamed:@"Cancel"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setTag:0];
        [self addSubview:button];

    return self;
    
}

- (void)countdownTracker:(NSTimer *)theTimer {
    counter++;
    if (counter == 4){
        [timer invalidate];
        timer = nil;
        counter = 0;
        [self dismissWithAnimation:YES];
    }
}



- (void)setSummaryText:(NSString *)text {
    [self.summaryLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);
        
        NSRegularExpression *regexp = NameRegularExpression();
        
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            
            UIFont *boldSystemFont =[UIFont fontWithName:@"HelveticaNueue-Medium" size:14.0];
            CTFontRef boldFont = CTFontCreateWithName(( CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
            
            if (boldFont) {
                [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:result.range];
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge  id)boldFont range:result.range];
                CFRelease(boldFont);
                
                [mutableAttributedString removeAttribute:(NSString *)kCTForegroundColorAttributeName range:result.range];
                [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[[UIColor whiteColor] CGColor] range:result.range];
            }
        }];
        
        NSInteger hashCount = [[text componentsSeparatedByString:@"#"] count]-1;
        
        for (int i=0; i<hashCount; i++)
        {
            NSRange range = [[mutableAttributedString string] rangeOfString:@"#"];
            [mutableAttributedString replaceCharactersInRange:NSMakeRange(range.location, 1) withString:@""];
        }
        
        return mutableAttributedString;
    }];
}

-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    
    [self dismissWithAnimation:YES];
    

    if (self.notification.backgroundTap && self.notification.notificationType!=CANCEL_ACTIVITY_TYPE) {
         if (self.delegate && [self.delegate respondsToSelector:@selector(backgroundTapToPush:)])
            if(self.notification.activity.activityId!=0){
                [self.delegate backgroundTapToPush:self.notification];
                
            }

    }
    
    
}

- (void)show
{
    //Get window instance to display the notification as a subview on the view present on screen
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if (!window)
        window = [[UIApplication sharedApplication].windows lastObject];
    
    windowLevel = [[[[UIApplication sharedApplication] delegate] window] windowLevel];
    
    //Update windowLevel to make sure status bar does not interfere with the notification
    [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelStatusBar+1];
    
    CGRect presentationFrame = self.frame;
    CGRect viewBounds = [[[window subviews] lastObject] bounds];
    self.frame = CGRectMake(0, 0, viewBounds.size.width, -64);
    [[[window subviews] lastObject] addSubview:self];
    
    [UIView animateWithDuration:0.35 delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
         self.frame = presentationFrame;
    } completion:^(BOOL finished) {
        counter=0;
        timer =[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTracker:) userInfo:nil repeats:YES];
    }];


}

- (void)dismissWithAnimation:(BOOL)animated
{
    CGRect viewBounds = [self.superview bounds];
    
    if (animated) {
        [UIView animateWithDuration:0.35 delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.frame = CGRectMake(0, 0, viewBounds.size.width, -64);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:windowLevel];
        }];
        
        }
    
    if ([[self delegate] respondsToSelector:@selector(notificationView:didDismissWithButtonIndex:)]) {
        [[self delegate] notificationView:self didDismissWithButtonIndex:0];
    }
    
}



- (void)buttonTapped:(id)sender
{
    [self dismissWithAnimation:YES];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
