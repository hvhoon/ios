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
     ServerManager *loginServerManager;
     NSMutableData *_data;
}
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginActivity;
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
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookAuthComplete:) name:kFacebookSSOLoginAuthentication object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kFacebookAuthenticationFailed object:Nil];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    [_loginButton setTitle:@"Login Using Facebook" forState:UIControlStateNormal];

    
	// Do any additional setup after loading the view.
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFacebookSSOLoginAuthentication object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFacebookAuthenticationFailed object:nil];

}
- (IBAction)loginButtonPressed:(id)sender {
    [_loginButton setTitle:@"Logging you in..." forState:UIControlStateNormal];
    [_loginActivity startAnimating];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] facebookSignIn];
}

#pragma mark -
#pragma mark Delegate method From FacebookSession

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
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] facebookSignIn];
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
            [_loginActivity stopAnimating];
        }];
#endif
    });
    
}

-(void)permissionsError:(NSError*)e{
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            [_loginActivity stopAnimating];
            [_loginButton setTitle:@"Login Using Facebook" forState:UIControlStateNormal];
   });
        
}

-(void)facebookAuthComplete:(NSNotification*) note{
    [self pushToHomeScreen];
    
}
-(void)authenticationFailed:(NSNotification*) note{
    [self permissionsError:nil];
}
-(void)pushToHomeScreen{
    
    [_loginActivity stopAnimating];
    [_loginButton setTitle:@"Login Using Facebook" forState:UIControlStateNormal];

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
