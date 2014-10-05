//
//  BeagleUtilities.h
//  Beagle
//
//  Created by Kanav Gupta on 04/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BeagleNotificationClass;
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
+(UIColor*)returnAverageColor:(UIImage*)image;
+(UIColor*)getDominantColor:(UIImage*)image;
+ (UIColor *)lighterColorForColor:(UIColor *)c;
+ (UIColor *)darkerColorForColor:(UIColor *)c;
+(BOOL)hasBeenMoreThanSixtyMinutes;
+(BOOL)LastDistanceFromLocationExceeds_50M;
+(void) saveImage:(UIImage *)image withFileName:(NSInteger)imageName;
+(UIImage *) loadImage:(NSInteger )fileName;
+(BeagleNotificationClass*)getNotificationObject:(NSNotification*)object;
+(BeagleNotificationClass*)getNotificationForInterestPost:(NSNotification*)object;
+(void)updateBadgeInfoOnTheServer:(NSInteger)notificationId;
+(UIImage*)colorImage:(UIImage*)img withColor:(UIColor *)color;
+(UIColor*)returnShadeOfColor:(UIColor*)inputColor withShade:(CGFloat)inputShade;
+(UIColor*)returnLightColor:(UIColor*)inputColor withWhiteness:(CGFloat)white;
+(BOOL)checkIfTheTextIsBlank:(NSString*)text;
+(BOOL)checkIfTheDateHasBeenSetUsingAPicker:(NSString*)startDate endDate:(NSString*)endDate;
+ (CGFloat)heightForAttributedStringWithEmojis:(NSAttributedString *)attributedString forWidth:(CGFloat)width;
@end
