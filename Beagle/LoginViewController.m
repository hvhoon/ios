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
     UIActivityIndicatorView *loginIndicatorView;
     ServerManager *loginServerManager;
     NSMutableData *_data;
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
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookAuthComplete:) name:kFacebookSSOLoginAuthentication object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kFacebookAuthenticationFailed object:Nil];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    
    
        UIButton *facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if([UIScreen mainScreen].bounds.size.height > 480.0f)
        facebookButton.frame=CGRectMake(60, 430,
                                         200,33);
        else{
            facebookButton.frame=CGRectMake(60, 430-88,
                                            200,33);
            
        }
        [self.view addSubview:facebookButton];
        
        facebookButton.tag=573;
        [[facebookButton titleLabel]setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f]];
        [facebookButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [facebookButton setTitle:@"Login Using Facebook" forState:UIControlStateNormal];
        
        // Normal state
        [facebookButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [facebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [facebookButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]] forState:UIControlStateHighlighted];
        [facebookButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        
        [facebookButton addTarget:self action:@selector(facebookBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [facebookButton setEnabled:YES];
    
    
    loginIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            if([UIScreen mainScreen].bounds.size.height > 480.0f)
    loginIndicatorView.frame=CGRectMake(230, 436.5, 20, 20);
            else{
    loginIndicatorView.frame=CGRectMake(230, 436.5-88, 20, 20);
            }
    loginIndicatorView.hidesWhenStopped=YES;
    [self.view addSubview:loginIndicatorView];
    loginIndicatorView.hidden=YES;
    
    
    
	// Do any additional setup after loading the view.
}

-(void)facebookBtnPressed:(id)sender{
    UIButton *tb=(UIButton*)sender;
    [tb setTitle:@"Logging you in..." forState:UIControlStateNormal];
    [loginIndicatorView setHidden:NO];
    [loginIndicatorView startAnimating];
    [Appsee addEvent:@"Login Attempt"];
    _facebookSession=[[FacebookLoginSession alloc]init];
    _facebookSession.delegate=self;
    [_facebookSession getUserNativeFacebookSession];

    
}

#pragma mark -
#pragma mark Delegate method From FacebookSession


-(void)checkIfUserAlreadyExists:(BeagleUserClass*)userData{
    if(_loginServerManager!=nil){
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }
    _loginServerManager=[[ServerManager alloc]init];
    _loginServerManager.delegate=self;
    [_loginServerManager userInfoOnBeagle:userData.email];
    
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
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] checkForFacebookSSOLogin];
#else
        
        
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        controller.view.hidden = YES;
        [controller setInitialText:@""];
        
        [controller addImage:[UIImage imageNamed:@""]];

        [self.view.window.rootViewController presentViewController:controller animated:NO completion:^{
            [self resignFirstResponder];
            [[controller view] endEditing:YES];
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [loginIndicatorView stopAnimating];
            [loginIndicatorView setHidden:YES];

        }];
#endif
    });
    
}

-(void)permissionsError:(NSError*)e{
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle" message:@"We need some basic Facebook info to show you what your friends are upto and tell them what you want to do.  We promise to never post anything on your wall or spam your friends. If you change your mind please try logging in again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
            [alert show];
            
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [loginIndicatorView stopAnimating];
            [loginIndicatorView setHidden:YES];
            UIButton *fbBtn=(UIButton*)[self.view viewWithTag:586];
            [fbBtn setTitle:@"Login Using Facebook" forState:UIControlStateNormal];
   });
        
}

-(void)facebookAuthComplete:(NSNotification*) note{
        id obj=[note valueForKey:@"userInfo"];
        BeagleUserClass *player=[obj valueForKey:@"player"];
       [self checkIfUserAlreadyExists:player];
    
}
-(void)authenticationFailed:(NSNotification*) note{
    [self permissionsError:nil];
}
-(void)pushToHomeScreen{
    
    [loginIndicatorView stopAnimating];
    [loginIndicatorView setHidden:YES];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    InitialSlidingViewController *initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"initialBeagle"];
    [self.navigationController pushViewController:initialViewController animated:YES];

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
//                    [_facebookSession requestAdditionalPermissions];
                    [self successfulFacebookLogin:[[BeagleManager SharedInstance]beaglePlayer]];
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
