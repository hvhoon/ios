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
#import <Social/Social.h>
#define kJoinBeagle 12
@interface LoginViewController ()<FacebookLoginSessionDelegate,ServerManagerDelegate>{
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    __weak IBOutlet UIImageView *NextArrow;
    ServerManager *loginServerManager;
     NSMutableData *_data;
    NSInteger test;
}
@property(nonatomic,strong)FacebookLoginSession *facebookSession;
@property(nonatomic,strong)ServerManager *loginServerManager;
@end

@implementation LoginViewController
@synthesize loginServerManager=_loginServerManager;
@synthesize facebookSession=_facebookSession;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    
}

-(IBAction)signInUsingFacebookClicked:(id)sender{
    
    [NextArrow setHidden:YES];
    [activityIndicatorView setHidden:NO];
    [activityIndicatorView startAnimating];
    

    _facebookSession=[[FacebookLoginSession alloc]init];
    _facebookSession.delegate=self;
    [_facebookSession getUserNativeFacebookSession];

    
}

#pragma mark -
#pragma mark Delegate method From FacebookSession


-(void)checkIfUserAlreadyExists:(NSString*)email{
    if(_loginServerManager!=nil){
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }
    _loginServerManager=[[ServerManager alloc]init];
    _loginServerManager.delegate=self;
    [_loginServerManager userInfoOnBeagle:email];
    
}
-(void)successfulFacebookLogin:(BeagleUserClass*)data{
    
    if(_loginServerManager!=nil){
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }
    _loginServerManager=[[ServerManager alloc]init];
    _loginServerManager.delegate=self;
    [_loginServerManager registerPlayerOnBeagle:data];
    
}
-(void)facebookAccountNotSetup{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
#if 1
        NSString *message = NSLocalizedString (@"Right now beagle requires facebook to login. Please setup your facebook account in Settings > Facebook",
                                               @"No Facebook Account");
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        
        [alert show];
        
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        [activityIndicatorView stopAnimating];
        [activityIndicatorView setHidden:YES];
        [NextArrow setHidden:NO];
#else
        
        
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        controller.view.hidden = YES;
        [controller setInitialText:@""];
        
        [controller addImage:[UIImage imageNamed:@""]];

        [self.view.window.rootViewController presentViewController:controller animated:NO completion:^{
            [self resignFirstResponder];
            [[controller view] endEditing:YES];
            test=0;
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [activityIndicatorView stopAnimating];
            [activityIndicatorView setHidden:YES];
            [NextArrow setHidden:NO];

        }];
#endif
    });
    
}

-(void)permissionsError:(NSError*)e{
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *message=nil;
            if(e!=nil){
                message=[e localizedDescription];
            }else{
                
                message = NSLocalizedString (@"We are not able to retrieve your email from Facebook.Please check your privacy settings",
                                                       @"No Facebook Account");
            }
            
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            
            [alert show];
            
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [activityIndicatorView stopAnimating];
            [activityIndicatorView setHidden:YES];
            [NextArrow setHidden:NO];
        });
        
}

-(void)pushToHomeScreen{
    
    [activityIndicatorView stopAnimating];
    [activityIndicatorView setHidden:YES];
    [NextArrow setHidden:NO];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    InitialSlidingViewController *initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"initialBeagle"];
    [self.navigationController pushViewController:initialViewController animated:YES];

}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES];
    activityIndicatorView.hidden=YES;
	// Do any additional setup after loading the view.
}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallUserRegisteration){
        
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;

        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
            
            
            
            id player=[response objectForKey:@"player"];
            if (player != nil && [player class] != [NSNull class]) {

                id beagleId=[player objectForKey:@"id"];
                if (beagleId != nil && [beagleId class] != [NSNull class]) {
                  [[[BeagleManager SharedInstance] beaglePlayer]setBeagleUserId:[beagleId integerValue]];
                    [[BeagleManager SharedInstance] userProfileDataUpdate];
                    [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:[beagleId integerValue]] forKey:@"beagleId"];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                     NSLog(@"beagleId=%ld",(long)[beagleId integerValue]);
                    
                }

                
                
                    NSURL *pictureURL = [NSURL URLWithString:[player objectForKey:@"image_url"]];
                    
                    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                          timeoutInterval:2.0f];
                    // Run network request asynchronously
                    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                    if (!urlConnection) {
                        NSLog(@"Failed to download picture");
                    }
                }
        }
        }
        
            [self pushToHomeScreen];
    }
    else if (serverRequest==kServerGetSignInInfo){
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            id  registered=[response objectForKey:@"registered"];
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                if (registered != nil && [status class] != [NSNull class] && [registered boolValue]){
                    [_facebookSession requestAdditionalPermissions];
                }else{
                    //first time user
                    // show an alert
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome To Beagle" message:@"To keep things simple we use Facebook to log you in. We promise never to post publicly without your permission but we do need some info to get started...Ready to join the fun?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"YES",nil];
                    alert.tag=kJoinBeagle;
                    [alert show];
                    
                }
            }
        }
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{

    if(serverRequest==kServerCallUserRegisteration|| serverRequest==kServerGetSignInInfo)
    {
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }

      NSString *message = NSLocalizedString (@"Well this is embarrassing. Please try again in a bit.",
                                           @"NSURLConnection initialization method failed.");
      BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallUserRegisteration|| serverRequest==kServerGetSignInInfo)
    {
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}

-(void)dealloc{
    
    for (ASIHTTPRequest *req in [ASIHTTPRequest.sharedQueue operations]) {
        [req clearDelegatesAndCancel];
        [req setDelegate:nil];
        [req setDidFailSelector:nil];
        [req setDidFinishSelector:nil];
    }
    [ASIHTTPRequest.sharedQueue cancelAllOperations];
}


#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[BeagleManager SharedInstance] processFacebookProfilePictureData:_data];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -
#pragma mark UIAlertView methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    [alertView resignFirstResponder];
    
    if(alertView.tag==kJoinBeagle){
    if (buttonIndex == 1) {
        
         [_facebookSession requestAdditionalPermissions];
    }
    
    else{
          [_facebookSession get];

    }
  }
}


@end
