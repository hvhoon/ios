//
//  BeagleUtilities.h
//  Beagle
//
//  Created by Kanav Gupta on 04/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BeagleUtilities : NSObject
+ (int) getRandomIntBetweenLow:(int) low andHigh:(int) high;
+(UIImage*) compressImage:(UIImage *)image size:(CGSize)size;
+(UIImage*) autoCrop:(UIImage*)image;

@end
