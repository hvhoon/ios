//
//  FacebookLoginSession.m
//  Beagle
//
//  Created by Kanav Gupta on 24/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "FacebookLoginSession.h"
#import <Social/Social.h>
#import <Accounts/ACAccountType.h>
#import <Accounts/ACAccountCredential.h>
@implementation FacebookLoginSession
@synthesize accountStore;
@synthesize facebookAccount;
@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


-(void)getUserNativeFacebookSession{
    self.accountStore = [[ACAccountStore alloc]init];
    ACAccountType *FBaccountType= [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSString *key = @"500525846725031";
    NSDictionary *dictFB = [NSDictionary dictionaryWithObjectsAndKeys:key,ACFacebookAppIdKey,@[@"email"],ACFacebookPermissionsKey,ACFacebookAudienceEveryone,ACFacebookAudienceKey,nil];
    
    
    
    
    [self.accountStore requestAccessToAccountsWithType:FBaccountType options:dictFB completion:^(BOOL granted, NSError *error) {
        if (granted) {
            NSArray *accounts = [self.accountStore accountsWithAccountType:FBaccountType];
            
            if ([accounts count] > 0) {
                ACAccountType *FBaccountType= [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
                NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:key,ACFacebookAppIdKey,[NSArray arrayWithObjects:@"friends_location",@"user_friends",nil],ACFacebookPermissionsKey,ACFacebookAudienceEveryone,ACFacebookAudienceKey,nil];

                

                
                [self.accountStore requestAccessToAccountsWithType:FBaccountType options:options completion:^(BOOL granted2, NSError *error) {
                    if (granted2) {
                        NSLog(@"granted")
                        ;
                        self.facebookAccount = [accounts lastObject];
                        // NSLog(@"facebook account =%@",self.facebookAccount);
                        [self get];

                    }
                    else {
                        NSLog(@" permission error: %@", [error localizedDescription]);
                        [delegate facebookAccountNotSetup];
                        //_publishPermissionsGranted = NO;
                    }
                    
                }];
            }
        }
        else {
            NSLog(@"Nope");
            [delegate facebookAccountNotSetup];
        }
        
        if (error) {
            if (error.code == 6) {
                NSLog(@"FB Account doesn't exist");
            }
            NSLog(@"Error: %@", error.localizedDescription);
            
            
            [delegate facebookAccountNotSetup];

        }
    }];
    
    
    
    

}

-(void)get
{
    
    NSURL *requestURL = [NSURL URLWithString:@"https://graph.facebook.com/me"];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:requestURL
                                               parameters:nil];
    request.account = self.facebookAccount;
    
    [request performRequestWithHandler:^(NSData *data,
                                         NSHTTPURLResponse *response,
                                         NSError *error) {
        
        if(!error)
        {
            list =[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            
            //NSLog(@"Dictionary contains: %@", list );
            if([list objectForKey:@"error"]!=nil)
            {
                [self attemptRenewCredentials];
            }
            dispatch_async(dispatch_get_main_queue(),^{
               // NSLog(@"name=%@",[list objectForKey:@"name"]);
                BeagleManager *BGM=[BeagleManager SharedInstance];
                BeagleUserClass *userObject=nil;
                if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
                    userObject= BGM.beaglePlayer;
                }else{
                    userObject=[[BeagleUserClass alloc]init];
                }
                
                
                id userName = [list objectForKey:@"username"];
                if (userName != nil && [userName class] != [NSNull class]) {
                    
                    userObject.userName=userName;
                }
                id fullName = [list objectForKey:@"name"];
                if (fullName != nil && [fullName class] != [NSNull class]) {
                    
                    
                    NSArray *arr = [fullName componentsSeparatedByString:@" "];
                    
                    if([arr count]>=2){
                        userObject.first_name=[arr objectAtIndex:0];
                        userObject.last_name=[arr objectAtIndex:1];
                    }
                    else{
                        userObject.first_name=fullName;
                    }

                }
                
                id userId = [list objectForKey:@"id"];
                if(userId != nil && [userId class] != [NSNull class]){
                    userObject.fbuid=[userId integerValue];
                }

                 id first_name = [list objectForKey:@"first_name"];
                if(first_name != nil && [first_name class] != [NSNull class]){
                    userObject.first_name=first_name;
                }
                
                id last_name = [list objectForKey:@"last_name"];
                if(last_name != nil && [last_name class] != [NSNull class]){
                    userObject.last_name =last_name;
                }
                

                
                id location = [list objectForKey:@"location"];
                if(location != nil && [location class] != [NSNull class]){
                    id country = [location objectForKey:@"name"];
                    if(country != nil && [country class] != [NSNull class]){
                        userObject.location=country;
                    }
                }
                
                
                userObject.profileImageUrl= [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", [list objectForKey:@"id"]];

                
                
                userObject.access_token = self.facebookAccount.credential.oauthToken;
                //NSLog(@"accessToken=%@", userObject.access_token);
                
               // userObject.profileImage=[UIImage imageWithData:facebookData];
                
                if (nil == response) {
                    if (error){
                        NSLog(@"Connection failed! Error - %@ %@",
                              [error localizedDescription],
                              [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
                }
            }

                id email = [list objectForKey:@"email"];
                if (email != nil && [email class] != [NSNull class]) {
                    
                    userObject.email=email;
                }
                    
                BGM.beaglePlayer=userObject;
                    
                [delegate successfulFacebookLogin:userObject];
        
            });
        }
        else{
            //handle error gracefully
            NSLog(@"error=%@",error);
            //attempt to revalidate credentials
            
            //[delegate facebookAccountNotSetup];
            
            
        }
        
    }];
    
    self.accountStore = [[ACAccountStore alloc]init];
    ACAccountType *FBaccountType= [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSString *key = @"500525846725031";
    
//    [NSArray arrayWithObjects:@"email",@"offline_access",@"read_stream",@"user_subscriptions",@"friends_subscriptions",@"friends_location",@"user_location",@"user_friends",@"publish_stream",@"xmpp_login",nil]
    
    NSDictionary *dictFB = [[NSDictionary alloc] initWithObjectsAndKeys:
                             (NSString *)ACFacebookAppIdKey,key,
                            (NSString *)ACFacebookPermissionsKey,@[@"email", @"offline_access",@"read_stream",@"user_subscriptions", @"friends_subscriptions",@"friends_location",@"user_location", @"user_friends",@"publish_stream",@"xmpp_login"],
                             (NSString *)ACFacebookAudienceKey, ACFacebookAudienceEveryone,
                             nil];
    
//    NSDictionary *dictFB = [NSDictionary dictionaryWithObjectsAndKeys:key,ACFacebookAppIdKey,@[@"offline_access"],@[@"read_stream"],@[@"email"],@[@"user_subscriptions"],@[@"friends_subscriptions"],@[@"friends_location"],@[@"user_location"],@[@"user_friends"],@[@"publish_stream"],@[@"xmpp_login"],ACFacebookPermissionsKey, nil];
    
    
    [self.accountStore requestAccessToAccountsWithType:FBaccountType options:dictFB completion:
     ^(BOOL granted, NSError *e) {}];
    
}

-(void)attemptRenewCredentials{
    [self.accountStore renewCredentialsForAccount:(ACAccount *)self.facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error){
        if(!error)
        {
            switch (renewResult) {
                case ACAccountCredentialRenewResultRenewed:
                    NSLog(@"Good to go");
                    [self get];
                    break;
                case ACAccountCredentialRenewResultRejected:
                    NSLog(@"User declined permission");
                    break;
                case ACAccountCredentialRenewResultFailed:
                    NSLog(@"non-user-initiated cancel, you may attempt to retry");
                    break;
                default:
                    break;
            }
            
        }
        else{
            //handle error gracefully
            NSLog(@"error from renew credentials%@",error);
        }
    }];
    
    
}

@end
