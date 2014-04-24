//
//  InterestChatClass.h
//  Beagle
//
//  Created by Kanav Gupta on 23/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InterestChatClass : NSObject
@property(nonatomic,assign)NSInteger ownnerid;
@property(nonatomic,assign)NSInteger player_id;
@property(nonatomic,strong)NSString *player_name;
@property(nonatomic,strong)NSString *player_photo_url;
@property(nonatomic,strong)NSDate *timestamp;
@property(nonatomic,strong)UIImage *playerImage;
@property(nonatomic,strong)NSString *text;
-(id) initWithDictionary:(NSDictionary *)dictionary;
@end
