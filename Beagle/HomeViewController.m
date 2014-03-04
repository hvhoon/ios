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
#import "BGStockPhotoManager.h"
#import "ASIHTTPRequest.h"
#define kTimerIntervalInSeconds 10
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
    
    [self retrieveLocationAndUpdateBackgroundPhoto];

	// Do any additional setup after loading the view.
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
                    
                    NSURL *url = [NSURL URLWithString:@"http://api.wunderground.com/api/5706a66cb7258dd4/conditions/q/NY/Glens%20Falls.json"];
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
                                
                                [self crossDissolvePhotos:flickrRequestInfo.photos withTitle:flickrRequestInfo.userInfo];
                            } else {
                                
                                //Error : Stock photos
                                [[BGStockPhotoManager sharedManager] randomStockPhoto:^(BGPhotos * photos) {
                                    [self crossDissolvePhotos:photos withTitle:@""];
                                }];
                                
                                
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
            [[BGStockPhotoManager sharedManager] randomStockPhoto:^(BGPhotos * photos) {
                [self crossDissolvePhotos:photos withTitle:@""];
            }];
            
            
            NSLog(@"Location: %@", error.description);
        }
    }];
}

- (void) crossDissolvePhotos:(BGPhotos *) photos withTitle:(NSString *) title {
    [UIView transitionWithView:self.backgroundPhoto duration:1.0f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.backgroundPhoto.image = photos.photo;
        
    } completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
