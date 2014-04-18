//
//  BlankHomePageView.m
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BlankHomePageView.h"

@interface BlankHomePageView ()
@property (weak, nonatomic)IBOutlet NSLayoutConstraint *verticalSpacing;
@property (weak, nonatomic)IBOutlet NSLayoutConstraint *gapBetween_1_2_FilterBtns;
@property (weak, nonatomic)IBOutlet NSLayoutConstraint *gapBetween_2_3_FilterBtns;
 @property (weak, nonatomic) IBOutlet NSLayoutConstraint *gapBetween_3_4_FilterBtns;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpacingForLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceForLabel_1_2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceForLabel_2_3;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpacingForLabel_3_4;

@end

@implementation BlankHomePageView
@synthesize delegate=_delegate;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)updateViewConstraints {
    _verticalSpacing.constant =
    [UIScreen mainScreen].bounds.size.height > 480.0f ? 32 : 16;
    
    _gapBetween_1_2_FilterBtns.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 16 : 11;
    
    _gapBetween_2_3_FilterBtns.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 16 : 11;

    
    _gapBetween_3_4_FilterBtns.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 16 : 11;

    
    _verticalSpacingForLabel.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 50 : 34;
    
    _verticalSpaceForLabel_1_2.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 58 : 53;
    
    _verticalSpaceForLabel_2_3.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 58 : 53;
    
    _verticalSpacingForLabel_3_4.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 58 : 53;
}
-(IBAction)NothingTryAgainClicked:(id)sender{
    [_delegate filterOptionClicked:0];
}
-(IBAction)changeYourFilterClicked:(id)sender{
    [_delegate filterOptionClicked:1];
}
-(IBAction)inviteYourFriendsClicked:(id)sender{
    [_delegate filterOptionClicked:2];
}

-(IBAction)createAInterestClicked:(id)sender{
    [_delegate filterOptionClicked:3];
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
