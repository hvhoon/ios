//
//  HomeViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "HomeViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "Constants.h"
#import "BGFlickrManager.h"
#import "BGLocationManager.h"
#import "ASIHTTPRequest.h"
#import "ActivityViewController.h"
@interface HomeViewController ()
@property(nonatomic, strong) IBOutlet UIImageView *backgroundPhoto;
@end

@implementation HomeViewController
@synthesize backgroundPhoto;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)revealUnderRight:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[SettingsViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsScreen"];
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[NotificationsViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationsScreen"];
    }
      [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
   // [self retrieveLocationAndUpdateBackgroundPhoto];
    
    
    UIView *navigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 200)];
    
    navigationView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"defaultLocation"]];
    [self.view addSubview:navigationView];
    
    CGSize size = CGSizeMake(80,999);
    
    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentLeft;
    

    CGRect textRect = [@"New York"
                       boundingRectWithSize:size
                       options:NSStringDrawingUsesLineFragmentOrigin
                       attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f],
                                     NSParagraphStyleAttributeName: paragraphStyle }
                       context:nil];
    
    
    UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(15,30, textRect.size.width, textRect.size.height)];
    fromLabel.text = @"New York";
    fromLabel.font = [UIFont systemFontOfSize:18.0f];
    fromLabel.numberOfLines = 1;
    fromLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    fromLabel.adjustsFontSizeToFitWidth = YES;
    fromLabel.adjustsFontSizeToFitWidth = YES;
    fromLabel.minimumScaleFactor = 10.0f/18.0f;
    fromLabel.clipsToBounds = YES;
    fromLabel.backgroundColor = [UIColor clearColor];
    fromLabel.textColor = [UIColor blackColor];
    fromLabel.textAlignment = NSTextAlignmentLeft;
    [navigationView addSubview:fromLabel];
    
    UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [eventButton addTarget:self action:@selector(createANewActivity:)forControlEvents:UIControlEventTouchUpInside];
    eventButton.frame = CGRectMake(270.0, 25.0, 34.0, 34.0);
    [navigationView addSubview:eventButton];

    

	// Do any additional setup after loading the view.
}

-(void)createANewActivity:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];

    [self.navigationController presentViewController:activityNavigationController animated:YES completion:nil];
    
}
- (void) retrieveLocationAndUpdateBackgroundPhoto {
    
    //Location
    [[BGLocationManager sharedManager] locationRequest:^(CLLocation * location, NSError * error) {
        
        
        if(!error) {
            
            
            CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
            CLLocation *newLocation=[[CLLocation alloc]initWithLatitude:[[NSNumber numberWithDouble:[BGLocationManager sharedManager].locationBestEffort.coordinate.latitude] doubleValue] longitude:[[NSNumber numberWithDouble:[BGLocationManager sharedManager].locationBestEffort.coordinate.longitude] doubleValue]];
            [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                
                if(!error) {
                for (CLPlacemark * placemark in placemarks) {
                    NSLog(@"placemark.city=%@",[placemark.addressDictionary objectForKey:@"City"]);
                    NSLog(@"placemark.country=%@",placemark.country);
                    NSLog(@"placemark.locality=%@",placemark.locality);
                    NSLog(@"placemark.subLocality=%@",placemark.subLocality);
                    NSLog(@"placemark.administrativeArea=%@",placemark.administrativeArea);
                    NSLog(@"placemark.subAdministrativeArea=%@",placemark.subAdministrativeArea);
                    
                    NSString *urlString=[NSString stringWithFormat:@"http://api.wunderground.com/api/5706a66cb7258dd4/conditions/q/%@/%@.json",placemark.administrativeArea,[placemark.addressDictionary objectForKey:@"City"]];
                    
                    
                    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
                    NSURL *url = [NSURL URLWithString:urlString];
                    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                    [request setCompletionBlock:^{
                        // Use when fetching text data
                        NSError* error;
                        NSString *jsonString = [request responseString];
                        NSDictionary* weatherDictionary = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                        NSDictionary *current_observation=[weatherDictionary objectForKey:@"current_observation"];
                        NSString *weather=[current_observation objectForKey:@"weather"];
                            NSLog(@"weather=%@",weather);
                        [BGLocationManager sharedManager].weatherCondition=weather;
                        
                        

                            //Flickr
                            [[BGFlickrManager sharedManager] randomPhotoRequest:^(FlickrRequestInfo * flickrRequestInfo, NSError * error) {
                                
                                if(!error) {
                                    NSLog(@"Url=%@",flickrRequestInfo.userPhotoWebPageURL);
                                    
                                    [self crossDissolvePhotos:flickrRequestInfo.photo withTitle:flickrRequestInfo.userInfo];
                                } else {
                                    
                                    //Error : Stock photos
                                    [self crossDissolvePhotos:[UIImage imageNamed:@"defaultLocation"] withTitle:@""];
                                    
                                    NSLog(@"Flickr: %@", error.description);
                                }
                            }];

                            
                        



                        
                    }];
                    [request setFailedBlock:^{
                        NSError *error = [request error];
                        NSLog(@"error=%@",[error description]);
                    }];
                    [request startAsynchronous];

                        
                    }
                
                }
                else{
                     NSLog(@"reverseGeocodeLocation: %@", error.description);
                }
            }];
        } else {
            
            //Error : Stock photos
                [self crossDissolvePhotos:[UIImage imageNamed:@"defaultLocation"] withTitle:@""];
            
            
            NSLog(@"Location: %@", error.description);
        }
    }];
}

- (void) crossDissolvePhotos:(UIImage *) photo withTitle:(NSString *) title {
    [UIView transitionWithView:self.backgroundPhoto duration:1.0f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.backgroundPhoto.image =photo;
        
    } completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
