//
//  FeedbackReporting.m
//  Beagle
//
//  Created by Kanav Gupta on 01/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "FeedbackReporting.h"
static FeedbackReporting *sharedInstance = nil;
@implementation FeedbackReporting
+ (FeedbackReporting *)sharedInstance
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [[self alloc] init];
		}
	}
	return sharedInstance;
}

- (BOOL)canSendFeedback
{
    if ([MFMailComposeViewController canSendMail]) {
        return true;
    }
    
    return false;
    
}


- (MFMailComposeViewController *)shareFeedbackController
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    NSArray *toRecipients = [NSArray arrayWithObject:@"help@mybeagleapp.com"];
    
    [picker setSubject:@"Feedback"];
    [picker setToRecipients:toRecipients];
    [picker setMessageBody:[self messageBody] isHTML:NO];
    
    return picker;
}

- (MFMailComposeViewController *)flagAnActivityController:(NSString*)flagMessage {
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    NSArray *toRecipients = [NSArray arrayWithObject:@"flagged@mybeagleapp.com"];
    
    [picker setSubject:@"Flag Activity"];
    [picker setToRecipients:toRecipients];
    [picker setMessageBody:flagMessage isHTML:NO];
    
    return picker;
}

-(NSString *)messageBody:(NSString*)activityName orgName:(NSString*)orgName
{
    
    // Getting the iOS environment settings
    
    NSDictionary *appMetaData = [[NSBundle mainBundle] infoDictionary];
    NSString* appVersion = [appMetaData objectForKey:@"CFBundleShortVersionString"];
    NSString* gitCommit = [appMetaData objectForKey:@"CFBundleVersion"];
    NSString* osVersion = [[UIDevice currentDevice] systemVersion];
    
    NSLog(@"App Version: %@, (%@)", appVersion, gitCommit);
    NSLog(@"iOS Version: %@", osVersion);
    
    // Fill out the email body text
    NSString *emailBody = [NSString stringWithFormat:@"Please tell us why you find this activity objectionable? (Enter below):\n\n\n\n\n--\n Flag Report:\n Activity : %@ \n Organizer: %@\n Beagle: %@ (%@)\niPhone iOS: %@", activityName,orgName,appVersion, gitCommit, osVersion];
    
    return emailBody;
}

- (NSString *)messageBody
{
    
    // Getting the iOS environment settings
    
    NSDictionary *appMetaData = [[NSBundle mainBundle] infoDictionary];
    NSString* appVersion = [appMetaData objectForKey:@"CFBundleShortVersionString"];
    NSString* gitCommit = [appMetaData objectForKey:@"CFBundleVersion"];
    NSString* osVersion = [[UIDevice currentDevice] systemVersion];
    
    NSLog(@"App Version: %@, (%@)", appVersion, gitCommit);
    NSLog(@"iOS Version: %@", osVersion);
    
    // Fill out the email body text
    NSString *emailBody = [NSString stringWithFormat:@"\n\n\n\n--\nBeagle: %@ (%@)\niPhone iOS: %@", appVersion, gitCommit, osVersion];
    
    return emailBody;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if(staturBarShow){
        staturBarShow=FALSE;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];

     
    }
    [controller dismissViewControllerAnimated:YES completion:Nil];
}

@end
