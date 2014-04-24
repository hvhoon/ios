//
//  BeagleActivityClass.m
//  Beagle
//
//  Created by Kanav Gupta on 20/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BeagleActivityClass.h"

@implementation BeagleActivityClass
@synthesize activityDesc,startActivityDate,endActivityDate,visibility,locationName,city,state,activityId,latitude,longitude,timeFilter,visibiltyFilter,ownerid,activityType,organizerName,photoUrl,dosRelation,participantsCount,profilePhotoImage,dos2Count,isParticipant,postCount;

-(id) initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.activityId = [[dictionary valueForKey:@"id"]integerValue];
        self.activityType = [[dictionary valueForKey:@"atype"]integerValue];
        self.startActivityDate = [dictionary valueForKey:@"start_when"];
        self.latitude = [[dictionary valueForKey:@"where_lat"]floatValue];
        self.longitude = [[dictionary valueForKey:@"where_lng"]floatValue];
        self.city = [dictionary valueForKey:@"where_city"];
        self.state = [dictionary valueForKey:@"where_state"];
        self.activityDesc = [dictionary valueForKey:@"what"];
        self.visibility = [dictionary valueForKey:@"access"];
        self.ownerid = [[dictionary valueForKey:@"ownnerid"]integerValue];
        self.endActivityDate = [dictionary valueForKey:@"stop_when"];
        self.organizerName = [dictionary valueForKey:@"organizer"];
        self.photoUrl = [dictionary valueForKey:@"owner_photo_url"];
        self.dosRelation = [[dictionary valueForKey:@"dosRelation"]integerValue];
        self.dos2Count = [[dictionary valueForKey:@"dos2Count"]integerValue];
        self.participantsCount = [[dictionary valueForKey:@"total_count"]integerValue];
        self.locationName=[NSString stringWithFormat:@"%@, %@",self.city,self.state];
        self.isParticipant=[[dictionary valueForKey:@"isParticipant"]boolValue];
        self.postCount = [[dictionary valueForKey:@"postCount"]integerValue];
    }
    return self;
}
@end

