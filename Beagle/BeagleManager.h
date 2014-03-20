//
//  BeagleManager.h
//  Beagle
//
//  Created by Kanav Gupta on 20/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BeagleUserClass;
@interface BeagleManager : NSObject{
   
    BeagleUserClass *beaglePlayer;
}
@property(nonatomic,strong)BeagleUserClass*beaglePlayer;
+ (id)SharedInstance;
-(void)userProfileDataUpdate;
-(void)getUserObjectInAutoSignInMode;
- (void)processFacebookProfilePictureData:(NSData *)newProfilePictureData;
@end
