//
//  InterestChatClass.m
//  Beagle
//
//  Created by Kanav Gupta on 23/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "InterestChatClass.h"

@implementation InterestChatClass
@synthesize ownnerid,player_id,player_name,player_photo_url,playerImage,text,timestamp,chat_id;

-(id) initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.chat_id = [[dictionary valueForKey:@"chat_id"]integerValue];
        self.ownnerid = [[dictionary valueForKey:@"ownnerid"]integerValue];
        self.player_id = [[dictionary valueForKey:@"player_id"]integerValue];
        self.player_name = [dictionary valueForKey:@"player_name"];
        self.player_photo_url = [dictionary valueForKey:@"player_photo_url"];
        self.text = [dictionary valueForKey:@"text"];
        self.timestamp = [dictionary valueForKey:@"timestamp"];
    }
    return self;
}
@end
