

#import "UIScreen+Screenshot.h"

@implementation UIScreen (Screenshot)


+ (UIImage *)screenshot
{
  
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (systemVersion >= 4.0f)
    {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
        
    } else {
        UIGraphicsBeginImageContext(imageSize);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            CGContextConcatCTM(context, [window transform]);
            
            NSInteger yOffset = [UIApplication sharedApplication].statusBarHidden ? 0 : 0;
            
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y + yOffset);
            
            [[window layer] renderInContext:context];
            CGContextRestoreGState(context);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIWindow*)keyboardRef
{
    UIWindow *keyboard = nil;
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if ([[window description] hasPrefix:@"<UITextEffectsWin"])
        {
            keyboard = window;
            break;
        }
    }
    return keyboard;
}

+ (UIImage *)keyboardScreenshot
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (systemVersion >= 4.0f)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIWindow *window = [UIScreen keyboardRef];
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, [window center].x, [window center].y);
    CGContextConcatCTM(context, [window transform]);
    NSInteger yOffset = [UIApplication sharedApplication].statusBarHidden ? 0 : 0;
    CGContextTranslateCTM(context,
                          -[window bounds].size.width * [[window layer] anchorPoint].x,
                          -[window bounds].size.height * [[window layer] anchorPoint].y + yOffset );
    
    [[window layer] renderInContext:context];
    CGContextRestoreGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



@end
