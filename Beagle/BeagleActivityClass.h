//
//  BeagleActivityClass.h
//  Beagle
//
//  Created by Kanav Gupta on 20/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BeagleActivityClass : NSObject
@property(nonatomic,strong)NSString*activityDesc;
@property(nonatomic,strong)NSString*startActivityDate;
@property(nonatomic,strong)NSString *endActivityDate;
@property(nonatomic,strong)NSString *visibility;
@property(nonatomic,strong)NSString *locationName;
@property(nonatomic,strong)NSString *city;
@property(nonatomic,strong)NSString *state;
@property(nonatomic,assign)NSInteger activityId;
@property(nonatomic,assign)CGFloat latitude;
@property(nonatomic,assign)CGFloat longitude;
@property(nonatomic,assign)NSInteger ownerid;
@property(nonatomic,assign)NSInteger activityType;
@property(nonatomic,strong)NSString*organizerName;
@property(nonatomic,strong)NSString*photoUrl;
@property(nonatomic,assign)NSInteger dosRelation;
@property(nonatomic,assign)NSInteger participantsCount;
@property(nonatomic,strong)UIImage*profilePhotoImage;
@property(nonatomic,assign)NSInteger dos1count;
@property(nonatomic,assign) BOOL isParticipant;
@property(nonatomic,assign)NSInteger postCount;
@property(nonatomic,strong)NSString*requestString;
@property(nonatomic,strong)NSArray*participantsArray;
-(id) initWithDictionary:(NSDictionary *)dictionary;
@end
