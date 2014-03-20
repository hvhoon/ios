//
//  ServerManager.h
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kServerCallUserRegisteration,
    kServerCallCreateActivity
} ServerCallType;

@class ServerManager;
@class BeagleUserClass;
@class BeagleActivityClass;
@protocol ServerManagerDelegate <NSObject>

@optional

- (void)serverManagerDidFinishWithResponse:(NSDictionary *)response forRequest:(ServerCallType)serverRequest;
- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest;
- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest;

@end


@interface ServerManager : NSObject

@property (nonatomic,assign) id<ServerManagerDelegate> delegate;

-(void)releaseServerManager;
//*************************** API calls ***************************
-(void)registerPlayerOnBeagle:(BeagleUserClass*)data;
-(void)createActivityOnBeagle:(BeagleActivityClass*)data;
@end
