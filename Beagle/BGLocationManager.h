//
//  BGLocationManager.h
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface BGLocationManager : NSObject<CLLocationManagerDelegate>

@property(nonatomic, copy) void (^completionBlock)(CLLocation *, NSError *);

@property(nonatomic, assign) bool isRunning;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) CLLocation *locationBestEffort;
@property(nonatomic, strong) NSDate *locationInvalidateCacheTimeout;
@property(nonatomic, strong) NSDate *locationQuitTimeout;
@property (nonatomic,strong)NSString *weatherCondition;
+ (BGLocationManager *) sharedManager;
- (void) locationRequest: (void (^)(CLLocation *, NSError *)) completion;

@end
