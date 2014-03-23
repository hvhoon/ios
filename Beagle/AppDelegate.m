//
//  AppDelegate.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
@implementation AppDelegate
@synthesize progressIndicator=_progressIndicator;
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [Crashlytics startWithAPIKey:@"e8e7ac59367e936ecae821876cc411ec67427e47"];
    NSString *storyboardId = [[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"] ? @"loginNavScreen" : @"loginNavScreen";
    if([storyboardId isEqualToString:@"initialBeagle"]){
        [[BeagleManager SharedInstance]getUserObjectInAutoSignInMode];
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
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


@end
