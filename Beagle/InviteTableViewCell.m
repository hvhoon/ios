//
//  InviteTableViewCell.m
//  Beagle
//
//  Created by Kanav Gupta on 25/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "InviteTableViewCell.h"
#import "BeagleUserClass.h"

@implementation InviteTableViewCell
@synthesize photoImage,delegate,cellIndexPath,bgPlayer;
static UIFont *firstTextFont = nil;
static UIFont *secondTextFont = nil;
+ (void)initialize
{
	if(self == [InviteTableViewCell class]){
        firstTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        secondTextFont=[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
        
    }
}
- (void)drawContentView:(CGRect)r
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *background;
    UIColor *backgroundColor;
    if(self.bgPlayer.isInvited)
        background = [[[BeagleManager SharedInstance] lightDominantColor] colorWithAlphaComponent:0.2];
     else
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
    
    fromTheTop = 16; // top spacing
    
    //Draw the scaled and cropped image
    CGRect thisRect = CGRectMake(fromTheTop, fromTheTop, 35, 35);
    [newImage drawInRect:thisRect];
    
    
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
    
    [self.bgPlayer.fullName drawInRect:CGRectMake(67, fromTheTop+4, organizerNameSize.width, organizerNameSize.height) withAttributes:attrs];
    
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
    
        UIButton *accesoryButton=[UIButton buttonWithType:UIButtonTypeCustom];
        accesoryButton.frame=CGRectMake(304-22, 10, 22, 22);
    if(bgPlayer.isInvited){
            [accesoryButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Checked"] withColor:[[BeagleManager SharedInstance] mediumDominantColor]] forState:UIControlStateNormal];
        [accesoryButton addTarget:self action:@selector(accessoryButtonClickedToUninvite:) forControlEvents:UIControlEventTouchUpInside];
        
    }
        else{
            [accesoryButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Add"] withColor:[[BeagleManager SharedInstance] mediumDominantColor]] forState:UIControlStateNormal];
            [accesoryButton addTarget:self action:@selector(accessoryButtonClickedToInvite:) forControlEvents:UIControlEventTouchUpInside];
            
        }
    
        [self setAccessoryView:accesoryButton];

    CGRect seperatorRect = {16, 65, 288, 1};
    
    if (self.bgPlayer.isInvited)
        CGContextSetRGBFillColor(context, 230.0/255.0, 230.0/255.0, 230.0/255.0, 0.0);
    else
        CGContextSetRGBFillColor(context, 230.0/255.0, 230.0/255.0, 230.0/255.0, 1.0);

    CGContextFillRect(context, seperatorRect);
    
}

-(void)accessoryButtonClickedToInvite:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteFriendOnBeagle:)])
        [self.delegate inviteFriendOnBeagle:cellIndexPath];
    
}

-(void)accessoryButtonClickedToUninvite:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(unInviteFriendOnBeagle:)])
        [self.delegate unInviteFriendOnBeagle:cellIndexPath];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch =[touches anyObject];
//    CGPoint startPoint =[touch locationInView:self.contentView];
    
    [super touchesEnded:touches withEvent:event];
}
@end
