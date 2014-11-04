//
//  AppDelegate.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import <Instabug/Instabug.h>
#import "HomeViewController.h"
#import "DetailInterestViewController.h"
#import "JSON.h"
@interface AppDelegate ()<ServerManagerDelegate>{
    ServerManager *notificationServerManager;
    NSInteger attempts;
}
@property(nonatomic,strong)ServerManager *loginServerManager;
@property(nonatomic,strong)ServerManager *notificationServerManager;
@end

@implementation AppDelegate
@synthesize listViewController;
@synthesize currentLocation;
@synthesize _locationManager = locationManager;
@synthesize loginServerManager=_loginServerManager;
@synthesize notificationServerManager=_notificationServerManager;
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
    }


    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // Starting crash analytics
    [Crashlytics startWithAPIKey:@"e8e7ac59367e936ecae821876cc411ec67427e47"];
    NSString *storyboardId = [[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"] ? @"initialNavBeagle" : @"loginNavScreen";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController*initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    
    // Facebook SDK settings
    [FBSettings enablePlatformCompatibility:YES];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];
    
    if(![BeagleUtilities checkIfTheInviteHTMLisAtTheDocuementFolderLocation]){
    NSString *inviteHtmlPath = [[NSBundle mainBundle] pathForResource:@"Invite" ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:inviteHtmlPath];
    [BeagleUtilities saveHTMLFileInDocumentDirectory:htmlData];
    }else{
        // create a block and download the file from Amazon Ec2
        [self getupdatedInviteHTMLFromTheServer];
    }
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f){
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // use registerUserNotificationSettings
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    }
else
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound |
      UIRemoteNotificationTypeAlert)];
}

    
    // Instabug integration
    [Instabug startWithToken:@"0fe55a803d01c2d223d89b450dcae674" captureSource:IBGCaptureSourceUIKit invocationEvent:IBGInvocationEventShake];
    [Instabug setEmailIsRequired:NO];
    [Instabug setWillShowEmailField:NO];
    
    [Instabug setWillShowTutorialAlert:NO];
    [Instabug setWillShowStartAlert:NO];
    
    [Instabug setButtonsFontColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0]];
    [Instabug setButtonsColor:[UIColor colorWithRed:(255/255.0) green:(115/255.0) blue:(0/255.0) alpha:1.0]];
    [Instabug setHeaderFontColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0]];
    [Instabug setHeaderColor:[UIColor colorWithRed:(255/255.0) green:(149/255.0) blue:(0/255.0) alpha:1.0]];
    [Instabug setTextFontColor:[UIColor colorWithRed:(82/255.0) green:(83/255.0) blue:(83/255.0) alpha:1.0]];
    [Instabug setTextBackgroundColor:[UIColor colorWithRed:(249/255.0) green:(249/255.0) blue:(249/255.0) alpha:1.0]];
    
    
    if([[NSUserDefaults standardUserDefaults]valueForKey:@"HourlyUpdate"]==nil){
        [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"HourlyUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    if([[NSUserDefaults standardUserDefaults]valueForKey:@"LastLocationLat"]==nil){
        [[NSUserDefaults standardUserDefaults]setDouble:0.0f  forKey:@"LastLocationLat"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    if([[NSUserDefaults standardUserDefaults]valueForKey:@"LastLocationLong"]==nil){
        [[NSUserDefaults standardUserDefaults]setDouble:0.0f  forKey:@"LastLocationLong"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    // Whenever a person opens the app, check for a cached session
    
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          // This method will be called EACH time the session state changes,
                                          // also for intermediate states and NOT just when the session open
                                          [self sessionStateChanged:session state:state error:error];
                                      }];
        
    }
  }
    
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f){
//    [self handlePush:launchOptions];
    
    
    NSDictionary *remoteNotificationPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotificationPayload && ([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"])) {
        
        if([[[remoteNotificationPayload valueForKey:@"p"] valueForKey:@"nty"]integerValue]!=CANCEL_ACTIVITY_TYPE){
            [[BeagleManager SharedInstance]getUserObjectInAutoSignInMode];
            
            DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
            viewController.interestServerManager=[[ServerManager alloc]init];
            viewController.interestServerManager.delegate=viewController;
            viewController.isRedirected=TRUE;
            if([[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] valueForKey:@"p"] valueForKey:@"nty"]integerValue]==CHAT_TYPE)
                viewController.toLastPost=TRUE;
            [viewController.interestServerManager getDetailedInterest:[[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] valueForKey:@"p"] valueForKey:@"aid"]integerValue]];
            initViewController.navigationItem.backBarButtonItem.title=@"";
            initViewController.navigationBar.topItem.title=@"";

            [initViewController pushViewController:viewController animated:NO];
            
            //            [BeagleUtilities updateBadgeInfoOnTheServer:[[[remoteNotificationPayload valueForKey:@"p"] valueForKey:@"nid"]integerValue]];
        }
        
    }
 }

    return YES;
}


-(void)getupdatedInviteHTMLFromTheServer{
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@",@"http://files.parsetfss.com/d3381117-b014-42cb-ab06-50aaf273b202/tfss-7b9640c7-1d32-408a-96d5-c0cff971ba18-Invite.html"]];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if ([data length] > 0 && error == nil){
             
             [self performSelectorOnMainThread:@selector(receivedData:) withObject:data waitUntilDone:NO];
         }else if ([data length] == 0 && error == nil){
         }else if (error != nil && error.code == NSURLErrorTimedOut){ //used this NSURLErrorTimedOut from foundation error responses
         }else if (error != nil){
             NSLog(@"Error=%@",[error description]);
         }
     }];
}

-(void)receivedData:(NSData*)returnData{
    
  [BeagleUtilities saveHTMLFileInDocumentDirectory:returnData];
    
    
}
#pragma mark - location Manager calls

- (void)startStandardUpdates {
    
	if (nil == locationManager) {
		locationManager = [[CLLocationManager alloc] init];
	}
    
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
	// Set a movement threshold for new events.
	locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
    
    // IOS 8 Support
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f){
    
    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
    }
	[locationManager startUpdatingLocation];
    
	CLLocation *currentLoc = locationManager.location;
	if (currentLoc) {
		self.currentLocation = currentLoc;
	}
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted||status==kCLAuthorizationStatusNotDetermined) {
        // Clear out any pending location requests (which will execute the blocks with a status that reflects
        // the unavailability of location services) since we now no longer have location services permissions
    NSLog(@"kCLAuthorizationStatusNotDetermined Restricted");
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    else if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
#else
    else if (status == kCLAuthorizationStatusAuthorized) {
#endif

			[locationManager startUpdatingLocation];
    }
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < _IPHONE_7_0
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    self.currentLocation=newLocation;
    
}
#else
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    CLLocation*newLocation=[locations lastObject];
    self.currentLocation=newLocation;
    
}
#endif
#define kLocationFetchTimeout 5
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Error: %@", [error description]);
    
	if (error.code == kCLErrorDenied) {
		[locationManager stopUpdatingLocation];
        [[NSNotificationCenter defaultCenter] postNotificationName:kErrorToGetLocation object:self userInfo:nil];
	}
    else if (error.code == kCLErrorLocationUnknown) {
		// todo: retry?
		// set a timer for five seconds to cycle location, and if it fails again, bail and tell the user.
        
        if(attempts!=3){
            attempts++;
            [self performSelector:@selector(timeoutLocationFetch) withObject:nil afterDelay:kLocationFetchTimeout];
        }else{
            attempts=0;
            [locationManager stopUpdatingLocation];
            [[NSNotificationCenter defaultCenter] postNotificationName:kErrorToGetLocation object:self userInfo:nil];
            
        }
	}
    else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Where's Waldo?"
		                                                message:[error description]
		                                               delegate:nil
		                                      cancelButtonTitle:nil
		                                      otherButtonTitles:@"Ok", nil];
		[alert show];
	}
}

- (void)setCurrentLocation:(CLLocation *)aCurrentLocation {
	currentLocation = aCurrentLocation;
    BeagleManager *BG=[BeagleManager SharedInstance];
    BG.currentLocation=currentLocation;
    [locationManager stopUpdatingLocation];
    locationManager.delegate=nil;
    
	dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateReceived object:self userInfo:nil];
        
	});
}

- (void) timeoutLocationFetch {
    NSLog(@"LocationService:timeout");
    [locationManager startUpdatingLocation];
}
#pragma mark - push Notifications calls

- (void)handlePush:(NSDictionary *)launchOptions {
    
    // If the app was launched in response to a push notification, we'll handle the payload here
    NSDictionary *remoteNotificationPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotificationPayload) {

        if(_notificationServerManager!=nil){
            _notificationServerManager.delegate = nil;
            [_notificationServerManager releaseServerManager];
            _notificationServerManager = nil;
        }
        _notificationServerManager=[[ServerManager alloc]init];
        _notificationServerManager.delegate=self;

        [self handleOfflineNotifications:remoteNotificationPayload];
        
        }
    }

//Device Token failed
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error{
	NSLog(@"Failed to get token, error: %@", error);
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"device_token"];
}


//Device Token
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *token = [[NSString stringWithFormat:@"%@",deviceToken] stringByReplacingOccurrencesOfString:@" " withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    NSLog(@"token: %@", token);
    
    [[NSUserDefaults standardUserDefaults] setValue:token forKey:@"device_token"];
}


-(void)handleOnlineNotifications:(NSDictionary*)userInfo{
    
        
        // app was already in the foreground
        
        if([[[userInfo valueForKey:@"p"] valueForKey:@"nty"]integerValue]==CHAT_TYPE){
            [_notificationServerManager requestInAppNotificationForPosts:[[[userInfo valueForKey:@"p"] valueForKey:@"cid"]integerValue] notifType:1];
            
            
            [[BeagleManager SharedInstance]setBadgeCount:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            
            NSLog(@"badge Value=%ld",(long)[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]);
            
            
        }else if([[[userInfo valueForKey:@"p"] valueForKey:@"nty"]integerValue]==CANCEL_ACTIVITY_TYPE){
            NSMutableDictionary *cancelDictionary=[NSMutableDictionary new];
            [cancelDictionary setObject:[[userInfo valueForKey:@"aps"] valueForKey:@"alert"] forKey:@"message"];
            [cancelDictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"nty"] forKey:@"notification_type"];
            [cancelDictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"nid"] forKey:@"nid"];
            
            [[BeagleManager SharedInstance]setBadgeCount:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            
            NSLog(@"badge Value=%ld",(long)[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]);

            
            [cancelDictionary setObject:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",[[userInfo valueForKey:@"p"] valueForKey:@"fbuid"]] forKey:@"photo_url"];
            NSMutableDictionary *activity=[NSMutableDictionary new];
            [activity setObject:[NSNumber numberWithInteger:[[[userInfo valueForKey:@"p"] valueForKey:@"aid"]integerValue]] forKey:@"id"];
            [cancelDictionary setObject:activity forKey:@"activity"];
            
            NSOperationQueue *queue = [NSOperationQueue new];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                initWithTarget:self
                                                selector:@selector(loadProfileImageData:)
                                                object:cancelDictionary];
            [queue addOperation:operation];
            
            
        }
        else{
            [_notificationServerManager requestInAppNotification:[[[userInfo valueForKey:@"p"] valueForKey:@"nid"]integerValue] notifType:1];
            
        }
    
}
-(void)handleOfflineNotifications:(NSDictionary*)userInfo{
#if 1
    // app was just brought from background to foreground
    NSLog(@"userInfo=%@",userInfo);
        if([[[userInfo valueForKey:@"p"] valueForKey:@"nty"]integerValue]==CHAT_TYPE){
            

//            [_notificationServerManager requestInAppNotificationForPosts:[[[userInfo valueForKey:@"p"] valueForKey:@"cid"]integerValue]notifType:2];
            
            NSMutableDictionary *dictionary=[NSMutableDictionary new];
            [dictionary setObject:[NSNumber numberWithInteger:2] forKey:@"notifType"];
            
            [dictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"nty"] forKey:@"notification_type"];
            [dictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"nid"] forKey:@"nid"];

            [[BeagleManager SharedInstance]setBadgeCount:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            
            NSLog(@"badge Value=%ld",(long)[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]);
            
            [dictionary setObject:[[userInfo valueForKey:@"aps"] valueForKey:@"alert"] forKey:@"msg"];
           [dictionary setObject:[NSNumber numberWithInteger:[[[userInfo valueForKey:@"p"] valueForKey:@"aid"]integerValue]] forKey:@"activity_id"];
  
            [dictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"cid"] forKey:@"chatid"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
            
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kNotificationForInterestPost object:nil userInfo:dictionary]];
            
        }else{
            

//        else if([[[userInfo valueForKey:@"p"] valueForKey:@"nty"]integerValue]==CANCEL_ACTIVITY_TYPE){
        
            NSMutableDictionary *dictionary=[NSMutableDictionary new];
            [dictionary setObject:[NSNumber numberWithInteger:2] forKey:@"notifType"];
            
            [dictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"nty"] forKey:@"notification_type"];
            [dictionary setObject:[[userInfo valueForKey:@"p"] valueForKey:@"nid"] forKey:@"nid"];
            
            [[BeagleManager SharedInstance]setBadgeCount:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]];
            
            NSLog(@"badge Value=%ld",(long)[[[userInfo valueForKey:@"aps"] valueForKey:@"badge"]integerValue]);

            [dictionary setObject:[[userInfo valueForKey:@"aps"] valueForKey:@"alert"] forKey:@"message"];
            
            NSMutableDictionary *activity=[NSMutableDictionary new];
            [activity setObject:[NSNumber numberWithInteger:[[[userInfo valueForKey:@"p"] valueForKey:@"aid"]integerValue]] forKey:@"id"];
            [dictionary setObject:activity forKey:@"activity"];

            [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
            
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:nil userInfo:dictionary]];

        }
//            else
//            [_notificationServerManager requestInAppNotification:[[[userInfo valueForKey:@"p"] valueForKey:@"nid"]integerValue] notifType:2];
        
        // create a service which will return data and update the view badge count automatically
        
#endif
}

-(void)handleSilentNotifications:(NSDictionary*)userInfo{
        NSLog(@"userInfo=%@",userInfo);
        
    [_notificationServerManager requestInAppNotification:[[[userInfo valueForKey:@"p"] valueForKey:@"nid"]integerValue] notifType:3];
        
        
}

- (void)loadProfileImageDataForSilentPost:(NSMutableDictionary*)notificationDictionary {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[notificationDictionary objectForKey:@"photo_url"]]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [notificationDictionary setObject:image forKey:@"profileImage"];
    [notificationDictionary setObject:[NSNumber numberWithInteger:3] forKey:@"notifType"];
    [self performSelectorOnMainThread:@selector(sendSilentNotification:) withObject:notificationDictionary waitUntilDone:NO];
}

- (void)loadProfileImageData:(NSMutableDictionary*)notificationDictionary {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[notificationDictionary objectForKey:@"photo_url"]]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [notificationDictionary setObject:image forKey:@"profileImage"];
    [notificationDictionary setObject:[NSNumber numberWithInteger:1] forKey:@"notifType"];
    [self performSelectorOnMainThread:@selector(sendAppNotification:) withObject:notificationDictionary waitUntilDone:NO];
}
-(void)sendAppNotification:(NSMutableDictionary*)appNotifDictionary{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kBeagleBadgeCount object:self userInfo:nil]];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:self userInfo:appNotifDictionary]];
    

}
- (void)loadProfileImageDataForAPost:(NSMutableDictionary*)notificationDictionary {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[notificationDictionary objectForKey:@"player_photo_url"]]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [notificationDictionary setObject:image forKey:@"profileImage"];
    [notificationDictionary setObject:[NSNumber numberWithInteger:1] forKey:@"notifType"];
    [self performSelectorOnMainThread:@selector(sendAppNotificationForPost:) withObject:notificationDictionary waitUntilDone:NO];
}
-(void)sendAppNotificationForPost:(NSMutableDictionary*)appNotifDictionary{
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kNotificationForInterestPost object:self userInfo:appNotifDictionary]];
    
    
}
-(void)sendSilentNotification:(NSMutableDictionary*)appNotifDictionary{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:self userInfo:appNotifDictionary]];
}


-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    
    // Pass on
//    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
    
    {
        
        
        
        NSLog(@"didReceiveRemoteNotification");
        if([userInfo[@"aps"][@"alert"] length]== 0){
            if(_notificationServerManager!=nil){
                _notificationServerManager.delegate = nil;
                [_notificationServerManager releaseServerManager];
                _notificationServerManager = nil;
            }
            _notificationServerManager=[[ServerManager alloc]init];
            _notificationServerManager.delegate=self;
            
            
            [self handleSilentNotifications:userInfo];
            
            // Check if in background
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
                NSLog(@"UIApplicationStateInactive");
                
                // User opened the push notification
                
            } else if(application.applicationState == UIApplicationStateActive){
                NSLog(@"UIApplicationStateActive");
                
                
            }else{
                // User hasn't opened it, this was a silent update
                NSLog(@"User hasn't opened it, this was a silent update");
                
                
            }
            
            //         [self presentNotification];
            
            
        }else{
            
            if(_notificationServerManager!=nil){
                _notificationServerManager.delegate = nil;
                [_notificationServerManager releaseServerManager];
                _notificationServerManager = nil;
            }
            _notificationServerManager=[[ServerManager alloc]init];
            _notificationServerManager.delegate=self;
            
            
            if ( application.applicationState == UIApplicationStateActive){
                [self handleOnlineNotifications:userInfo];
            }
            else {
                [self handleOfflineNotifications:userInfo];
            }
        }
        
    }
    
}
#if 0
-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    
    
    NSLog(@"didReceiveRemoteNotification");
    if([userInfo[@"aps"][@"alert"] length]== 0){
#if 0
        
        
        if (self.downloadTask) {
            return;
        }
        
        NSURL *downloadURL=[NSURL URLWithString:[NSString stringWithFormat:@"%@rsparameter.json?id=%ld",herokuHost,[[[userInfo valueForKey:@"p"] valueForKey:@"nid"]integerValue]]];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        self.downloadTask = [[self backgroundURLSession] downloadTaskWithRequest:request];
        [self.downloadTask resume];
#endif
        
        if(_notificationServerManager!=nil){
            _notificationServerManager.delegate = nil;
            [_notificationServerManager releaseServerManager];
            _notificationServerManager = nil;
        }
        _notificationServerManager=[[ServerManager alloc]init];
        _notificationServerManager.delegate=self;
        
        
        [self handleSilentNotifications:userInfo];
        
        // Check if in background
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
            NSLog(@"UIApplicationStateInactive");
            
            // User opened the push notification
            
        } else if(application.applicationState == UIApplicationStateActive){
            NSLog(@"UIApplicationStateActive");
            
            
        }else{
            // User hasn't opened it, this was a silent update
            NSLog(@"User hasn't opened it, this was a silent update");
            
            
        }
        
        //         [self presentNotification];
        
        
    }else{
        
        if(_notificationServerManager!=nil){
            _notificationServerManager.delegate = nil;
            [_notificationServerManager releaseServerManager];
            _notificationServerManager = nil;
        }
        _notificationServerManager=[[ServerManager alloc]init];
        _notificationServerManager.delegate=self;
        
        
        if ( application.applicationState == UIApplicationStateActive){
            [self handleOnlineNotifications:userInfo];
        }
        else if( application.applicationState != UIApplicationStateBackground){
              [self handleOfflineNotifications:userInfo];
        }
    }
    completionHandler(UIBackgroundFetchResultNewData);

}
#endif

-(void)presentNotification{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"Download Complete!";
    localNotification.alertAction = @"Background Transfer Download!";
    
    //On sound
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    //increase the badge number of application plus 1
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

#pragma mark - application Delegate calls

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"applicationWillEnterForeground");
        if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
    [[BeagleManager SharedInstance]setBadgeCount:[[UIApplication sharedApplication]applicationIconBadgeNumber]];

    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"AutoRefreshEvents" object:self userInfo:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHomeScreenAndNotificationStack object:self userInfo:nil];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateNotificationStack object:self userInfo:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdatePostsOnInterest object:self userInfo:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    // Handle the user leaving the app while the Facebook login dialog is being shown
    // For example: when the user presses the iOS "home" button while the login dialog is active
    [FBAppCall handleDidBecomeActive];
}


#pragma mark - Facebook Session Delegate calls



-(BOOL)checkForFacebookSesssion{
    if(FBSession.activeSession.state == FBSessionStateOpen
       || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
        return YES;
    
    return NO;
}
-(void)facebookSignIn{
    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
        
        // If the session state is not any of the two "open" states when the button is clicked
    } else {
        
        NSArray* permissions = [NSArray arrayWithObjects:@"public_profile",@"email",@"user_friends", nil];
        FBSession *session = [[FBSession alloc] initWithAppID:@"500525846725031" permissions:permissions defaultAudience:FBSessionDefaultAudienceNone urlSchemeSuffix:nil tokenCacheStrategy:nil];
        [FBSession setActiveSession:session];
        
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent     completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            
            // Open a session showing the user the login UI
            // You must ALWAYS ask for public_profile permissions when opening a session
            //        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
            //                                           allowLoginUI:YES
            //                                      completionHandler:
            //         ^(FBSession *session, FBSessionState state, NSError *error) {
            
            
            // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
            [self sessionStateChanged:session state:state error:error];
        }];
    }
}
// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");
        [self makeRequestForUserData:FBSession.activeSession.accessTokenData.accessToken];
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
    }
    
    if(state==FBSessionStateCreated){
        NSLog(@"FBSessionStateCreated");
    }
    if(state==FBSessionStateCreatedOpening){
        NSLog(@"FBSessionStateCreatedOpening");
    }

    if(state==FBSessionStateOpenTokenExtended){
        NSLog(@"FBSessionStateOpenTokenExtended");
    }

    if(state==FBSessionStateCreatedTokenLoaded){
        NSLog(@"FBSessionStateCreatedTokenLoaded");
    }

    // Handle errors
    if (error){
        NSLog(@"errorode=%ld",(long)[FBErrorUtility errorCategoryForError:error]);
        NSLog(@"Error=%@",[error localizedDescription]);
        
        // If the error requires people using an app to make an action outside of the app in order to recover

        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            // Show the logout alert message
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle" message:@"Your Facebook settings have changed so we've logged you out to protect your account.  Please log back in when you are ready." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
            [alert show];
        }
        else if ([FBErrorUtility errorCategoryForError:error] == 6) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle" message:@"We need some basic Facebook info to show you what's happening around you and tell your friends what you want to do. We promise to never post anything on your wall or spam your friends. If you change your mind please try logging in again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
            [alert show];
        }
        else if ([FBErrorUtility errorCategoryForError:error] == 4) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle" message:@"Please go to Settings > Facebook and allow Beagle to use your account and then try logging in again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
            [alert show];
        }
        else {
            //Get more error information from the error
            NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
            NSLog(@"message=%@",[errorInformation objectForKey:@"message"]);

        }
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookAuthenticationFailed object:self userInfo:nil]];

        
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}


-(void)requestUserForAdditionalPermissions{
    
    

    // These are the permissions we need:
        NSArray *permissionsNeeded = @[@"xmpp_login"];
        
        // Request the permissions the user currently has
        [FBRequestConnection startWithGraphPath:@"/me/permissions"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error){
                                      // These are the current permissions the user has
                                      NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                                      
                                      // We will store here the missing permissions that we will have to request
                                      NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                      
                                      // Check if all the permissions we need are present in the user's current permissions
                                      // If they are not present add them to the permissions to be requested
                                      for (NSString *permission in permissionsNeeded){
                                          if (![currentPermissions objectForKey:permission]){
                                              [requestPermissions addObject:permission];
                                          }
                                      }
                                      
                                      // If we have permissions to request
                                      if ([requestPermissions count] > 0){
                                          // Ask for the missing permissions
                                          [FBSession.activeSession
                                           requestNewReadPermissions:requestPermissions
                                           completionHandler:^(FBSession *session, NSError *error) {
                                               if (!error) {
                                                   // Permission granted, we can request the user information
                                                   NSLog(@"permissionsGranted=%@",session.permissions);
                                                   for(id granted in session.permissions){
                                                       NSLog(@"granted=%@",granted);
                                                   }
                                                   NSLog(@"permissionsDeclined=%@",session.declinedPermissions);
                                                   for(id declined in session.declinedPermissions){
                                                       NSLog(@"declined=%@",declined);
                                                   }
                                                   
                                                   if([session.declinedPermissions count]==0){
                                                       [self makeRequestForUserData:session.accessTokenData.accessToken];
                                                       
                                                   }else{
                                                       [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookAddOnPermissionsDenied object:self userInfo:nil]];
                                                       
                                                   }

                                               } else {
                                                   NSLog(@"error %@", error.description);
                                                   
                                                   //error when permissions not granted
                                                   [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookAddOnPermissionsDenied object:self userInfo:nil]];

                                               }
                                           }];
                                      } else {
                                          // Permissions are already present just invite
                                          [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookSSOLoginAuthentication object:self userInfo:nil]];

                                      
                                      }
                                      
                                  } else {
                                      
                                        // need to come up with an alert message probably no internet connection
                                      NSLog(@"error %@", error.description);


                                  }
                              }];

}

- (void) makeRequestForUserData:(NSString*)accessToken
{

    
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id list, NSError *error) {
        if (!error) {
            // Success! Include your code to handle the results here
            NSLog(@"user info: %@", list);
            BeagleManager *BGM=[BeagleManager SharedInstance];
            BeagleUserClass *userObject=nil;
            if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
                userObject= BGM.beaglePlayer;
            }else{
                userObject=[[BeagleUserClass alloc]init];
            }
            
            
            id userName = [list objectForKey:@"username"];
            if (userName != nil && [userName class] != [NSNull class]) {
                
                userObject.userName=userName;
            }
            id fullName = [list objectForKey:@"name"];
            if (fullName != nil && [fullName class] != [NSNull class]) {
                
                
                NSArray *arr = [fullName componentsSeparatedByString:@" "];
                
                if([arr count]>=2){
                    userObject.first_name=[arr objectAtIndex:0];
                    userObject.last_name=[arr objectAtIndex:1];
                }
                else{
                    userObject.first_name=fullName;
                }
                
            }
            
            id userId = [list objectForKey:@"id"];
            if(userId != nil && [userId class] != [NSNull class]){
                userObject.fbuid=userId;
            }
            
            id first_name = [list objectForKey:@"first_name"];
            if(first_name != nil && [first_name class] != [NSNull class]){
                userObject.first_name=first_name;
            }
            
            id last_name = [list objectForKey:@"last_name"];
            if(last_name != nil && [last_name class] != [NSNull class]){
                userObject.last_name =last_name;
            }
            
            
            
            id location = [list objectForKey:@"location"];
            if(location != nil && [location class] != [NSNull class]){
                id country = [location objectForKey:@"name"];
                if(country != nil && [country class] != [NSNull class]){
                    userObject.location=country;
                }
            }
            
            
            userObject.profileImageUrl= [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", [list objectForKey:@"id"]];
            
            
            
            userObject.access_token = accessToken;
            
            id email = [list objectForKey:@"email"];
            if (email != nil && [email class] != [NSNull class]) {
                
                userObject.email=email;
            }
            userObject.permissionsGranted=YES;
            
            BGM.beaglePlayer=userObject;
            
            [self successfulFacebookLogin:userObject];

        } else {
            NSLog(@"error %@", error.description);
        }
    }];
}

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



-(void)closeAllFBSessions{
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}





- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest!=kServerCallUserRegisteration){
        _notificationServerManager.delegate = nil;
        [_notificationServerManager releaseServerManager];
        _notificationServerManager = nil;
    }
    if(serverRequest==kServerCallInAppNotification){
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSMutableDictionary *inappnotification=[response objectForKey:@"inappnotification"];
                if (inappnotification != nil && [inappnotification class] != [NSNull class]) {
                    
                    NSLog(@"badge Value=%ld",(long)[[inappnotification objectForKey:@"badge"]integerValue]);
                    
                    
                    NSOperationQueue *queue = [NSOperationQueue new];
                    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                        initWithTarget:self
                                                        selector:@selector(loadProfileImageData:)
                                                        object:inappnotification];
                    [queue addOperation:operation];
                    
                    [[BeagleManager SharedInstance]setBadgeCount:[[inappnotification objectForKey:@"badge"]integerValue]];
                    
                    
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[inappnotification objectForKey:@"badge"]integerValue]];
                    
                    
                }
                
            }
        }
        
    }
    else if(serverRequest==kServerCallInAppNotificationForPosts){
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSMutableDictionary *interestPost=[response objectForKey:@"interestPost"];
                if (interestPost != nil && [interestPost class] != [NSNull class]) {
                    
                    
                    NSOperationQueue *queue = [NSOperationQueue new];
                    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                        initWithTarget:self
                                                        selector:@selector(loadProfileImageDataForAPost:)
                                                        object:interestPost];
                    [queue addOperation:operation];
                    
                    
                    
                    
                }
            }
        }
        
    }else if (serverRequest==kServerCallRequestForOfflineNotification){
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSMutableDictionary *offlinePost=[response objectForKey:@"inappnotification"];
                
                
                
                
                id badge=[offlinePost objectForKey:@"badge"];
                if (badge != nil && [status class] != [NSNull class]){
                    [[BeagleManager SharedInstance]setBadgeCount:[badge integerValue]];
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badge integerValue]];
                    
                }
                if (offlinePost != nil && [offlinePost class] != [NSNull class]) {
                    
                    [offlinePost setObject:[NSNumber numberWithInteger:2] forKey:@"notifType"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
                    
                    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:nil userInfo:offlinePost]];
                    
                    
                }
            }
        }
        
    }else if (serverRequest==kServerCallInAppForOfflinePost){
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSMutableDictionary *interestPost=[response objectForKey:@"interestPost"];
                if (interestPost != nil && [interestPost class] != [NSNull class]) {
                    
                    
                    [interestPost setObject:[NSNumber numberWithInteger:2] forKey:@"notifType"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
                    
                    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kNotificationForInterestPost object:nil userInfo:interestPost]];
                    
                    
                    
                    
                }
            }
        }
        
    }
    
    else if(serverRequest==kServerCallRequestForSilentNotification){
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSMutableDictionary *inappnotification=[response objectForKey:@"inappnotification"];
                if (inappnotification != nil && [inappnotification class] != [NSNull class]) {
                    
                    NSOperationQueue *queue = [NSOperationQueue new];
                    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                        initWithTarget:self
                                                        selector:@selector(loadProfileImageDataForSilentPost:)
                                                        object:inappnotification];
                    [queue addOperation:operation];
                    
                    
                }
                
            }
        }
        
    }
    
    else if(serverRequest==kServerCallUserRegisteration){
        
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
        
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookSSOLoginAuthentication object:self userInfo:nil]];
        
    }
    
    
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    _notificationServerManager.delegate = nil;
    [_notificationServerManager releaseServerManager];
    _notificationServerManager = nil;
    
    if(serverRequest==kServerCallUserRegisteration|| serverRequest==kServerGetSignInInfo)
    {
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
        
        NSString *message = NSLocalizedString (@"Well this is embarrassing. Please try again in a bit.",
                                               @"NSURLConnection initialization method failed.");
        BeagleAlertWithMessage(message);

    }
    
    
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallUserRegisteration|| serverRequest==kServerGetSignInInfo)
    {
        _loginServerManager.delegate = nil;
        [_loginServerManager releaseServerManager];
        _loginServerManager = nil;
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookAuthenticationFailed object:self userInfo:nil]];

    }else{
        
        _notificationServerManager.delegate = nil;
        [_notificationServerManager releaseServerManager];
        _notificationServerManager = nil;
        
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [alert show];
}
@end
