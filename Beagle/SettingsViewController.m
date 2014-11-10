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
#import "AboutUsViewController.h"
#import <Instabug/Instabug.h>
#import "InitialSlidingViewController.h"
#import "LinkViewController.h"
@interface SettingsViewController ()<ServerManagerDelegate>
@property(nonatomic,strong)ServerManager*updateFBTickerManager;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *profileNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *fbTickerSwitch;
@property (weak, nonatomic) IBOutlet UILabel *version;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kFacebookAuthenticationFailed object:Nil];

    [self.slidingViewController setAnchorRightRevealAmount:[UIScreen mainScreen].bounds.size.width-50.0f];
     self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    // Extract App Name
    NSDictionary *appMetaData = [[NSBundle mainBundle] infoDictionary];
    NSString* bundleName = [appMetaData objectForKey:@"CFBundleShortVersionString"];
    NSString* buildNumber = [appMetaData objectForKey:@"CFBundleVersion"];
    
    [_version setTextColor:[BeagleUtilities returnBeagleColor:3]];
    
    // Build text
    _version.text = [NSString stringWithFormat:@"Beagle v%@ (%@)", bundleName, buildNumber];
    
    if([[[BeagleManager SharedInstance]beaglePlayer]profileData]==nil){
        
        [self imageCircular:[UIImage imageNamed:@"picbox"]];
        _profileImageView.layer.cornerRadius = _profileImageView.frame.size.width/2;
        _profileImageView.clipsToBounds = YES;
        _profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _profileImageView.layer.borderWidth = 3.0f;

        
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl]];
        [queue addOperation:operation];
        
    }
    else{
        _profileImageView.image=[BeagleUtilities imageCircularBySize:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]] sqr:200.0f];
        _profileImageView.layer.cornerRadius = _profileImageView.frame.size.width/2;
        _profileImageView.clipsToBounds = YES;
        _profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _profileImageView.layer.borderWidth = 3.0f;
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

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
   //[[NSNotificationCenter defaultCenter] removeObserver:self name:kFacebookAuthenticationFailed object:nil];
}
-(void)authenticationFailed:(NSNotification*) note{

    if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
        
    NSArray *controllerObjects = [[self navigationController]viewControllers];
    NSInteger index=0;
    NSMutableArray *items=[NSMutableArray new];
    for(id controller in [controllerObjects reverseObjectEnumerator]){
        NSLog(@"controller=%@",controller);
        
        if([controller isKindOfClass:[InitialSlidingViewController class]]){
            [items addObject:[NSNumber numberWithInteger:index]];
        }
        index++;
        
    }
    if([items count]>0){
        if([items count]==2){
            [[self navigationController] popViewControllerAnimated:NO];
            [[self navigationController] popViewControllerAnimated:NO];
        }else{
            [[self navigationController] popViewControllerAnimated:NO];            
        }
    }
    UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginScreen"];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] closeAllFBSessions];
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"FacebookLogin"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    // Sliding animation
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = newTopViewController;
    self.slidingViewController.topViewController.view.frame = frame;
    [self.slidingViewController resetTopView];
    }];
        
  }
}



- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    if (image)
        [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:200.0f];
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
                
                MFMailComposeViewController* inviteuserController = [[FeedbackReporting sharedInstance] inviteAUserController:nil firstName:[[[[[BeagleManager SharedInstance]beaglePlayer]first_name] componentsSeparatedByString:@" "] objectAtIndex:0]];
                [self presentViewController:inviteuserController animated:YES completion:Nil];
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please setup your email account" message:nil
                                                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                
                [alert show];
                
            }
            return;
        }
            break;

        case 5:
        {
            [Instabug invokeFeedbackSender];
            return;

        }
        case 6:
        {
            identifier=@"aboutUs";
        }
            break;
            
        case 7:
        {
            identifier=@"loginScreen";
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] closeAllFBSessions];
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
        else if ([identifier isEqualToString:@"aboutUs"]){

            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            LinkViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"webLinkScreen"];
            viewController.linkString=@"http://about.mybeagleapp.com";
            [self.navigationController pushViewController:viewController animated:YES];
            return;
            
            
//            AboutUsViewController *viewController=(AboutUsViewController*)newTopViewController;
//            [self.navigationController pushViewController:viewController animated:YES];
//            return;
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

    NSString *message = NSLocalizedString (@"You shouldn't be doing stuff on Facebook anyways.",
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
