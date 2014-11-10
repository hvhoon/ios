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
    [picker.navigationBar setTintColor:[BeagleUtilities returnBeagleColor:13]];
    
    NSArray *toRecipients = [NSArray arrayWithObject:@"flag@mybeagleapp.com"];
    
    [picker setSubject:@"Flag Activity"];
    [picker setToRecipients:toRecipients];
    [picker setMessageBody:flagMessage isHTML:NO];
    
    return picker;
}

-(MFMailComposeViewController*)testInviteUserController{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker.navigationBar setTintColor:[BeagleUtilities returnBeagleColor:13]];
    
    NSArray *toRecipients = [NSArray arrayWithObject:@"kanavkartik@gmail.com"];
    
    [picker setSubject:@"Invite Interest"];
    [picker setToRecipients:toRecipients];
    NSString *inviteHtmlPath = [[NSBundle mainBundle] pathForResource:@"Invite" ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:inviteHtmlPath];
    [picker addAttachmentData:htmlData mimeType:@"text/html" fileName:@"Invite"];

    
    [picker setMessageBody:@"hey how is it going" isHTML:NO];
    
    return picker;
}

- (MFMailComposeViewController*)inviteAUserController:(NSArray*)listArray firstName:(NSString*)firstName{
    
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker.navigationBar setTintColor:[BeagleUtilities returnBeagleColor:13]];
       picker.view.tag=473;
        NSMutableString *emailBody =[[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"<br /><p>%@ has invited you to check out Beagle, learn more below.</p><br />",firstName]];
       [emailBody appendString:[BeagleUtilities readHTMLFromDocumentDirectory]];

        [picker setSubject:@"Introducing Beagle!"];
        [picker setToRecipients:listArray];
        [picker setMessageBody:emailBody isHTML:YES];
        
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
    if(statusBarShow){
        statusBarShow=FALSE;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];

     
    }
    
    
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Result: Mail sending canceled");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Result: Mail sending failed");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Result: Mail sent");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Result: Mail saved");
            break;
            
        default:
            NSLog(@"Result: Mail not sent");
            break;
    }
    
    if(controller.view.tag==473){
      if (result == MFMailComposeResultSent){
          
          
          if (self.delegate && [self.delegate respondsToSelector:@selector(sendEmailInvite)])
          [self.delegate sendEmailInvite];
//        NSString *email = [self findEmailAddresses:controller.view depth:0];
//        NSLog(@"%@", email);
      }
    }
    [controller dismissViewControllerAnimated:YES completion:Nil];
}

- (NSString *)findEmailAddresses:(UIView *)view depth:(NSInteger)depth
{
    NSString *eAddress = nil;
    if (!view)
        return eAddress;
    
    NSMutableString *tabString = [NSMutableString stringWithCapacity:depth];
    for (int i = 0; i < depth; i++)
        [tabString appendString:@"-- "];
    NSLog(@"%@%@", tabString, view);
    
    if ([view isKindOfClass:[UITextField class]])
    {
        // MAGIC: debugger shows email address(es) in first textField
        // but only if it's about max 35 characters
        if (((UITextField *)view).text)
        {
            eAddress = [NSString stringWithString:((UITextField *)view).text];
            NSLog(@"FOUND UITextField: %@", eAddress ? eAddress : @"");
        }
    }
    
    NSArray *subviews = [view subviews];
    if (subviews) {
        for (UIView *view in subviews)
        {
            NSString *s = [self findEmailAddresses:view depth:depth+1];
            if (s) eAddress = s;
        }
    }
    
    return eAddress;
}

@end
