//
//  FeedbackReporting.h
//  Beagle
//
//  Created by Kanav Gupta on 01/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@protocol FeedbackReportingDelegate <NSObject>

@optional
-(void)sendEmailInvite;
@end

@interface FeedbackReporting : NSObject<MFMailComposeViewControllerDelegate>{
    BOOL statusBarShow;
}
@property (nonatomic,weak)id <FeedbackReportingDelegate> delegate;
+ (FeedbackReporting *)sharedInstance;
- (BOOL)canSendFeedback;
- (MFMailComposeViewController *)flagAnActivityController:(NSString*)flagMessage;
- (MFMailComposeViewController *)shareFeedbackController;
- (MFMailComposeViewController*)inviteAUserController:(NSArray*)listArray firstName:(NSString*)firstName;
@end
