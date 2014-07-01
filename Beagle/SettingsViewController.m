//
//  SettingsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "SettingsViewController.h"
#import "FriendsViewController.h"
#import "FeedbackReporting.h"

@interface SettingsViewController ()<ServerManagerDelegate>
@property(nonatomic,strong)ServerManager*updateFBTickerManager;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *profileNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *fbTickerSwitch;
@end

@implementation SettingsViewController
@synthesize updateFBTickerManager=_updateFBTickerManager;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.slidingViewController setAnchorRightRevealAmount:270.0f];
     self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    if([[[BeagleManager SharedInstance]beaglePlayer]profileData]==nil){
        
        [self imageCircular:[UIImage imageNamed:@"picbox"]];
        
        
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl]];
        [queue addOperation:operation];
        
    }
    else{
        _profileImageView.image=[BeagleUtilities imageCircularBySize:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]] sqr:100.0f];
    }
    
    if([[[[BeagleManager SharedInstance]beaglePlayer]last_name]length]!=0)
        _profileNameLabel.text =[NSString stringWithFormat:@"%@ %@",[[[BeagleManager SharedInstance]beaglePlayer]first_name],[[[BeagleManager SharedInstance]beaglePlayer]last_name]];
    else{
        _profileNameLabel.text =[[[BeagleManager SharedInstance]beaglePlayer]first_name];
    }
    BeagleManager *BG=[BeagleManager SharedInstance];
    BeagleUserClass *player=BG.beaglePlayer;

    _fbTickerSwitch.on= player.fb_ticker;
	// Do any additional setup after loading the view.
}


- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:100.0f];
}
- (IBAction)sliderButtonClicked:(id)sender{
    NSString *identifier = [NSString stringWithFormat:@"mainScreen"];
    UIButton *button=(UIButton*)sender;
    switch (button.tag) {
        case 2:
        {
            identifier=@"homeScreen";
        }
            break;
            
        case 3:
        {
            identifier=@"profileScreen";
        }
            break;

        case 4:
        {
            if ([[FeedbackReporting sharedInstance] canSendFeedback]) {
                UINavigationController* shareFeedbackController = [[FeedbackReporting sharedInstance] shareFeedbackController];

                [self presentViewController:shareFeedbackController animated:YES completion:Nil];
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please setup your email account" message:nil
                                                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                
                [alert show];
                
            }
            return;

        }
        case 5:
        {
            identifier=@"aboutUs";
        }
            break;
            
        case 8:
        {
            identifier=@"loginScreen";
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
            [[NSUserDefaults standardUserDefaults]synchronize];

        }
            break;
    }
    
    UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
 
        if([identifier isEqualToString:@"homeScreen"]&& [(AppDelegate*)[[UIApplication sharedApplication] delegate]listViewController] != nil){
            newTopViewController=[(AppDelegate*)[[UIApplication sharedApplication] delegate]listViewController];
        }
        else if ([identifier isEqualToString:@"profileScreen"]){
            FriendsViewController *viewController=(FriendsViewController*)newTopViewController;
            viewController.inviteFriends=TRUE;
            [self.navigationController pushViewController:viewController animated:YES];
            return;
        }
    
    // Sliding animation
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];

}

- (IBAction) switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    NSLog( @"The switch is %@", switchControl.on ? @"ON" : @"OFF" );
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    BeagleUserClass *player=BG.beaglePlayer;
    player.fb_ticker=switchControl.on;
    
    if(_updateFBTickerManager!=nil){
        _updateFBTickerManager.delegate = nil;
        [_updateFBTickerManager releaseServerManager];
        _updateFBTickerManager = nil;
    }
    
    _updateFBTickerManager=[[ServerManager alloc]init];
    _updateFBTickerManager.delegate=self;
    [_updateFBTickerManager updateFacebookTickerStatus:player.fb_ticker];

}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallUpdateFbTicker){
        
        _updateFBTickerManager.delegate = nil;
        [_updateFBTickerManager releaseServerManager];
        _updateFBTickerManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id player=[response objectForKey:@"player"];
                if (player != nil && [player class] != [NSNull class]) {
                    
                    id fb_ticker=[player objectForKey:@"fb_ticker"];
                    if (fb_ticker != nil && [fb_ticker class] != [NSNull class]) {
                        [[BeagleManager SharedInstance] userProfileDataUpdate];
                        
                    }
                    
                    
                    
                }
            }
        }
        
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallUpdateFbTicker)
    {
            _updateFBTickerManager.delegate = nil;
            [_updateFBTickerManager releaseServerManager];
            _updateFBTickerManager = nil;
    }
    BeagleManager *BG=[BeagleManager SharedInstance];
    BeagleUserClass *player=BG.beaglePlayer;
    player.fb_ticker=!player.fb_ticker;
    
    [_fbTickerSwitch setOn:player.fb_ticker animated:YES];

    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    BeagleManager *BG=[BeagleManager SharedInstance];
    BeagleUserClass *player=BG.beaglePlayer;
    player.fb_ticker=!player.fb_ticker;
    
    [_fbTickerSwitch setOn:player.fb_ticker animated:YES];

    if(serverRequest==kServerCallUpdateFbTicker)
    {
            _updateFBTickerManager.delegate = nil;
            [_updateFBTickerManager releaseServerManager];
            _updateFBTickerManager = nil;
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
