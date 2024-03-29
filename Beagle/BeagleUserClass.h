//
//  BeagleUserClass.h
//  Beagle
//
//  Created by Kanav Gupta on 24/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BeagleActivityClass;
@class BeagleNotificationClass;
@interface BeagleUserClass : NSObject
@property(nonatomic,strong)NSString*first_name;
@property(nonatomic,strong)NSString*last_name;
@property(nonatomic,strong)NSString *userName;
@property(nonatomic,strong)NSString *fullName;
@property(nonatomic,strong)NSString *password;
@property(nonatomic,strong)NSString *profileImageUrl;
@property(nonatomic,strong)NSString *email;
@property(nonatomic,strong)NSNumber *fbuid;
@property(nonatomic,strong)NSString *access_token;
@property(nonatomic,strong)NSString *location;
@property(nonatomic,assign)BOOL fb_ticker;
@property(nonatomic,assign)NSInteger beagleUserId;
@property(nonatomic,assign)NSInteger badge;
@property(nonatomic,strong)NSData*profileData;
@property(nonatomic,assign)BOOL isInvited;
@property(nonatomic,assign)BOOL permissionsGranted;
@property(nonatomic,assign)CGFloat distance;
-(id) initWithDictionary:(NSDictionary *)dictionary;
-(id) initWithProfileDictionary:(NSDictionary*)dictionary;
-(id) initWithActivityObject:(BeagleActivityClass*)activity;
-(id)initWithNotificationObject:(BeagleNotificationClass*)notification;
@end
