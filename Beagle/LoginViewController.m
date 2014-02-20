//
//  LoginViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LoginViewController.h"
#import "InitialSlidingViewController.h"
@interface LoginViewController (){
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
    [self performSelector:@selector(pushToHomeScreen) withObject:nil afterDelay:3.0];
    
}
-(void)pushToHomeScreen{
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"FacebookLogin"];
    [activityIndicatorView stopAnimating];
    [activityIndicatorView setHidden:YES];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    InitialSlidingViewController *initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"initialBeagle"];
    [self.navigationController pushViewController:initialViewController animated:YES];
    
    
    

}

- (void)viewDidLoad
{
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
