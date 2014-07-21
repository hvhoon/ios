//
//  FriendsTableViewCell.m
//  Beagle
//
//  Created by Kanav Gupta on 20/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "FriendsTableViewCell.h"
@implementation FriendsTableViewCell
@synthesize photoImage,delegate,cellIndexPath,bgPlayer;
static UIFont *firstTextFont = nil;
static UIFont *secondTextFont = nil;
+ (void)initialize
{
	if(self == [FriendsTableViewCell class]){
        firstTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        secondTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
        
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
    UIImage *newImage = [BeagleUtilities imageCircularBySize:originalImage sqr:70.0f];
    
    fromTheTop = 8; // top spacing
    //Draw the scaled and cropped image
    CGRect thisRect = CGRectMake(16, fromTheTop, 35, 35);
    [newImage drawInRect:thisRect];
    
    profileRect=thisRect;
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // Drawing the time label
    [style setAlignment:NSTextAlignmentLeft];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           firstTextFont, NSFontAttributeName,
                           [UIColor blackColor],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];
    
    
    
    // Drawing the organizer name
    
    CGSize organizerNameSize=[self.bgPlayer.fullName boundingRectWithSize:CGSizeMake(288, r.size.height)
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:attrs
                                                                     context:nil].size;
    nameRect=CGRectMake(67, fromTheTop+4, organizerNameSize.width, organizerNameSize.height);
    
    [self.bgPlayer.fullName drawInRect:nameRect withAttributes:attrs];
    
    // Adding the height of the profile picture
    
    // Adding buffer below the top section with the profile picture
    fromTheTop = fromTheTop+4+organizerNameSize.height;
    
    // Drawing the activity description
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             secondTextFont, NSFontAttributeName,
             [BeagleUtilities returnBeagleColor:3],NSForegroundColorAttributeName,
             style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    CGSize maximumLabelSize = CGSizeMake(288,r.size.height);
    
    CGRect locationTextRect = [self.bgPlayer.location boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil];
    
    if([self.bgPlayer.location length]!=0){
        [self.bgPlayer.location drawInRect:CGRectMake(67, fromTheTop, locationTextRect.size.width,locationTextRect.size.height) withAttributes:attrs];
    }
    
    if(self.bgPlayer.beagleUserId==0){
        UIButton *inviteStatusButton=[UIButton buttonWithType:UIButtonTypeCustom];
        inviteStatusButton.frame=CGRectMake(320-80, 0, 80, 54);
        [inviteStatusButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 16.0f)];
        [inviteStatusButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        
        if(self.bgPlayer.isInvited){
            inviteStatusButton.titleLabel.backgroundColor=[UIColor clearColor];
            inviteStatusButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            inviteStatusButton.titleLabel.textColor=[UIColor blackColor];
            inviteStatusButton.titleLabel.font=secondTextFont;
            [inviteStatusButton setTitleColor:[BeagleUtilities returnBeagleColor:3] forState:UIControlStateNormal];
         inviteStatusButton.titleLabel.textAlignment = NSTextAlignmentCenter;            [inviteStatusButton setTitle: @"Invite\nSent" forState: UIControlStateNormal];
        }else{
            [inviteStatusButton setImage:[UIImage imageNamed:@"Invite"] forState:UIControlStateNormal];
            [inviteStatusButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Invite"] withColor:[[BeagleUtilities returnBeagleColor:13] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
        [inviteStatusButton addTarget:self action:@selector(inviteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:inviteStatusButton];
    
    }
    
    UIView* lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(16, 60, 288, 1)];
    lineSeparator.backgroundColor = [BeagleUtilities returnBeagleColor:2];
    [self addSubview:lineSeparator];
}


-(void)inviteButtonClicked:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteFacebookFriendOnBeagle:)])
        [self.delegate inviteFacebookFriendOnBeagle:cellIndexPath];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch =[touches anyObject];
    CGPoint startPoint =[touch locationInView:self.contentView];
    
    if((CGRectContainsPoint(profileRect,startPoint)||CGRectContainsPoint(nameRect,startPoint))&& self.bgPlayer.beagleUserId!=0){
            if (self.delegate && [self.delegate respondsToSelector:@selector(userProfileSelected:)])
                [self.delegate userProfileSelected:cellIndexPath];
        }
        
 
    
    [super touchesEnded:touches withEvent:event];
}
@end
