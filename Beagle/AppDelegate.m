//
//  AppDelegate.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import <Instabug/Instabug.h>

@interface AppDelegate ()<ServerManagerDelegate>{
    ServerManager *notificationServerManager;
}
@property(nonatomic,strong)ServerManager *notificationServerManager;
@end

@implementation AppDelegate
@synthesize progressIndicator=_progressIndicator;
@synthesize listViewController;
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
    
    [Crashlytics startWithAPIKey:@"e8e7ac59367e936ecae821876cc411ec67427e47"];
    NSString *storyboardId = [[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"] ? @"initialNavBeagle" : @"loginNavScreen";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];
    [self registerForNotifications];
    
    // Instabug integration
    [Instabug KickOffWithToken:@"0fe55a803d01c2d223d89b450dcae674" CaptureSource:InstabugCaptureSourceUIKit FeedbackEvent:InstabugFeedbackEventShake IsTrackingLocation:YES];
    [Instabug setShowEmail:NO];
    [Instabug setShowStartAlert:NO];
    
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
    return YES;
}

-(void)registerForNotifications {
	UIRemoteNotificationType type = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:type];
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


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    
    
    if(_notificationServerManager!=nil){
        _notificationServerManager.delegate = nil;
        [_notificationServerManager releaseServerManager];
        _notificationServerManager = nil;
    }
    _notificationServerManager=[[ServerManager alloc]init];
    _notificationServerManager.delegate=self;
        if([[[userInfo valueForKey:@"params"] valueForKey:@"notification_type"]isEqualToString:@"17"]){
            [_notificationServerManager requestInAppNotificationForPosts:[[[userInfo valueForKey:@"params"] valueForKey:@"chat_id"]integerValue]];

            
        }else{
            [_notificationServerManager requestInAppNotification:[[[userInfo valueForKey:@"params"] valueForKey:@"notification_id"]integerValue]];
            
        }
    
}

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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AutoRefreshEvents" object:self userInfo:nil];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
-(void)showProgressIndicator:(NSInteger)type{
    
    _progressIndicator = [[MBProgressHUD alloc] initWithView:self.window];
    [self.window addSubview:_progressIndicator];
    _progressIndicator.labelFont=[UIFont systemFontOfSize:18.0f];
    _progressIndicator.yOffset = -60.0;
    switch (type) {
        case 1:
        {
            _progressIndicator.labelText=@"Registering...";
        }
            break;
            
            
        case 2:
        {
            _progressIndicator.labelText =@"Creating...";
            
        }
            
            break;
            
        case 3:
        {
            _progressIndicator.labelText =@"Loading...";
            
        }
            
            break;
    }
    [_progressIndicator show:YES];
    
}

-(void)hideProgressView{
    [_progressIndicator hide:YES];
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    _notificationServerManager.delegate = nil;
    [_notificationServerManager releaseServerManager];
    _notificationServerManager = nil;
    
    if(serverRequest==kServerCallInAppNotification){
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
             
                NSMutableDictionary *inappnotification=[response objectForKey:@"inappnotification"];
                NSLog(@"badge Value=%ld",[[inappnotification objectForKey:@"badge"]integerValue]);
                
                
                NSOperationQueue *queue = [NSOperationQueue new];
                NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                    initWithTarget:self
                                                    selector:@selector(loadProfileImageData:)
                                                    object:inappnotification];
                [queue addOperation:operation];

                [[BeagleManager SharedInstance]setBadgeCount:[[inappnotification objectForKey:@"badge"]integerValue]];
                


            }
        }
        
    }
    else{
        
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSMutableDictionary *interestPost=[response objectForKey:@"interestPost"];
                NSLog(@"badge Value=%ld",[[interestPost objectForKey:@"badge"]integerValue]);
                
                
                NSOperationQueue *queue = [NSOperationQueue new];
                NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                    initWithTarget:self
                                                    selector:@selector(loadProfileImageDataForAPost:)
                                                    object:interestPost];
                [queue addOperation:operation];
                
                [[BeagleManager SharedInstance]setBadgeCount:[[interestPost objectForKey:@"badge"]integerValue]];
                
                
                
            }
        }
        
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
        _notificationServerManager.delegate = nil;
        [_notificationServerManager releaseServerManager];
        _notificationServerManager = nil;
    
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
        _notificationServerManager.delegate = nil;
        [_notificationServerManager releaseServerManager];
        _notificationServerManager = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [alert show];
}
- (void)loadProfileImageData:(NSMutableDictionary*)notificationDictionary {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[notificationDictionary objectForKey:@"photo_url"]]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [notificationDictionary setObject:image forKey:@"profileImage"];
    [self performSelectorOnMainThread:@selector(sendAppNotification:) withObject:notificationDictionary waitUntilDone:NO];
}
-(void)sendAppNotification:(NSMutableDictionary*)appNotifDictionary{
    NSNotification* notification = [NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:nil userInfo:appNotifDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}
- (void)loadProfileImageDataForAPost:(NSMutableDictionary*)notificationDictionary {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[notificationDictionary objectForKey:@"player_photo_url"]]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [notificationDictionary setObject:image forKey:@"profileImage"];
    [self performSelectorOnMainThread:@selector(sendAppNotificationForPost:) withObject:notificationDictionary waitUntilDone:NO];
}
-(void)sendAppNotificationForPost:(NSMutableDictionary*)appNotifDictionary{
    NSNotification* notification = [NSNotification notificationWithName:kNotificationForInterestPost object:nil userInfo:appNotifDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
