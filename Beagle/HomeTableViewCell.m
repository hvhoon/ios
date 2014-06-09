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
static UIFont *forthTextFont = nil;
+ (void)initialize
{
	if(self == [HomeTableViewCell class]){
        firstTextFont=[UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        secondTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        thirdTextFont=[UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
        forthTextFont=[UIFont fontWithName:@"HelveticaNeue" size:15.0f];
        
    }
}

- (void)drawContentView:(CGRect)r
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *background;
    UIColor *backgroundColor;
    background = [UIColor whiteColor];
    backgroundColor = background;
    
    // Start from the top and set the top padding to 8
    int fromTheTop = 0;
    
    if(self.selected)
    {
        backgroundColor = background;
    }
    
    [backgroundColor set];
    
    
    CGContextFillRect(context, r);
    
    UIImage * originalImage =self.photoImage;
    
    // Draw the original image at the origin
    UIImage *newImage = [BeagleUtilities imageCircularBySize:originalImage sqr:100.0f];
    
    fromTheTop = 8; // top spacing
    
    //Draw the scaled and cropped image
    CGRect thisRect = CGRectMake(16, fromTheTop, 50, 50);
    [newImage drawInRect:thisRect];

    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // Drawing the time label
    [style setAlignment:NSTextAlignmentRight];
    UIColor *color=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                            secondTextFont, NSFontAttributeName,
                            color,NSForegroundColorAttributeName,
                            style, NSParagraphStyleAttributeName, nil];
    
    CGSize dateTextSize = [[BeagleUtilities activityTime:bg_activity.startActivityDate endate:bg_activity.endActivityDate] boundingRectWithSize:CGSizeMake(300, r.size.height)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:attrs
                                                   context:nil].size;
    
    
    [[BeagleUtilities activityTime:bg_activity.startActivityDate endate:bg_activity.endActivityDate] drawInRect:CGRectMake(304-dateTextSize.width,
                                          fromTheTop,
                                          dateTextSize.width,dateTextSize.height) withAttributes:attrs];

    
    // Drawing the organizer name
    [style setAlignment:NSTextAlignmentLeft];
     attrs=[NSDictionary dictionaryWithObjectsAndKeys:
     secondTextFont, NSFontAttributeName,
     [UIColor blackColor],NSForegroundColorAttributeName,
     style, NSParagraphStyleAttributeName, nil];

    CGSize organizerNameSize=[bg_activity.organizerName boundingRectWithSize:CGSizeMake(300, r.size.height)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:attrs
                                 context:nil].size;
    
    [bg_activity.organizerName drawInRect:CGRectMake(75, 55.5-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height) withAttributes:attrs];
    
    if(bg_activity.dosRelation!=0){
        if(bg_activity.dosRelation==1) {
            [[UIImage imageNamed:@"DOS2"] drawInRect:CGRectMake(75+8+organizerNameSize.width, 38.5, 27, 15)];
        }else {
            [[UIImage imageNamed:@"DOS3"] drawInRect:CGRectMake(75+8+organizerNameSize.width, 38.5, 32, 15)];
        }
    }
    
    // Adding the height of the profile picture
    fromTheTop = fromTheTop+thisRect.size.height;
    
    // Adding buffer below the top section with the profile picture
    fromTheTop = fromTheTop+8;
    
    // Drawing the activity description
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                             firstTextFont, NSFontAttributeName,
                             [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect commentTextRect = [self.bg_activity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:attrs
                                                                  context:nil];
    
    if([self.bg_activity.activityDesc length]!=0){
        [self.bg_activity.activityDesc drawInRect:CGRectMake(16, fromTheTop, commentTextRect.size.width,commentTextRect.size.height) withAttributes:attrs];
        fromTheTop = fromTheTop+commentTextRect.size.height;
    }
    
    // Drawing the location
    [style setAlignment:NSTextAlignmentLeft];
    attrs =[NSDictionary dictionaryWithObjectsAndKeys:
    secondTextFont, NSFontAttributeName,
    color,NSForegroundColorAttributeName,
    style, NSParagraphStyleAttributeName, nil];
    
    CGSize locationTextSize = [self.bg_activity.locationName boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:attrs
                                                   context:nil].size;
    
    
    fromTheTop = fromTheTop+8; // Adding buffer between the description and location
    [self.bg_activity.locationName drawInRect:CGRectMake(16, fromTheTop,
                                          locationTextSize.width, locationTextSize.height) withAttributes:attrs];
    fromTheTop = fromTheTop+locationTextSize.height;
    fromTheTop = fromTheTop+16; // Adding space after location

    // Drawing number of interested text
    [style setAlignment:NSTextAlignmentLeft];
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           secondTextFont, NSFontAttributeName,
           [UIColor blackColor],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];

    CGSize participantsCountTextSize;
    
    // If your friends are interested
    if(self.bg_activity.participantsCount>0 && self.bg_activity.dos2Count>0){
        
        NSString* relationship = nil;
        
        if(self.bg_activity.dos2Count > 1)
            relationship = @"Friends";
        else
            relationship = @"Friend";
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested - %ld %@",(long)self.bg_activity.participantsCount,(long)self.bg_activity.dos2Count, relationship]  boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        
        [[NSString stringWithFormat:@"%ld Interested - %ld %@",(long)self.bg_activity.participantsCount,(long)self.bg_activity.dos2Count, relationship] drawInRect:CGRectMake(16, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height) withAttributes:attrs];
        fromTheTop = fromTheTop+participantsCountTextSize.height;
        fromTheTop = fromTheTop+18; // Spacing after the count of people interested
        
    // If people are interested but none of them are your friends
    }else if(self.bg_activity.participantsCount>0){
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.bg_activity.participantsCount]  boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs  context:nil].size;
        
        [[NSString stringWithFormat:@"%ld Interested",(long)self.bg_activity.participantsCount] drawInRect:CGRectMake(16, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height) withAttributes:attrs];
        fromTheTop = fromTheTop+participantsCountTextSize.height;
        fromTheTop = fromTheTop+18; // Spacing after the count of people interested

    }

    // If you've already expressed interest, icons for 'Count me in' and 'Comments'
    if(self.bg_activity.isParticipant)
        [[UIImage imageNamed:@"Star"] drawInRect:CGRectMake(16, fromTheTop, 19, 18)];
    else
        [[UIImage imageNamed:@"Star-Unfilled"] drawInRect:CGRectMake(16, fromTheTop, 19, 18)];
    
    // Drawing the 'Count me in' text
    // Changing the text based on who is seeing this
    NSString* expressInterestText = nil;
    
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           forthTextFont, NSFontAttributeName,
           [BeagleUtilities returnBeagleColor:1],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    // If it's the organizer
    if (self.bg_activity.dosRelation==0) {
        expressInterestText = @"Created by you";
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               thirdTextFont, NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:1],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
    }
    // If you are the first one to express interest
    else if(self.bg_activity.dosRelation > 0 && self.bg_activity.participantsCount == 0) {
        expressInterestText = @"Be the first to join";
    }
    // You are not the organizer and have already expressed interest
    else if(self.bg_activity.dosRelation > 0 && self.bg_activity.isParticipant)
    {
        expressInterestText = @"Count me in";
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               thirdTextFont, NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:1],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
    }
    // You are not the organizer and have not expressed interest
    else
        expressInterestText = @"Are you in?";
    
    // Actually draw it now!
    CGSize interestedSize = [expressInterestText boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
    [expressInterestText drawInRect:CGRectMake(16+19+5, fromTheTop, interestedSize.width, interestedSize.height) withAttributes:attrs];
    
    fromTheTop = fromTheTop+3;
    
    // Comments icon and text now
    if(self.bg_activity.postCount>0) {
        [[UIImage imageNamed:@"Comment"] drawInRect:CGRectMake(304-21, fromTheTop, 21, 18)];
        // Drawing the comment count text
        [style setAlignment:NSTextAlignmentLeft];
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 secondTextFont, NSFontAttributeName,
                 [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)self.bg_activity.postCount]  boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        
        [[NSString stringWithFormat:@"%ld",(long)self.bg_activity.postCount] drawInRect:CGRectMake(301-21-postCountTextSize.width, fromTheTop-1, postCountTextSize.width, postCountTextSize.height) withAttributes:attrs];
    }
    else
        [[UIImage imageNamed:@"Add-Comment"] drawInRect:CGRectMake(304-21, fromTheTop, 21, 18)];
    
    fromTheTop = fromTheTop+16;
    fromTheTop = fromTheTop+10;
    
    // Drawing the card seperator
    CGRect stripRect = {0, fromTheTop, 320, 8};
    
    CGContextSetRGBFillColor(context, 230.0/255.0, 230.0/255.0, 230.0/255.0, 1.0);
    CGContextFillRect(context, stripRect);
    
    // add the interested touchzone rectangle back!!
    interestedRect=CGRectMake(0, fromTheTop-8-35, 250, 35);
    

}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    CGPoint startPoint =[touch locationInView:self.contentView];
    
    if(CGRectContainsPoint(interestedRect,startPoint)){
        if(self.bg_activity.dosRelation!=0){
            if (self.delegate && [self.delegate respondsToSelector:@selector(updateInterestedStatus:)])
            [delegate updateInterestedStatus:cellIndex];
        }
    }
    else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(detailedInterestScreenRedirect:)])
            [self.delegate detailedInterestScreenRedirect:cellIndex];

    }
    [super touchesEnded:touches withEvent:event];
}
@end
