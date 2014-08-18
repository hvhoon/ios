//
//  AppDelegate.h
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Appsee/Appsee.h>
#import <CoreLocation/CoreLocation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>{
}
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *_locationManager;
@property (nonatomic,strong)id listViewController;
@property (strong, nonatomic) UIWindow *window;
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error;
- (void)startStandardUpdates;
-(void)checkForFacebookSSOLogin;
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;

@end
