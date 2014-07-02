//
//  InAppNotificationView.h
//  Beagle
//
//  Created by Kanav Gupta on 24/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BeagleNotificationClass;
@class TTTAttributedLabel;

@protocol InAppNotificationViewDelegate <NSObject>

@optional
-(void)backgroundTapToPush:(BeagleNotificationClass*)notification;
-(void)notificationViewWillHide;
@end

@interface InAppNotificationView : UIView{
    NSTimer *timer;
    NSInteger counter;
}
@property(nonatomic,assign)id<InAppNotificationViewDelegate>delegate;
@property (nonatomic,retain)TTTAttributedLabel *summaryLabel;
@property (nonatomic,retain)BeagleNotificationClass *inAppNotif;
- (id)initWithFrame:(CGRect)frame appNotification:(BeagleNotificationClass*)appNotification;

@end
