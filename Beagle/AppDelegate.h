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

@interface AppDelegate : UIResponder <UIApplicationDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate,CLLocationManagerDelegate>{
}
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *_locationManager;
@property (nonatomic,strong)id listViewController;
@property (strong, nonatomic) UIWindow *window;
@property (copy) void (^backgroundSessionCompletionHandler)();
@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error;
- (void)startStandardUpdates;


@end
