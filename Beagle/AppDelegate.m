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
#import "HomeViewController.h"
@interface AppDelegate ()<ServerManagerDelegate>{
    ServerManager *notificationServerManager;
    NSInteger attempts;

}
@property(nonatomic,strong)ServerManager *notificationServerManager;
@end

@implementation AppDelegate
@synthesize listViewController;
@synthesize downloadTask;
@synthesize currentLocation;
@synthesize _locationManager = locationManager;
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
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    
    // Start AppSee analytics
    [Appsee start:@"d4f6b6daba7e4c3ca8b7ad040c2edaa3"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];
    [self registerForNotifications];
    
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
//    [self handlePush:launchOptions];
    return YES;
}

-(void)registerForNotifications {
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
    (
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeSound |
     UIRemoteNotificationTypeAlert)];
}
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
            
            NSNotification* notification = [NSNotification notificationWithName:kNotificationForInterestPost object:nil userInfo:dictionary];
            [[NSNotificationCenter defaultCenter] postNotification:notification];

            [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

            
            
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
            
            NSNotification* notification = [NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:nil userInfo:dictionary];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

        }
//            else
//            [_notificationServerManager requestInAppNotification:[[[userInfo valueForKey:@"p"] valueForKey:@"nid"]integerValue] notifType:2];
        
        // create a service which will return data and update the view badge count automatically
        
    
}


-(void)handleSilentNotifications:(NSDictionary*)userInfo{
        NSLog(@"userInfo=%@",userInfo);
        
    [_notificationServerManager requestInAppNotification:[[[userInfo valueForKey:@"p"] valueForKey:@"nid"]integerValue] notifType:3];
        
        
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
    
    NSLog(@"applicationWillEnterForeground");
    [[BeagleManager SharedInstance]setBadgeCount:[[UIApplication sharedApplication]applicationIconBadgeNumber]];

    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"AutoRefreshEvents" object:self userInfo:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHomeScreenAndNotificationStack object:self userInfo:nil];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateNotificationStack object:self userInfo:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdatePostsOnInterest object:self userInfo:nil];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
                    
                    NSNotification* notification = [NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:nil userInfo:offlinePost];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

                    
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

                    NSNotification* notification = [NSNotification notificationWithName:kNotificationForInterestPost object:nil userInfo:interestPost];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

                    
                    
                    
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
    NSNotification* notification = [NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:self userInfo:appNotifDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
}
- (void)loadProfileImageDataForAPost:(NSMutableDictionary*)notificationDictionary {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[notificationDictionary objectForKey:@"player_photo_url"]]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [notificationDictionary setObject:image forKey:@"profileImage"];
    [notificationDictionary setObject:[NSNumber numberWithInteger:1] forKey:@"notifType"];
    [self performSelectorOnMainThread:@selector(sendAppNotificationForPost:) withObject:notificationDictionary waitUntilDone:NO];
}
-(void)sendAppNotificationForPost:(NSMutableDictionary*)appNotifDictionary{
    NSNotification* notification = [NSNotification notificationWithName:kNotificationForInterestPost object:self userInfo:appNotifDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
    

}
-(void)sendSilentNotification:(NSMutableDictionary*)appNotifDictionary{
    NSNotification* notification = [NSNotification notificationWithName:kRemoteNotificationReceivedNotification object:self userInfo:appNotifDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}


- (NSURLSession *)backgroundURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"io.objc.backgroundTransferExample";
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}


-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    

    // Pass on
    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
    
}

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
         completionHandler(UIBackgroundFetchResultNewData);


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
    else{
        [self handleOfflineNotifications:userInfo];
    }
    }
    
}


- (void)URLSession:(NSURLSession *)session
               downloadTask:(NSURLSessionDownloadTask *)downloadTask
  didFinishDownloadingToURL:(NSURL *)location
{
    
    // Notify your UI
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error == nil) {
        NSLog(@"Task: %@ completed successfully", task);
    } else {
        NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
    }
    
    self.downloadTask = nil;
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = self.backgroundSessionCompletionHandler;
        self.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    
    NSLog(@"All tasks are finished");
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler {
    self.backgroundSessionCompletionHandler = completionHandler;
    
    //add notification
    [self presentNotification];
}

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

- (void)startStandardUpdates {
    
	if (nil == locationManager) {
		locationManager = [[CLLocationManager alloc] init];
	}
    
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
	// Set a movement threshold for new events.
	locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
    
	[locationManager startUpdatingLocation];
    
	CLLocation *currentLoc = locationManager.location;
	if (currentLoc) {
		self.currentLocation = currentLoc;
	}
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	switch (status) {
		case kCLAuthorizationStatusAuthorized:
			NSLog(@"kCLAuthorizationStatusAuthorized");
			[locationManager startUpdatingLocation];
			break;
		case kCLAuthorizationStatusDenied:
			NSLog(@"kCLAuthorizationStatusDenied");
        {
            /*
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!!!" message:@"Beagle can’t access your current location.\nTo view interests nearby, please turn on location services in  Settings under Location Services." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
             [alertView show];
             */// Disable the post button.
        }
			break;
		case kCLAuthorizationStatusNotDetermined:
			NSLog(@"kCLAuthorizationStatusNotDetermined");
			break;
		case kCLAuthorizationStatusRestricted:
			NSLog(@"kCLAuthorizationStatusRestricted");
			break;
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
@end
