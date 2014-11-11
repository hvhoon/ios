//
//  ExpressInterestPreview.m
//  Beagle
//
//  Created by Kanav Gupta on 07/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ExpressInterestPreview.h"
#define kBigStarImageView 1
#define kSpinningWheel 2
#define kAwesomeLabel 3
#define kInfoLabel 4

@implementation ExpressInterestPreview



- (id)initWithFrame:(CGRect)frame orgn:(NSString*)orgn
{
    self = [super initWithFrame:frame];
    if (self) {
		
        self.backgroundColor=[BeagleUtilities returnBeagleColor:13];
		
        // Initialization code.
		UIImageView* bigStarImageView =[[UIImageView alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-89)/2,(frame.size.height-83)/2-30,89,83)];
        bigStarImageView.image=[UIImage imageNamed:@"Big-Star"];
		bigStarImageView.tag = kBigStarImageView;
		[bigStarImageView setHidden:YES];
		[self  addSubview:bigStarImageView];
        
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinningWheel.tag=kSpinningWheel;
        spinningWheel.center = self.center;
        spinningWheel.hidesWhenStopped=YES;
        [self addSubview:spinningWheel];
        [spinningWheel startAnimating];
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        
        // add the awesomeLabel 
        [style setAlignment:NSTextAlignmentLeft];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f], NSFontAttributeName,
                               [UIColor whiteColor],NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];
        
        
        
       CGSize textSize = [@"Awesome!" boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, frame.size.height)
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:attrs
                                                                     context:nil].size;
            

		CGRect awesomeLabelRect=CGRectMake(([UIScreen mainScreen].bounds.size.width-textSize.width)/2,(frame.size.height+83)/2-20,textSize.width,textSize.height);
		UILabel *awesomeLabel=[[UILabel alloc] initWithFrame:awesomeLabelRect];
		awesomeLabel.textAlignment=NSTextAlignmentCenter;
		awesomeLabel.tag = kAwesomeLabel;
		[awesomeLabel setHidden:YES];
        awesomeLabel.text=@"Awesome!";
		awesomeLabel.font=[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
		awesomeLabel.textColor=[UIColor whiteColor];
		awesomeLabel.backgroundColor=[UIColor clearColor];
        
		[self addSubview:awesomeLabel];
        
        style.lineBreakMode=NSLineBreakByWordWrapping;
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f], NSFontAttributeName,
                 [UIColor whiteColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake(288,999);
        NSArray *firstName=[orgn componentsSeparatedByString:@" "];
        NSString *infoString=[NSString stringWithFormat:@"We'll let %@ know you're interested",[firstName objectAtIndex:0]];
        CGRect commentTextRect = [infoString boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                          attributes:attrs
                                                                             context:nil];

		
		CGRect infoLabelRect=CGRectMake(([UIScreen mainScreen].bounds.size.width-commentTextRect.size.width)/2,(frame.size.height+83)/2+textSize.height-20,commentTextRect.size.width,commentTextRect.size.height);
		UILabel *infoLabel=[[UILabel alloc] initWithFrame:infoLabelRect];
		infoLabel.textAlignment=NSTextAlignmentCenter;
		infoLabel.tag = kInfoLabel;
        infoLabel.numberOfLines=0;
		[infoLabel setHidden:YES];
        infoLabel.text=infoString;
		infoLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
		infoLabel.textColor=[UIColor whiteColor];
		infoLabel.backgroundColor=[UIColor clearColor];
        [self addSubview:infoLabel];
        
    }
    return self;
}

- (void) ShowViewFromCell
{
	    
    UIImageView* bigStarImageView = (UIImageView *)[self viewWithTag:kBigStarImageView];
	[bigStarImageView setHidden:NO];
	UIActivityIndicatorView *spinningWheel=(UIActivityIndicatorView*)[self viewWithTag:kSpinningWheel];
    [spinningWheel stopAnimating];
	
	UILabel *awesomeLabel = (UILabel *)[self viewWithTag:kAwesomeLabel];
	[awesomeLabel setHidden:NO];
    
    UILabel *infoLabel = (UILabel *)[self viewWithTag:kInfoLabel];
	[infoLabel setHidden:NO];

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
