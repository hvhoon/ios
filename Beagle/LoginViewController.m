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
@interface LoginViewController ()<FacebookLoginSessionDelegate>{
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
}
@end

@implementation LoginViewController

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
    [self pushToHomeScreen];
}
-(void)facebookAccountNotSetup{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        controller.view.hidden = YES;
        [self presentViewController:controller animated:NO completion:^{
            //[controller.view endEditing:NO];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
