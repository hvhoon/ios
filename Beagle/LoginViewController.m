//
//  LoginViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LoginViewController.h"
#import "InitialSlidingViewController.h"
#import "FacebookLoginSession.h"
#import "BeagleUserClass.h"
#import <Social/Social.h>
#import "ServerManager.h"
@interface LoginViewController ()<FacebookLoginSessionDelegate,ServerManagerDelegate>{
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    ServerManager *loginServerManager;
}
@property(nonatomic,strong)ServerManager *loginServerManager;
@end

@implementation LoginViewController
@synthesize loginServerManager=_loginServerManager;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(IBAction)signInUsingFacebookClicked:(id)sender{
    [activityIndicatorView setHidden:NO];
    [activityIndicatorView startAnimating];
    

    FacebookLoginSession *facebookSession=[[FacebookLoginSession alloc]init];
    facebookSession.delegate=self;
    [facebookSession getUserNativeFacebookSession];

    
}

#pragma mark -
#pragma mark Delegate method From FacebookSession

-(void)successfulFacebookLogin:(BeagleUserClass*)data{
    
    _loginServerManager=[[ServerManager alloc]init];
    _loginServerManager.delegate=self;
    [_loginServerManager registerPlayerOnBeagle:data];
}
-(void)facebookAccountNotSetup{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        controller.view.hidden = YES;
        [self presentViewController:controller animated:NO completion:^{
            [self dismissViewControllerAnimated:NO completion:nil];
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [activityIndicatorView stopAnimating];
            [activityIndicatorView setHidden:YES];

        }];
    });
    
    
}


-(void)pushToHomeScreen{
    
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"FacebookLogin"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [activityIndicatorView stopAnimating];
    [activityIndicatorView setHidden:YES];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    InitialSlidingViewController *initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"initialBeagle"];
    [self.navigationController pushViewController:initialViewController animated:YES];
    
    
    

}

- (void)viewDidLoad
{
    [self.navigationController setNavigationBarHidden:YES];
    activityIndicatorView.hidden=YES;
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallUserRegisteration){
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
            
            
            
            
            id player=[response objectForKey:@"player"];
            if (player != nil && [player class] != [NSNull class]) {
                
                
                NSLog(@"player=%@",player);
                
            }
        }
        }
        
            [self pushToHomeScreen];
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{

//    [(AppDelegate*)[[UIApplication sharedApplication] delegate]hideProgressView];
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    //ScoreAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
//    [(AppDelegate*)[[UIApplication sharedApplication] delegate]hideProgressView];
    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
//    [alert show];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
