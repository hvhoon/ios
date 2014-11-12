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
@protocol InAppNotificationViewDelegate;

@interface InAppNotificationView : UIView<UIGestureRecognizerDelegate>{
    NSTimer *timer;
    NSInteger counter;
}
@property (nonatomic,retain)TTTAttributedLabel *summaryLabel;
@property (nonatomic,retain)BeagleNotificationClass *notification;
- (id)initWithNotificationClass:(BeagleNotificationClass*)appNotification;
-(void)show;
@property(nonatomic,weak)id<InAppNotificationViewDelegate>delegate;

@end


@protocol InAppNotificationViewDelegate <NSObject>

@optional
-(void)backgroundTapToPush:(BeagleNotificationClass*)notification;
-(void)notificationViewWillHide;
- (void)notificationView:(InAppNotificationView *)inAppNotification didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
