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
#import "BeagleUserClass.h"
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
    
    NSString *key = @"160726900680967";
    NSDictionary *dictFB = [NSDictionary dictionaryWithObjectsAndKeys:key,ACFacebookAppIdKey,@[@"email"],ACFacebookPermissionsKey, nil];
    
    
    [self.accountStore requestAccessToAccountsWithType:FBaccountType options:dictFB completion:
     ^(BOOL granted, NSError *e) {
         if (granted) {
             NSArray *accounts = [self.accountStore accountsWithAccountType:FBaccountType];
             //it will always be the last object with single sign on
             self.facebookAccount = [accounts lastObject];
             NSLog(@"facebook account =%@",self.facebookAccount);
             [self get];
         } else {
             //Fail gracefully...
             NSLog(@"error getting permission %@",e);
             
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
            
            NSLog(@"Dictionary contains: %@", list );
            if([list objectForKey:@"error"]!=nil)
            {
                [self attemptRenewCredentials];
            }
            dispatch_async(dispatch_get_main_queue(),^{
                NSLog(@"name=%@",[list objectForKey:@"name"]);
                
                BeagleUserClass *userObject=[[BeagleUserClass alloc]init];
                
                id userName = [list objectForKey:@"username"];
                if (userName != nil && [userName class] != [NSNull class]) {
                    
                    userObject.userName=userName;
                }
                id fullName = [list objectForKey:@"name"];
                if (fullName != nil && [fullName class] != [NSNull class]) {
                    
                    userObject.fullName=fullName;
                }
                
                if([userName length]==0){
                    int r = arc4random() % 9;
                    int z = arc4random() % 9;
                    fullName=[fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    userObject.userName=[NSString stringWithFormat:@"%@_%d%d",fullName,r,z];
                }
                
                
                id password = [list objectForKey:@"id"];
                if (password != nil && [password class] != [NSNull class]) {
                    
                    userObject.password=password;
                }

                
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", [list objectForKey:@"id"]]];
                
                NSURLRequest *request = [NSURLRequest
                                         requestWithURL:pictureURL
                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
                NSError *error=nil;
                
                NSURLResponse *response;
                NSData *facebookData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                
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
    
    NSString *key = @"160726900680967";
    
    NSDictionary *dictFB = [NSDictionary dictionaryWithObjectsAndKeys:key,ACFacebookAppIdKey,@[@"offline_access"],@[@"read_stream"],@[@"email"],@[@"user_subscriptions"],@[@"friends_subscriptions"],@[@"publish_stream"],@[@"xmpp_login"],ACFacebookPermissionsKey, nil];
    
    
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
