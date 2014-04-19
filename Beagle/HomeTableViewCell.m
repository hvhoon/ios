//
//  HomeTableViewCell.h
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


#import "HomeTableViewCell.h"
#import "BeagleActivityClass.h"
@implementation HomeTableViewCell
@synthesize delegate,cellIndex;
@synthesize bg_activity,photoImage;
static UIFont *firstTextFont = nil;
static UIFont *secondTextFont = nil;
static UIFont *thirdTextFont = nil;
+ (void)initialize
{
	if(self == [HomeTableViewCell class]){
        firstTextFont=[UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        secondTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        thirdTextFont=[UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
        
    }
}



- (void)drawContentView:(CGRect)r
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *background;
    UIColor *backgroundColor;
    background = [UIColor whiteColor];
    backgroundColor = background;
    
    
    if(self.selected)
    {
        backgroundColor = background;
    }
    
    [backgroundColor set];
    
    
    CGContextFillRect(context, r);
    
    UIImage * originalImage =self.photoImage;
    CGFloat oImageWidth = originalImage.size.width;
    CGFloat oImageHeight = originalImage.size.height;
    // Draw the original image at the origin
    CGRect newRect = CGRectMake(0, 0, oImageWidth, oImageHeight);
    UIImage *newImage = [BeagleUtilities circularScaleNCrop:originalImage rect:newRect];
    
    
    //Draw the scaled and cropped image
    CGRect thisRect = CGRectMake(16, 8, 52.5, 52.5);
    [newImage drawInRect:thisRect];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentRight];
    UIColor *color=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                            secondTextFont, NSFontAttributeName,
                            color,NSForegroundColorAttributeName,
                            style, NSParagraphStyleAttributeName, nil];
    
    CGSize dateTextSize = [@"Later Today" boundingRectWithSize:CGSizeMake(300, r.size.height)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:attrs
                                                   context:nil].size;
    
    
    [@"Later Today" drawInRect:CGRectMake(304-dateTextSize.width,
                                          8,
                                          dateTextSize.width,dateTextSize.height) withAttributes:attrs];

    
    [style setAlignment:NSTextAlignmentLeft];
     attrs=[NSDictionary dictionaryWithObjectsAndKeys:
     secondTextFont, NSFontAttributeName,
     [UIColor blackColor],NSForegroundColorAttributeName,
     style, NSParagraphStyleAttributeName, nil];

    CGSize organizerNameSize=[bg_activity.organizerName boundingRectWithSize:CGSizeMake(300, r.size.height)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:attrs
                                 context:nil].size;
    
    [bg_activity.organizerName drawInRect:CGRectMake(76,
                                          52.5-organizerNameSize.height,
                                          organizerNameSize.width, organizerNameSize.height) withAttributes:attrs];
    
    if(bg_activity.dosRelation==0){
        [[UIImage imageNamed:@"DOS2"] drawInRect:CGRectMake(76+10+organizerNameSize.width, 52.5-15, 27, 15)];
    }
    
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                             firstTextFont, NSFontAttributeName,
                             [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect commentTextRect = [self.bg_activity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:attrs
                                                                  context:nil];
    
    if([self.bg_activity.activityDesc length]!=0){
        [self.bg_activity.activityDesc drawInRect:CGRectMake(16,69,commentTextRect.size.width,commentTextRect.size.height) withAttributes:attrs];
    }
    
    [style setAlignment:NSTextAlignmentLeft];
    attrs =[NSDictionary dictionaryWithObjectsAndKeys:
    secondTextFont, NSFontAttributeName,
    color,NSForegroundColorAttributeName,
    style, NSParagraphStyleAttributeName, nil];
    
     CGSize locationTextSize = [self.bg_activity.locationName boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:attrs
                                                   context:nil].size;
    
    
    [self.bg_activity.locationName drawInRect:CGRectMake(16,69+8+commentTextRect.size.height,
                                          locationTextSize.width, locationTextSize.height) withAttributes:attrs];

    
    
    [style setAlignment:NSTextAlignmentLeft];
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           secondTextFont, NSFontAttributeName,
           [UIColor blackColor],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];

    CGSize participantsCountTextSize;
    if(self.bg_activity.participantsCount>0 && self.bg_activity.dos2Count>0){
       

        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.bg_activity.participantsCount,(long)self.bg_activity.dos2Count]  boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:attrs
                                                               context:nil].size;
        
        [[NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.bg_activity.participantsCount,(long)self.bg_activity.dos2Count] drawInRect:CGRectMake(16,69+8+commentTextRect.size.height+16+locationTextSize.height,
                                                             participantsCountTextSize.width, participantsCountTextSize.height) withAttributes:attrs];
        
        
    }else{
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.bg_activity.participantsCount]  boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                                                                                                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                                                                  attributes:attrs
                                                                                                                                                                                     context:nil].size;
        
        [[NSString stringWithFormat:@"%ld Interested",(long)self.bg_activity.participantsCount] drawInRect:CGRectMake(16,69+8+commentTextRect.size.height+16+locationTextSize.height,
                                                                                                                                                          participantsCountTextSize.width, participantsCountTextSize.height) withAttributes:attrs];
        
        

    }
    
    if(self.bg_activity.isParticipant){
        [[UIImage imageNamed:@"Star"] drawInRect:CGRectMake(16, 69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16, 16, 15)];
    }

    else{

        [[UIImage imageNamed:@"Star-Unfilled"] drawInRect:CGRectMake(16,69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16, 16, 15)];
        
    }
    
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           thirdTextFont, NSFontAttributeName,
           [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];

    CGSize interestedSize = [@"I'm Interested"  boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                                                                                                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                                                              attributes:attrs
                                                                                                                                                                                 context:nil].size;
    
    [@"I'm Interested" drawInRect:CGRectMake(42,69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16,
                                                                                                                                                      interestedSize.width, interestedSize.height) withAttributes:attrs];
    
    
    if(self.bg_activity.postCount>0)
    [[UIImage imageNamed:@"Comment"] drawInRect:CGRectMake(306-21, 69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16, 21, 18)];
    else{
        [[UIImage imageNamed:@"Add-Comment"] drawInRect:CGRectMake(306-21, 69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16,21, 18)];
    }
    
    [style setAlignment:NSTextAlignmentLeft];
     attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           secondTextFont, NSFontAttributeName,
                           [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];
    
    CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)self.bg_activity.postCount]  boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                                     attributes:attrs
                                                                        context:nil].size;
    
    [[NSString stringWithFormat:@"%ld",(long)self.bg_activity.postCount] drawInRect:CGRectMake(300-21- postCountTextSize.width,69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16-2,
                                             postCountTextSize.width, postCountTextSize.height) withAttributes:attrs];
    
    
    CGRect stripRect = {0, 69+8+commentTextRect.size.height+16+locationTextSize.height+participantsCountTextSize.height+16+postCountTextSize.height+8, 320, 8};
    
    CGContextSetRGBFillColor(context, 230.0/255.0, 230.0/255.0, 230.0/255.0, 1.0);
    CGContextFillRect(context, stripRect);
    

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch =[touches anyObject];
//    CGPoint startPoint =[touch locationInView:self.contentView];

    [self.delegate detailedInterestScreenRedirect:cellIndex];
    [super touchesBegan:touches withEvent:event];
}
@end
