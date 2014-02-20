//
//  ServerManager.h
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kServerCallUserRegisteration
} ServerCallType;

@class ServerManager;
@protocol ServerManagerDelegate <NSObject>

@optional

- (void)serverManagerDidFinishWithResponse:(NSDictionary *)response forRequest:(ServerCallType)serverRequest;
- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest;
- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest;

@end


@interface ServerManager : NSObject

@property (nonatomic,assign) id<ServerManagerDelegate> delegate;

//*************************** API calls ***************************
-(void)registerUserWithPostRequest;
@end
