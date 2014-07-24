//
//  BeagleUtilities.m
//  Beagle
//
//  Created by Kanav Gupta on 04/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BeagleUtilities.h"
#import "JSON.h"
@implementation BeagleUtilities
+ (int) getRandomIntBetweenLow:(int) low andHigh:(int) high {
	return ((arc4random() % (high - low + 1)) + low);
}
// Function to auto-crop the image if user does not
+(UIImage*) autoCrop:(UIImage*)image{
    
    CGSize dimensions = {0,0};
    float x=0.0,y=0.0;
    
    // Check to see if the image layout is landscape or portrait
    if(image.size.width > image.size.height)
    {
        // if landscape
        x = (image.size.width - image.size.height)/2;
        dimensions.width = image.size.height;
        dimensions.height = image.size.height;
        
    }
    else
    {
        // if portrait use the top portion of the image
        dimensions.height = image.size.width;
        dimensions.width = image.size.width;
        
    }
    
    // Create the mask
    CGRect imageRect = CGRectMake(x,y,dimensions.width,dimensions.height);
    
    // Create the image based on the mask created above
    CGImageRef  imageRef = CGImageCreateWithImageInRect([image CGImage], imageRect);
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
	return image;
}

// Function to compress a large image
+(UIImage*) compressImage:(UIImage *)image size:(CGSize)size{
    
    UIGraphicsBeginImageContext(size);
    CGRect imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
    [image drawInRect:imageRect];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIColor*)returnBeagleColor:(NSInteger)colorID {
    
    switch (colorID) {
        
        // This is the brilliant blue highlights
        case 1:
            return [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
        
        // This is the light gray screen which is the back of most screens
        case 2:
            return [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
        
        // This is the darker gray back of the settings screen and some text
        case 3:
            return [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
        
        // This is the dark gray used for text
        case 4:
            return [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0];
        
        // This is the background for the comments section
        case 5:
            return [UIColor colorWithRed:230.0/255.0 green:240.0/255.0 blue:255.0/255.0 alpha:1.0];
        case 6:
            return [UIColor colorWithRed:178.0/255.0 green:178.0/255.0 blue:178.0/255.0 alpha:1.0];
        case 7:
            return [UIColor colorWithRed:88.0/255.0 green:89.0/255.0 blue:91.0/255.0 alpha:1.0];
        case 8:
            return [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
        // Translucent blurred overlay color
        case 9:
            return [UIColor colorWithRed:112.0/255.0 green:112.0/255.0 blue:112.0/255.0 alpha:0.75];
            
        case 10:
            return [UIColor colorWithRed:100.0/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
        // Filter panel background
        case 11:
            return [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.35];
            
        case 12:
            return [UIColor colorWithRed:175.0/255.0 green:175.0/255.0 blue:175.0/255.0 alpha:1.0];
        // Pastel Orange used in the logo
        case 13:
            return [UIColor colorWithRed:255.0/255.0 green:149.0/255.0 blue:0.0/255.0 alpha:1.0];
        default:
            return [UIColor whiteColor];
    }
    
}

#pragma mark - Image processing functions
+ (UIImage*) getSubImageFrom: (UIImage*) img rect: (CGRect) rect {
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // translated rectangle for drawing sub image
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, img.size.width, img.size.height);
    
    // clip to the bounds of the image context
    // not strictly necessary as it will get clipped anyway?
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    
    // draw image
    [img drawInRect:drawRect];
    
    // grab image
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return subImage;
}
+ (UIImage*)imageByCropping:(UIImage *)imageToCrop toRect:(CGRect)aperture withOrientation:(UIImageOrientation)orientation {
    
    // convert y coordinate to origin bottom-left
    CGFloat orgY = aperture.origin.y + aperture.size.height - imageToCrop.size.height,
    orgX = -aperture.origin.x,
    scaleX = 1.0,
    scaleY = 1.0,
    rot = 0.0;
    CGSize size;
    
    switch (orientation) {
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            size = CGSizeMake(aperture.size.height, aperture.size.width);
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            size = aperture.size;
            break;
        default:
            assert(NO);
            return nil;
    }
    
    
    switch (orientation) {
        case UIImageOrientationRight:
            rot = 1.0 * M_PI / 2.0;
            orgY -= aperture.size.height;
            break;
        case UIImageOrientationRightMirrored:
            rot = 1.0 * M_PI / 2.0;
            scaleY = -1.0;
            break;
        case UIImageOrientationDown:
            scaleX = scaleY = -1.0;
            orgX -= aperture.size.width;
            orgY -= aperture.size.height;
            break;
        case UIImageOrientationDownMirrored:
            orgY -= aperture.size.height;
            scaleY = -1.0;
            break;
        case UIImageOrientationLeft:
            rot = 3.0 * M_PI / 2.0;
            orgX -= aperture.size.height;
            break;
        case UIImageOrientationLeftMirrored:
            rot = 3.0 * M_PI / 2.0;
            orgY -= aperture.size.height;
            orgX -= aperture.size.width;
            scaleY = -1.0;
            break;
        case UIImageOrientationUp:
            break;
        case UIImageOrientationUpMirrored:
            orgX -= aperture.size.width;
            scaleX = -1.0;
            break;
    }
    
    // set the draw rect to pan the image to the right spot
    CGRect drawRect = CGRectMake(orgX, orgY, imageToCrop.size.width, imageToCrop.size.height);
    
    // create a context for the new image
    UIGraphicsBeginImageContextWithOptions(size, NO, imageToCrop.scale);
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    // apply rotation and scaling
    CGContextRotateCTM(gc, rot);
    CGContextScaleCTM(gc, scaleX, scaleY);
    
    // draw the image to our clipped context using the offset rect
    CGContextDrawImage(gc, drawRect, imageToCrop.CGImage);
    
    // pull the image from our cropped context
    UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    // Note: this is autoreleased
    return cropped;
}

+ (UIImage*)circularScaleNCrop:(UIImage*)image rect:(CGRect) rect{
    // This function returns a newImage, based on image, that has been:
    // - scaled to fit in (CGRect) rect
    // - and cropped within a circle of radius: rectWidth/2
    
    //Create the bitmap graphics context
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Get the width and heights
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat rectWidth = rect.size.width;
    CGFloat rectHeight = rect.size.height;
    
    //Calculate the scale factor
    CGFloat scaleFactorX = rectWidth/imageWidth;
    CGFloat scaleFactorY = rectHeight/imageHeight;
    
    //Calculate the centre of the circle
    CGFloat imageCentreX = rectWidth/2;
    CGFloat imageCentreY = rectHeight/2;
    
    // Create and CLIP to a CIRCULAR Path
    // (This could be replaced with any closed path if you want a different shaped clip)
    CGFloat radius = rectWidth/2;
    CGContextBeginPath (context);
    CGContextAddArc (context, imageCentreX, imageCentreY, radius, 0, 2*M_PI, 0);
    CGContextClosePath (context);
    CGContextClip (context);
    
    //Set the SCALE factor for the graphics context
    //All future draw calls will be scaled by this factor
    CGContextScaleCTM (context, scaleFactorX, scaleFactorY);
    
    // Draw the IMAGE
    CGRect myRect = CGRectMake(0, 0, imageWidth, imageHeight);
    [image drawInRect:myRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

// Determine the dominant color in an image
+(UIColor*)getDominantColor:(UIImage*)image {
    struct pixel {
        unsigned char r, g, b, a;
    };
    
    NSUInteger red = 0;
    NSUInteger green = 0;
    NSUInteger blue = 0;
    
    float alpha = 1.0f;
    
    // Allocate a buffer big enough to hold all the pixels
    
    struct pixel* pixels = (struct pixel*) calloc(1, image.size.width * image.size.height * sizeof(struct pixel));
    if (pixels != nil)
    {
        
        CGContextRef context = CGBitmapContextCreate(
                                                     (void*) pixels,
                                                     image.size.width,
                                                     image.size.height,
                                                     8,
                                                     image.size.width * 4,
                                                     CGImageGetColorSpace(image.CGImage),
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        
        if (context != NULL)
        {
            // Draw the image in the bitmap
            
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), image.CGImage);
            
            // Now that we have the image drawn in our own buffer, we can loop over the pixels to
            // process it. This simple case simply counts all pixels that have a pure red component.
            
            // There are probably more efficient and interesting ways to do this. But the important
            // part is that the pixels buffer can be read directly.
            
            NSUInteger numberOfPixels = image.size.width * image.size.height;
            for (int i=0; i<numberOfPixels; i++) {
                red += pixels[i].r;
                green += pixels[i].g;
                blue += pixels[i].b;
            }
            
            
            red /= numberOfPixels;
            green /= numberOfPixels;
            blue/= numberOfPixels;
            
            
            CGContextRelease(context);
        }
        
        free(pixels);
    }
    NSLog(@"Dominant color = R: %i, G: %i, B: %i", (int)red, (int)green, (int)blue);
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}

+(UIColor*)returnShadeOfColor:(UIColor*)inputColor withShade:(CGFloat)inputShade {
    CGFloat hue, saturation, brightness, alpha;
    
    // Getting these values
    if([inputColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha])
        return [UIColor colorWithHue:hue saturation:saturation brightness:inputShade alpha:alpha];
    
    return [self returnBeagleColor:5];
}

// Crazy function for mixing white into a color to make it light!
+(UIColor*)returnLightColor:(UIColor*)inputColor withWhiteness:(CGFloat)white {
    CGFloat r, g, b, a;
    CGFloat multiplier = 1 - white;
    
    // Getting these values
    if([inputColor getRed:&r green:&g blue:&b alpha:&a]) {
        r = r*255.0;
        g = g*255.0;
        b = b*255.0;

        CGFloat newR = (255.0f - (int)(255.0f - r)*multiplier);
        CGFloat newG = (255.0f - (int)(255.0f - g)*multiplier);
        CGFloat newB = (255.0f - (int)(255.0f - b)*multiplier);
        
        NSLog(@"Light Version = R: %i, G: %i, B: %i", (int)newR, (int)newG, (int)newB);
        return [UIColor colorWithRed:newR/255.0 green:newG/255.0 blue:newB/255.0 alpha:1.0];
    }
    return [self returnBeagleColor:8];
}

// Determine the average color in an image!
+(UIColor*)returnAverageColor:(UIImage*)image; {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), image.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if(rgba[3] > 0) {
        CGFloat alpha = 1.0;
        CGFloat multiplier = alpha/255.0;
        return [UIColor colorWithRed:((CGFloat)rgba[0])*multiplier
                               green:((CGFloat)rgba[1])*multiplier
                                blue:((CGFloat)rgba[2])*multiplier
                               alpha:alpha];
    }
    else {
        return [UIColor colorWithRed:((CGFloat)rgba[0])/255.0
                               green:((CGFloat)rgba[1])/255.0
                                blue:((CGFloat)rgba[2])/255.0
                               alpha:((CGFloat)rgba[3])/255.0];
    }
}
// Determine the lighterColorForColor !
+ (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}
// Determine the darkerColorForColor !
+ (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}

+(UIImage*)imageCircularBySize:(UIImage*)image sqr:(CGFloat)sqr{
    
    if(image.size.height != image.size.width)
        image = [BeagleUtilities autoCrop:image];
    
    
    if(image.size.height > sqr || image.size.width > sqr)
        image = [BeagleUtilities compressImage:image size:CGSizeMake(sqr,sqr)];
    
    UIGraphicsBeginImageContext(image.size);
    {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGAffineTransform trnsfrm = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0));
        trnsfrm = CGAffineTransformConcat(trnsfrm, CGAffineTransformMakeTranslation(0.0, image.size.height));
        CGContextConcatCTM(ctx, trnsfrm);
        CGContextBeginPath(ctx);
        CGContextAddEllipseInRect(ctx, CGRectMake(0.0, 0.0, image.size.width, image.size.height));
        CGContextClip(ctx);
        CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, image.size.width, image.size.height), image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
    
}

+ (UIImage *)colorImage:(UIImage *)img withColor:(UIColor *)color {
    
    // begin a new image context, to draw our colored image onto with the right scale
    UIGraphicsBeginImageContextWithOptions(img.size, NO, [UIScreen mainScreen].scale);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}


#pragma mark -

+(NSString*)activityTime:(NSString*)startDate endate:(NSString*)endDate{
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
    
    //Set the first day of the week
    NSInteger dayofweek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]] weekday];// this will give you current day of week
    [components setDay:([components day] - ((dayofweek) - 2))];// for beginning of the week.
    NSDate *beginningOfWeek = [gregorian dateFromComponents:components];
    
    //Set the start of the weekend
    NSDate *startOfWeekend = [beginningOfWeek dateByAddingTimeInterval:60*60*24*5];
    
    //Set the end of the weekend
    [components setDay:([components day] + 6)]; // Advancing by 6 days
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    NSDate *endOfWeekend = [gregorian dateFromComponents:components];

    //Set start/end dates for next weekend
    NSDate *startOfNextWeekend = [startOfWeekend dateByAddingTimeInterval:60*60*24*7];
    NSDate *endOfNextWeekend = [endOfWeekend dateByAddingTimeInterval:60*60*24*7];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setAMSymbol:@"am"];
    
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    NSDate *startActivityDate = [dateFormatter dateFromString:startDate];
    NSDate *endActivityDate = [dateFormatter dateFromString:endDate];
    
    NSTimeInterval Interval=[endActivityDate timeIntervalSinceDate:[NSDate date]];
    
    // When pick a date option is selected
    
    if([startActivityDate timeIntervalSinceDate:endActivityDate]==0.0){
        NSCalendar* calendar = [NSCalendar currentCalendar];
        
        NSString *eventDateString = [dateFormatter stringFromDate:startActivityDate];
        NSDate *eventDate = [dateFormatter dateFromString:eventDateString];
        NSString *todayDate = [dateFormatter stringFromDate:[NSDate date]];
        NSDate *currentDate=[dateFormatter dateFromString:todayDate];
        
        
        NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
        NSInteger destinationGMTOffset1 = [destinationTimeZone secondsFromGMTForDate:eventDate];
        NSInteger destinationGMTOffset2 = [destinationTimeZone secondsFromGMTForDate:currentDate];
        
        NSTimeInterval interval2 = destinationGMTOffset1;
        NSTimeInterval interval3 = destinationGMTOffset2;
        
        NSDate* destinationDate =[[NSDate alloc] initWithTimeInterval:interval2 sinceDate:eventDate];
        NSDate* currentDateTime =[[NSDate alloc] initWithTimeInterval:interval3 sinceDate:currentDate];
        
        NSInteger differenceInDays =
        [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:destinationDate]-
        [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:currentDateTime];

        
        
        if(differenceInDays==0){
            NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
            localDateFormatter.dateFormat=@"h:mma";
            [localDateFormatter setPMSymbol:@"pm"];
            [localDateFormatter setAMSymbol:@"am"];
            
            return [NSString stringWithFormat:@"Today, %@",[localDateFormatter stringFromDate:startActivityDate]];
            
            //user has picked today
        }else if(differenceInDays==1){
            NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
            localDateFormatter.dateFormat=@"h:mma";
            [localDateFormatter setPMSymbol:@"pm"];
            [localDateFormatter setAMSymbol:@"am"];
            
            return [NSString stringWithFormat:@"Tomorrow, %@",[localDateFormatter stringFromDate:startActivityDate]];
        }
        else{
            NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
            
            localDateFormatter.dateFormat=@"EEE, MMM d, h:mma";
            [localDateFormatter setPMSymbol:@"pm"];
            [localDateFormatter setAMSymbol:@"am"];
            [localDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
            return [localDateFormatter stringFromDate:startActivityDate];
            
        }


    }
    
    // Is it today?
    if([[NSDate date] timeIntervalSinceDate:startActivityDate]>0 && Interval>0 && Interval<=86400.00)
        return @"Later Today";
    // Is it tomorrow?
    else if([[NSDate date] timeIntervalSinceDate:startActivityDate]<0 && Interval>=86400.00 && Interval<=172800.00)
        return @"Tomorrow";
    // Is it this week?
    else if([endOfWeekend timeIntervalSinceDate:endActivityDate]>=0) {
        // On the weekend?
        if ([startActivityDate timeIntervalSinceDate:startOfWeekend]>=0)
            return @"This Weekend";
        return @"This Week";
    }
    // Is this next week?
    else if([endOfNextWeekend timeIntervalSinceDate:endActivityDate]>=0) {
        // Over next weekend?
        if ([startActivityDate timeIntervalSinceDate:startOfNextWeekend]>=0)
            return @"Next Weekend";
        return @"Next Week";
    }
    else if ([[NSDate date] timeIntervalSinceDate:startActivityDate]>=0 && [endActivityDate timeIntervalSinceDate:endOfNextWeekend]>0)
        return @"This Month";
    
    dateFormatter.dateFormat=@"EEE, MMM d";
    return [dateFormatter stringFromDate:endActivityDate];


}

+(NSString *)calculateChatTimestamp:(NSString *)timeString{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setAMSymbol:@"am"];
    
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    NSDate *lastDate = [dateFormatter dateFromString:timeString];
    
    NSDate *currentDate=[NSDate date];
    
    NSTimeInterval interval = [lastDate timeIntervalSinceDate:currentDate];
    unsigned long seconds = interval;
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    unsigned long hours = minutes / 60;
    if(hours)
        minutes %= 60;
    unsigned long days=hours/24;
    if(days)
        hours %=24;
    
    NSMutableString * result = [NSMutableString new];
    dateFormatter.dateFormat=@"EEE, MMM d, h:mma";
    
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    NSInteger destinationGMTOffset1 = [destinationTimeZone secondsFromGMTForDate:lastDate];
    NSInteger destinationGMTOffset2 = [destinationTimeZone secondsFromGMTForDate:currentDate];
    
    NSTimeInterval interval2 = destinationGMTOffset1;
    NSTimeInterval interval3 = destinationGMTOffset2;
    
    NSDate* destinationDate =[[NSDate alloc] initWithTimeInterval:interval2 sinceDate:lastDate];
    NSDate* currentDateTime = [[NSDate alloc] initWithTimeInterval:interval3 sinceDate:currentDate];
    
    NSString *activityTime=[dateFormatter stringFromDate:destinationDate];
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSInteger differenceInDays =
    [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:destinationDate]-
    [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:currentDateTime];
    switch (differenceInDays) {
        case -1:
        {
            dateFormatter.dateFormat=@"h:mma";
            [result appendFormat:@"%@",[NSString stringWithFormat:@"Yesterday at %@",[dateFormatter stringFromDate:destinationDate]]];
        }
            break;
        case 0:
        {
            
            dateFormatter.dateFormat=@"h:mma";
            [result appendFormat:@"%@",[NSString stringWithFormat:@"Today at %@",[dateFormatter stringFromDate:destinationDate]]];
        }
            break;
        case 1:
        {
            [result appendFormat: @"Tommorow"];
            dateFormatter.dateFormat=@"h:mma";
            
            [result appendFormat:@"%@",[NSString stringWithFormat:@"Tomorrow at %@",[dateFormatter stringFromDate:destinationDate]]];
        }
            break;
        default: {
            [result appendFormat:@"%@",activityTime];
        }
            break;
    }
    
    return result;
}

+(BOOL)LastDistanceFromLocationExceeds_50M{
    
    // Retrieve the location
    CLLocationDegrees latitude = [[NSUserDefaults standardUserDefaults] doubleForKey:@"LastLocationLat"];
    CLLocationDegrees longitude = [[NSUserDefaults standardUserDefaults] doubleForKey:@"LastLocationLong"];
    
    if(latitude==0.0 && longitude==0.0f){

        [[NSUserDefaults standardUserDefaults] setDouble:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude forKey:@"LastLocationLat"];
        [[NSUserDefaults standardUserDefaults] setDouble:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude forKey:@"LastLocationLong"];
        
    }
    CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    CLLocationDistance kmeters = [[[BeagleManager SharedInstance]currentLocation] distanceFromLocation:oldLocation]/1000.0;
    //    NSLog(@"kmeters = %@", kmeters);
    if(kmeters/1.6>=50.0f)
        return YES;
    
    return NO;
    // Store the location
    
    
}

+(BOOL)hasBeenMoreThanSixtyMinutes{
    NSDate *lastHourUpdate=[[NSUserDefaults standardUserDefaults] valueForKey:@"HourlyUpdate"];
    
    if(lastHourUpdate==nil){
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"HourlyUpdate"];
    }
    NSLog(@"interval%lf",[lastHourUpdate timeIntervalSinceNow]);
    if ([lastHourUpdate timeIntervalSinceNow] <= -3600) {
        
        [[NSUserDefaults standardUserDefaults] setDouble:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude forKey:@"LastLocationLat"];
        [[NSUserDefaults standardUserDefaults] setDouble:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude forKey:@"LastLocationLong"];
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"HourlyUpdate"];
        
        return YES;
        
    }
    
    return NO;
}
+(void) saveImage:(UIImage *)image withFileName:(NSInteger)imageName{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];


        NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.png", (long)imageName]];
        NSData *data=UIImagePNGRepresentation(image);
        [ data writeToFile:savedImagePath atomically:YES];
}

+(UIImage *) loadImage:(NSInteger)fileName{
    NSString * directoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    UIImage * result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%ld.png", directoryPath, (long)fileName]];
    
    return result;
}


+(BeagleNotificationClass*)getNotificationObject:(NSNotification*)object{
    
    BeagleNotificationClass *notification=[[BeagleNotificationClass alloc]init];
    id obj=[object valueForKey:@"userInfo"];
    notification.notificationId=[[[object valueForKey:@"userInfo"]valueForKey:@"nid"]integerValue];
    id obj1=[obj valueForKey:@"activity"];
    NSLog(@"obj1=%@",obj1);

    if(obj1!=nil && obj1!=[NSNull class] && [[obj1 allKeys]count]!=0){
        BeagleActivityClass*activity=[[BeagleActivityClass alloc]initWithDictionary:obj1];
        notification.activity=activity;
        notification.backgroundTap=TRUE;
    }
    else{
        notification.backgroundTap=FALSE;
    }
    
    notification.notificationType=[[[object valueForKey:@"userInfo"] valueForKey:@"notification_type"]integerValue];
    
    [[BeagleManager SharedInstance]setBadgeCount:[[[object valueForKey:@"userInfo"] valueForKey:@"badge"]intValue]];
    notification.profileImage=[[object valueForKey:@"userInfo"] valueForKey:@"profileImage"];
    notification.notifType=[[[object valueForKey:@"userInfo"] valueForKey:@"notifType"]integerValue];
    notification.latitude=[[object valueForKey:@"userInfo"] valueForKey:@"lat"];
    notification.longitude=[[object valueForKey:@"userInfo"] valueForKey:@"lng"];
    notification.notificationString=[[object valueForKey:@"userInfo"] valueForKey:@"message"];
    notification.playerName=[[object valueForKey:@"userInfo"] valueForKey:@"player_name"];
    notification.photoUrl=[[object valueForKey:@"userInfo"] valueForKey:@"photo_url"];
    notification.timeOfNotification=[[object valueForKey:@"userInfo"] valueForKey:@"timing"];
    notification.referredId=[[[object valueForKey:@"userInfo"] valueForKey:@"reffered_to"]integerValue];
    return notification;
}
+(BeagleNotificationClass*)getNotificationForInterestPost:(NSNotification*)object{
    BeagleNotificationClass *notification=[[BeagleNotificationClass alloc]init];
    id obj1=[object valueForKey:@"userInfo"];
    NSLog(@"obj1=%@",obj1);
    notification.notificationId=[[[object valueForKey:@"userInfo"]valueForKey:@"nid"]integerValue];
    notification.notificationString=[obj1 valueForKey:@"msg"];
    notification.playerName=[obj1 valueForKey:@"player_name"];
    notification.postChatId=[[obj1 valueForKey:@"chatid"]integerValue];
    notification.activityOwnerId=[[obj1 valueForKey:@"ownerid"]integerValue];
    notification.postDesc=[obj1 valueForKey:@"post"];
    notification.notifType=[[[object valueForKey:@"userInfo"] valueForKey:@"notifType"]integerValue];
    notification.profileImage=[[object valueForKey:@"userInfo"] valueForKey:@"profileImage"];
    if([[obj1 valueForKey:@"activity_id"]integerValue]!=0){
        BeagleActivityClass*activity=[[BeagleActivityClass alloc]init];
        notification.activity=activity;
        notification.activity.activityId=[[obj1 valueForKey:@"activity_id"]integerValue];
        notification.activity.postCount=[[obj1 valueForKey:@"count"]integerValue];
    }
    notification.photoUrl=[obj1 valueForKey:@"player_photo_url"];
    notification.playerId=[[obj1 valueForKey:@"player_id"]integerValue];
    notification.backgroundTap=TRUE;
    notification.notificationType=17;
    return notification;
    
    
}

+(void)updateBadgeInfoOnTheServer:(NSInteger)notificationId{
    NSURL *url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@received_notification.json?id=%ld",herokuHost,(long)notificationId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if ([data length] > 0 && error == nil){
             
             [self performSelectorOnMainThread:@selector(receivedData:) withObject:data waitUntilDone:NO];
         }else if ([data length] == 0 && error == nil){
         }else if (error != nil && error.code == NSURLErrorTimedOut){ //used this NSURLErrorTimedOut from foundation error responses
         }else if (error != nil){
             NSLog(@"Error=%@",[error description]);
         }
     }];
}

+(void)receivedData:(NSData*)returnData{
    NSDictionary* resultsd = [[[NSString alloc] initWithData:returnData
                                                    encoding:NSUTF8StringEncoding] JSONValue];
    
    NSLog(@"Badge Updated =%ld",(long)[[resultsd objectForKey:@"badge"]integerValue]);
    
    [[BeagleManager SharedInstance]setBadgeCount:[[resultsd objectForKey:@"badge"]integerValue]];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[BeagleManager SharedInstance]badgeCount]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
    
}

@end
