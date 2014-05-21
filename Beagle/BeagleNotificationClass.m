//
//  BeagleNotificationClass.m
//  Beagle
//
//  Created by Kanav Gupta on 20/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BeagleNotificationClass.h"

@implementation BeagleNotificationClass
@synthesize notificationString,type,profileImage,date,count,notificationId,userId;
@synthesize activityId,expirationDate,photoUrl,latitude,longitude,notificationType,isRead;
@synthesize rowHeight,timeOfNotification,referredId,backgroundTap,playerId,activityWhat;
-(id) initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        
        NSNumber * n = [dictionary objectForKey:@"id"];
        self.notificationId= [n intValue];
        self.userId = [dictionary objectForKey:@"user_id"];
        self.notificationType = [[dictionary objectForKey:@"notification_type"]integerValue];
        self.notificationString = [dictionary objectForKey:@"notification"];
        self.latitude = [dictionary objectForKey:@"lat"];
        self.longitude = [dictionary objectForKey:@"lng"];
        self.timeOfNotification=[dictionary objectForKey:@"created_at"];
        NSNumber * received = [dictionary objectForKey:@"is_received"];
        self.isRead= [received boolValue];
        NSNumber * aId = [dictionary objectForKey:@"activity_id"];
        if(aId !=nil && [aId class]!=[NSNull class])
            self.activityId= [aId intValue];
        NSNumber *referredTo = [dictionary objectForKey:@"reffered_to"];
        if(referredTo !=nil && [referredTo class]!=[NSNull class])
            self.referredId= [referredTo intValue];
        self.photoUrl=[dictionary objectForKey:@"photo_url"];
        self.activityWhat=[NSString stringWithFormat:@"\"%@\"",[dictionary objectForKey:@"what"]];
    }
    return self;
}
@end
