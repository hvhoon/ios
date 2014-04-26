//
//  SettingsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *profileNameLabel;
@end

@implementation SettingsViewController
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
        _profileImageView.image=[BeagleUtilities imageCircularBySize:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData] scale:2.0] sqr:50.0f];
    }
    
    if([[[[BeagleManager SharedInstance]beaglePlayer]last_name]length]!=0)
        _profileNameLabel.text =[NSString stringWithFormat:@"%@ %@",[[[BeagleManager SharedInstance]beaglePlayer]first_name],[[[BeagleManager SharedInstance]beaglePlayer]last_name]];
    else{
        _profileNameLabel.text =[[[BeagleManager SharedInstance]beaglePlayer]first_name];
    }
    

	// Do any additional setup after loading the view.
}


- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
    UIImage* image =[[UIImage alloc] initWithData:imageData scale:2.0];
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:50.0f];
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
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
