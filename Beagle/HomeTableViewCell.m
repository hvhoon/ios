//
//  HomeTableViewCell.h
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


#import "HomeTableViewCell.h"
@implementation HomeTableViewCell
@synthesize delegate,cellIndex;
@synthesize bg_activity,photoImage;
static UIFont *firstTextFont = nil;
static UIFont *secondTextFont = nil;
static UIFont *thirdTextFont = nil;
static UIFont *forthTextFont = nil;
static UIFont *dateTextFont = nil;

#define DISABLED_ALPHA 0.5f
+ (void)initialize
{
	if(self == [HomeTableViewCell class]){
        firstTextFont=[UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        secondTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        thirdTextFont=[UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
        forthTextFont=[UIFont fontWithName:@"HelveticaNeue" size:15.0f];
        dateTextFont =[UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f];
        
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
    CGFloat organizerName_y=60.0f;
    
    [backgroundColor set];
    
    CGContextFillRect(context, r);
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // Drawing the time label
    [style setAlignment:NSTextAlignmentLeft];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue-Bold" size:11.0f], NSFontAttributeName,
                           [BeagleUtilities returnBeagleColor:12],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];

    
    if(self.bg_activity.activityType==2){
        
        CGSize suggestedBySize = [@"SUGGESTED POST" boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                                                                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                         attributes:attrs
                                                                                                                                            context:nil].size;
        
        
        [@"SUGGESTED POST" drawInRect:CGRectMake(16,10,suggestedBySize.width,suggestedBySize.height) withAttributes:attrs];

        fromTheTop += suggestedBySize.height+10;
        organizerName_y=organizerName_y+suggestedBySize.height+10;
    }
    fromTheTop = fromTheTop+10;

    UIImage * originalImage =self.photoImage;
    
    // Draw the original image at the origin
    UIImage *newImage = [BeagleUtilities imageCircularBySize:originalImage sqr:105.0f];
    
    
     // top spacing
    
    //Draw the scaled and cropped image
    CGRect thisRect = CGRectMake(16, fromTheTop, 52.5, 52.5);
    [newImage drawInRect:thisRect];

    profileRect=thisRect;
    
    
    // Drawing the time label
    [style setAlignment:NSTextAlignmentRight];
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                            dateTextFont, NSFontAttributeName,
                            [[BeagleManager SharedInstance] darkDominantColor],NSForegroundColorAttributeName,
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
     [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
     style, NSParagraphStyleAttributeName, nil];

    CGSize organizerNameSize=[bg_activity.organizerName boundingRectWithSize:CGSizeMake(300, r.size.height)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:attrs
                                 context:nil].size;
    
    nameRect = CGRectMake(75,organizerName_y-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height);

    
    [bg_activity.organizerName drawInRect:nameRect withAttributes:attrs];
    
    // Removing the friends icons for now
    /*
    if(bg_activity.dosRelation!=0 && self.bg_activity.activityType!=2){
        if(bg_activity.dosRelation==1) {
            [[UIImage imageNamed:@"DOS2"] drawInRect:CGRectMake(75+8+organizerNameSize.width, 43, 27, 15)];
        }else if(bg_activity.dosRelation==2){
            [[UIImage imageNamed:@"DOS3"] drawInRect:CGRectMake(75+8+organizerNameSize.width, 43, 32, 15)];
        }
    }
    */
    
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
    [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
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
    
    // Suggested post
    if(self.bg_activity.activityType==2){
    UIColor *outlineButtonColor = [[BeagleManager SharedInstance] darkDominantColor];
    UIButton *suggestedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        suggestedButton.frame=CGRectMake(16, fromTheTop,
                                         165,33);
    suggestedButton.tag=[[NSString stringWithFormat:@"444%ld",(long)cellIndex]integerValue];
       [suggestedButton.titleLabel setUserInteractionEnabled: NO];
       [self addSubview:suggestedButton];
        
        
        [[suggestedButton titleLabel]setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f]];
        [suggestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [suggestedButton setTitle:@"ASK FRIENDS NEARBY" forState:UIControlStateNormal];
        
        // Normal state
        [suggestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
        [suggestedButton setTitleColor:outlineButtonColor forState:UIControlStateNormal];
        // Pressed state
        [suggestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
        [suggestedButton setTitleColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
        
        [suggestedButton addTarget:self action:@selector(suggestedBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [suggestedButton setEnabled:YES];

}
    else{

    // Drawing number of interested text
    [style setAlignment:NSTextAlignmentLeft];
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           secondTextFont, NSFontAttributeName,
           [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    // If your friends are interested
    if(self.bg_activity.participantsCount>0){
        
        int countFromTheLeft = 0;
        countFromTheLeft += 16;
        
        CGSize participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.bg_activity.participantsCount]  boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        
        // Adding the Star image
        [[UIImage imageNamed:@"Star-Wireframe"] drawInRect:CGRectMake(countFromTheLeft, fromTheTop, 17, 16)];
        countFromTheLeft += 17+5;
        
        // Adding the # Interested
        [[NSString stringWithFormat:@"%ld Interested", (long)self.bg_activity.participantsCount] drawInRect:CGRectMake(countFromTheLeft, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height) withAttributes:attrs];
        countFromTheLeft += participantsCountTextSize.width+16;
        
        // If of the people interested you have friends interested
        if(self.bg_activity.dos1count>0) {
            
            NSString* relationship = nil;
            
            if(self.bg_activity.dos1count > 1)
                relationship = @"Friends";
            else
                relationship = @"Friend";
            
            // Adding the Friend Image
            [[UIImage imageNamed:@"DOS2-Wireframe"] drawInRect:CGRectMake(countFromTheLeft, fromTheTop, 28, 16)];
            countFromTheLeft += 28+5;
            
            // Adding the # of Friends
            CGSize friendCountTextSize = [[NSString stringWithFormat:@"%ld %@",(long)self.bg_activity.dos1count, relationship]  boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
            
            [[NSString stringWithFormat:@"%ld %@",(long)self.bg_activity.dos1count, relationship]  drawInRect:CGRectMake(countFromTheLeft, fromTheTop, friendCountTextSize.width, friendCountTextSize.height) withAttributes:attrs];
            countFromTheLeft +=friendCountTextSize.width+16;
        }

        // Adding comment count
        if(self.bg_activity.postCount>0) {
            
            // Adding the Comment icon
            [[UIImage imageNamed:@"Comment-Wireframe"] drawInRect:CGRectMake(countFromTheLeft, fromTheTop, 20, 18)];
            countFromTheLeft +=20+5;
            
            // Addinf the Comment # text
            [style setAlignment:NSTextAlignmentLeft];
            attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     secondTextFont, NSFontAttributeName,
                     [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                     style, NSParagraphStyleAttributeName, nil];
            
            CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)self.bg_activity.postCount]  boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        
            [[NSString stringWithFormat:@"%ld",(long)self.bg_activity.postCount] drawInRect:CGRectMake(countFromTheLeft, fromTheTop, postCountTextSize.width, postCountTextSize.height) withAttributes:attrs];
        }

        // Adding spacing after the Count section
        fromTheTop += participantsCountTextSize.height+20;
    }
    // Draw the Button
    UIButton *interestedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    interestedButton.frame=CGRectMake(16, fromTheTop, 151, 34);
    interestedButton.tag=[[NSString stringWithFormat:@"333%ld",(long)cellIndex]integerValue];
    UIColor *buttonColor = [[BeagleManager SharedInstance] mediumDominantColor];
    UIColor *outlineButtonColor = [[BeagleManager SharedInstance] darkDominantColor];
    [interestedButton.titleLabel setUserInteractionEnabled: NO];
    [self addSubview:interestedButton];
    
        if(self.bg_activity.activityType==1){
            [interestedButton addTarget:self action:@selector(interestedBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
            [interestedButton setEnabled:YES];
        }
        else{
            [interestedButton setEnabled:NO];
        }
        
    // If it's the organizer
    if (self.bg_activity.dosRelation==0) {

        // Setup text
        [[interestedButton titleLabel]setFont:forthTextFont];
        [interestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [interestedButton setTitle:@"Created by you" forState:UIControlStateNormal];
        
        // Normal state
        [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:buttonColor] forState:UIControlStateNormal];
        [interestedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        // Pressed state
        [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:[buttonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
        [interestedButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
        
        // Setting up alignments
        [interestedButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [interestedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    }
    // You are not the organizer and have already expressed interest
    else if(self.bg_activity.dosRelation > 0 && self.bg_activity.isParticipant)
    {
        // Setup text
        [[interestedButton titleLabel]setFont:forthTextFont];
        [interestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [interestedButton setTitle:@"I'm Interested" forState:UIControlStateNormal];
        
        // Normal state
        [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:buttonColor] forState:UIControlStateNormal];
        [interestedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star"] withColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        
        // Pressed state
        [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:[buttonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
        [interestedButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
        [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star"] withColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
        
        // Setting up alignments
        [interestedButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, -12.0f, 0.0f, 0.0f)];
        [interestedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    }
    // You are not the organizer and have not expressed interest
    else {
        
        // Setup text
        [[interestedButton titleLabel]setFont:forthTextFont];
        [interestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [interestedButton setTitle:@"I'm Interested" forState:UIControlStateNormal];
        
        // Normal state
        [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
        [interestedButton setTitleColor:outlineButtonColor forState:UIControlStateNormal];
        [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
        
        // Pressed state
        [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
        [interestedButton setTitleColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
        [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
        
        // Setting up alignments
        [interestedButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, -12.0f, 0.0f, 0.0f)];
        [interestedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        }
    }
    
    // Indicate if the activity is Invite only
    if([self.bg_activity.visibility isEqualToString:@"custom"]) {
        
        // Text attributes
        [style setAlignment:NSTextAlignmentRight];
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               secondTextFont, NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:6],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        // Adding the lock image
        [[UIImage imageNamed:@"Invite-only-icon"] drawInRect:CGRectMake(292, fromTheTop+10, 12, 15)];
        
        // Adding the # of Friends
        CGSize inviteOnlyTextSize = [@"Invite Only" boundingRectWithSize:CGSizeMake(288, r.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        
        [@"Invite Only" drawInRect:CGRectMake((320-(35+inviteOnlyTextSize.width)), fromTheTop+10, inviteOnlyTextSize.width, inviteOnlyTextSize.height) withAttributes:attrs];
    }

    // Space left after the button
    fromTheTop += 33+20;
    
    // Drawing the card seperator
    CGRect stripRect = {0, fromTheTop, 320, 1};
    CGContextSetRGBFillColor(context, 230.0/255.0, 230.0/255.0, 230.0/255.0, 1.0);
    CGContextFillRect(context, stripRect);
    
    fromTheTop += 1;

}
-(void)interestedBtnPressed:(id)sender{
    UIButton *btn=(UIButton*)sender;
    if(self.bg_activity.dosRelation!=0){
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateInterestedStatus:)])
            [delegate updateInterestedStatus:btn.tag%333];
    }
   
}

-(void)suggestedBtnPressed:(id)sender{
    UIButton *btn=(UIButton*)sender;
        if (self.delegate && [self.delegate respondsToSelector:@selector(askNearbyFriendsToPartOfSuggestedPost:)])
            [delegate askNearbyFriendsToPartOfSuggestedPost:btn.tag%444];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    CGPoint startPoint =[touch locationInView:self.contentView];
    
    if(self.bg_activity.activityType==1){
    if(CGRectContainsPoint(interestedRect,startPoint)){
        if(self.bg_activity.dosRelation!=0){
            if (self.delegate && [self.delegate respondsToSelector:@selector(updateInterestedStatus:)])
            [delegate updateInterestedStatus:cellIndex];
        }
    }
    else if(CGRectContainsPoint(profileRect,startPoint) || CGRectContainsPoint(nameRect,startPoint)){
        if(self.bg_activity.dosRelation!=0){
        if (self.delegate && [self.delegate respondsToSelector:@selector(profileScreenRedirect:)])
            [self.delegate profileScreenRedirect:cellIndex];
        }else{
            if (self.delegate && [self.delegate respondsToSelector:@selector(detailedInterestScreenRedirect:)])
                [self.delegate detailedInterestScreenRedirect:cellIndex];
        }
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(detailedInterestScreenRedirect:)])
            [self.delegate detailedInterestScreenRedirect:cellIndex];
    }
    }

    [super touchesEnded:touches withEvent:event];
}
@end
