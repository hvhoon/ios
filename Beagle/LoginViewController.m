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
@interface LoginViewController ()<FacebookLoginSessionDelegate,ServerManagerDelegate>{
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    ServerManager *loginServerManager;
     NSMutableData *_data;
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
- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{

    if(serverRequest==kServerCallUserRegisteration)
    {
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }

      NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
      BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallUserRegisteration)
    {
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
