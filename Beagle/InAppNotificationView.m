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
#import "JSON.h"
static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"#([^#(#)]+#)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

@implementation InAppNotificationView
@synthesize summaryLabel,delegate,inAppNotif;
- (id)initWithFrame:(CGRect)frame appNotification:(BeagleNotificationClass*)appNotification
{
    
    if(self=[super initWithFrame:frame]){
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        
        self.userInteractionEnabled = YES;
        self.opaque = NO;
        
        inAppNotif=appNotification;
        UIView *notificationView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
        notificationView.backgroundColor=[UIColor blackColor];
        notificationView.alpha=0.9;
        
        UIImageView *profileImageView=[[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 29)];
        
        self.summaryLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        summaryLabel.frame=CGRectMake(63, 0, 241, 64);
        summaryLabel.textColor=[UIColor whiteColor];
        summaryLabel.font =[UIFont fontWithName:@"HelveticaNueue-Light" size:14];
        summaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        summaryLabel.numberOfLines = 0;
        summaryLabel.highlightedTextColor = [UIColor whiteColor];
        summaryLabel.backgroundColor=[UIColor clearColor];
        
        [self setSummaryText:inAppNotif.notificationString];
        
        profileImageView.frame=CGRectMake(16, 14.5, 35, 35);
//        NSData *bytes=[NSData dataWithContentsOfURL:[NSURL URLWithString:appNotification.photoUrl]];
//        appNotification.profileImage=[UIImage imageWithData:bytes];
        profileImageView.image=[BeagleUtilities imageCircularBySize:appNotification.profileImage sqr:70.0f];
        

        [notificationView addSubview:profileImageView];
        UIButton *btnaction=[UIButton buttonWithType:UIButtonTypeCustom];
        btnaction.frame=CGRectMake(0, 0, 275, 64);
        btnaction.backgroundColor=[UIColor clearColor];
        [btnaction setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
        [btnaction addTarget:self action:@selector(backgroundtap:) forControlEvents:UIControlEventTouchUpInside];
        
        [notificationView addSubview:self.summaryLabel];
        [notificationView addSubview:btnaction];
        [self addSubview:notificationView];
        
        
        
        counter=0;
        timer =[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTracker:) userInfo:nil repeats:YES];
        
        CGRect popupStartRect=CGRectMake(0, -64, 320, 64);
        CGRect popupEndRect=CGRectMake(0,0, 320, 64);
        self.frame = popupStartRect;
        self.alpha = 1.0f;
        
        
        
        
        
        [UIView animateWithDuration:0.35 delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.frame = popupEndRect;
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        } completion:^(BOOL finished) {
        }];
        
        
    }
    return self;
}

- (void)countdownTracker:(NSTimer *)theTimer {
    counter++;
    if (counter == 8){
        [timer invalidate];
        timer = nil;
        counter = 0;
        
        [self HideNotification];
    }
}

-(void)HideNotification{
    
    CGRect popupStartRect=CGRectMake(0, -64, 320, 64);
    [UIView animateWithDuration:0.7 delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.frame = popupStartRect;
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.alpha = 0.0f;
    }];
    
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

-(void)backgroundtap:(UIButton*)sender{
#if 0
    if(inAppNotif.notificationType!=17){
        
    }
    NSURL *url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@received_notification.json?id=%ld",localHost,inAppNotif.notificationId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"url=%@",url);
    
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
    NSHTTPURLResponse *response = NULL;
	NSError *error = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSDictionary* resultsd = [[[NSString alloc] initWithData:returnData
                                                    encoding:NSUTF8StringEncoding] JSONValue];
    
    [[BeagleManager SharedInstance]setBadgeCount:[[resultsd objectForKey:@"badge"]integerValue]];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[BeagleManager SharedInstance]badgeCount]];
#endif
    if (inAppNotif.backgroundTap) {
        
        [self HideNotification];
        if (self.delegate && [self.delegate respondsToSelector:@selector(backgroundTapToPush:)])
            if(inAppNotif.activityId!=0){
                [self.delegate backgroundTapToPush:inAppNotif];
                
            }

    }
    
    
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
