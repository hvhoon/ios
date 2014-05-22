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
+ (UIImage*) getSubImageFrom: (UIImage*) img rect: (CGRect) rect;
+ (UIImage*)imageByCropping:(UIImage *)imageToCrop toRect:(CGRect)aperture withOrientation:(UIImageOrientation)orientation;
+ (UIImage*)circularScaleNCrop:(UIImage*)image rect:(CGRect) rect;
+(NSString*)activityTime:(NSString*)startDate endate:(NSString*)endDate;
+(UIImage*)imageCircularBySize:(UIImage*)image sqr:(CGFloat)sqr;
+(NSString *)calculateChatTimestamp:(NSString *)timeString;
+(UIColor*)returnBeagleColor:(NSInteger)colorID;
+(BOOL)hasBeenMoreThanSixtyMinutes;
+(BOOL)LastDistanceFromLocationExceeds_50M;
+(void) saveImage:(UIImage *)image withFileName:(NSInteger)imageName;
+(UIImage *) loadImage:(NSInteger )fileName;
@end
