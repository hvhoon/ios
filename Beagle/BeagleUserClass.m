//
//  BeagleUserClass.m
//  Beagle
//
//  Created by Kanav Gupta on 24/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BeagleUserClass.h"

@implementation BeagleUserClass
@synthesize userName,fullName,email,password,profileImageUrl,first_name,last_name,fbuid,access_token,location,fb_ticker,beagleUserId,profileData,badge;

-(id) initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.beagleUserId = [[dictionary valueForKey:@"id"]integerValue];
        self.fbuid = [[dictionary valueForKey:@"fbuid"]integerValue];
        self.first_name = [dictionary valueForKey:@"first_name"];
        self.last_name = [dictionary valueForKey:@"last_name"];
        self.profileImageUrl = [dictionary valueForKey:@"owner_photo_url"];
    }
    return self;
}

-(id) initWithProfileDictionary:(NSDictionary*)dictionary{
    self = [super init];
    if (self)
    {
        self.beagleUserId = [[dictionary valueForKey:@"id"]integerValue];
        self.fbuid = [[dictionary valueForKey:@"fbuid"]integerValue];
        self.fullName = [dictionary valueForKey:@"name"];
        self.location=[dictionary valueForKey:@"location"];
        self.profileImageUrl = [dictionary valueForKey:@"photo"];
    }
    return self;
    
}
@end
