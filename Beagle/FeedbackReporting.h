//
//  FeedbackReporting.h
//  Beagle
//
//  Created by Kanav Gupta on 01/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
@interface FeedbackReporting : NSObject<MFMailComposeViewControllerDelegate>
+ (FeedbackReporting *)sharedInstance;
- (BOOL)canSendFeedback;
- (MFMailComposeViewController *)flagAnActivityController:(NSString*)actName player:(NSString*)plyName;

@end
