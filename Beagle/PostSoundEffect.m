//
//  PostSoundEffect.m
//  Beagle
//
//  Created by Kanav Gupta on 05/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "PostSoundEffect.h"


@interface PostSoundEffect ()

+ (void)playSoundWithName:(NSString *)name type:(NSString *)type;

@end

@implementation PostSoundEffect
+ (void)playSoundWithName:(NSString *)name type:(NSString *)type
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSURL *url = [NSURL fileURLWithPath:path];
        SystemSoundID sound;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &sound);
        AudioServicesPlaySystemSound(sound);
    }
    else {
        NSLog(@"**** Sound Error: file not found: %@", path);
    }
}

+ (void)playMessageReceivedSound
{
    [PostSoundEffect playSoundWithName:@"messageReceived" type:@"aiff"];
}

+ (void)playMessageSentSound
{
    [PostSoundEffect playSoundWithName:@"messageSent" type:@"aiff"];
}

@end
