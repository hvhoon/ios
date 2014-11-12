//
//  PostSoundEffect.h
//  Beagle
//
//  Created by Kanav Gupta on 05/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface PostSoundEffect : NSObject
+ (void)playMessageReceivedSound;
+ (void)playMessageSentSound;

@end
