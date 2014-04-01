//
//  BeagleManager.m
//  Beagle
//
//  Created by Kanav Gupta on 20/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


#import "BeagleManager.h"
#import "BeagleUserClass.h"
@implementation BeagleManager
@synthesize beaglePlayer,currentLocation,placemark,weatherCondition;
+ (id) SharedInstance {
	static id sharedManager = nil;
	
    if (sharedManager == nil) {
        sharedManager = [[self alloc] init];
    }
	
    return sharedManager;
}
-(id)init{
    
    if(self=[super init]){
        
    }
    return self;
}

-(void)userProfileDataUpdate{
    

        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"User.plist"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"User" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
    
        
        NSMutableDictionary *array = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        
        if (nil == array) {
            array = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
    
        //here add elements to data file and write data to file
    
        if(self.beaglePlayer.access_token != nil && [self.beaglePlayer.access_token class] != [NSNull class])
        [array setObject:self.beaglePlayer.access_token forKey:@"access_token"];
    
    
    

        [array setObject:[NSNumber numberWithBool:self.beaglePlayer.fb_ticker] forKey:@"facebook_ticker"];
    if(self.beaglePlayer.email != nil && [self.beaglePlayer.email class] != [NSNull class])
          [array setObject:self.beaglePlayer.email forKey:@"email"];
    [array setObject:[NSNumber numberWithInteger:self.beaglePlayer.fbuid ]forKey:@"fbuid"];
    
    if(self.beaglePlayer.first_name != nil && [self.beaglePlayer.first_name class] != [NSNull class])
        [array setObject:self.beaglePlayer.first_name forKey:@"first_name"];
    
[array setObject:[NSNumber numberWithInteger:self.beaglePlayer.beagleUserId] forKey:@"id"];
    if(self.beaglePlayer.last_name != nil && [self.beaglePlayer.last_name class] != [NSNull class])
     [array setObject:self.beaglePlayer.last_name forKey:@"last_name"];
    if(self.beaglePlayer.profileImageUrl != nil && [self.beaglePlayer.profileImageUrl class] != [NSNull class])
    [array setObject:self.beaglePlayer.profileImageUrl forKey:@"photo_url"];
    
    if(self.beaglePlayer.profileData != nil && [self.beaglePlayer.profileData class] != [NSNull class])
        [array setObject:self.beaglePlayer.profileData forKey:@"photoData"];


    
   [array writeToFile:path atomically:YES];
        
        
        
        
        

}
-(void)getUserObjectInAutoSignInMode{
    
#if 1
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"User.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: path])
    {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"User" ofType:@"plist"];
        
        [fileManager copyItemAtPath:bundle toPath: path error:&error];
    }
    
    
    NSDictionary *array = [NSDictionary dictionaryWithContentsOfFile:path];
    
    
    BeagleUserClass *player=[[BeagleUserClass alloc]init];
    player.access_token=[array valueForKey:@"access_token"];
    player.email=[array valueForKey:@"email"];
    player.fbuid=[[array valueForKey:@"fbuid"]integerValue];
    player.first_name=[array valueForKey:@"first_name"];
    player.last_name=[array valueForKey:@"last_name"];
    player.beagleUserId=[[array valueForKey:@"id"]integerValue];
    player.profileImageUrl=[array valueForKey:@"photo_url"];
    self.beaglePlayer=player;
#endif
}

- (void)processFacebookProfilePictureData:(NSData *)newProfilePictureData {
    self.beaglePlayer.profileData=newProfilePictureData;
    [self userProfileDataUpdate];
}
@end
