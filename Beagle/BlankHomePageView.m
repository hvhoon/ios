//
//  BlankHomePageView.m
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BlankHomePageView.h"


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
-(IBAction)NothingTryAgainClicked:(id)sender{
        if (self.delegate && [self.delegate respondsToSelector:@selector(filterOptionClicked:)])
    [_delegate filterOptionClicked:0];
}
-(IBAction)changeYourFilterClicked:(id)sender{
        if (self.delegate && [self.delegate respondsToSelector:@selector(filterOptionClicked:)])
    [_delegate filterOptionClicked:1];
}
-(IBAction)inviteYourFriendsClicked:(id)sender{
        if (self.delegate && [self.delegate respondsToSelector:@selector(filterOptionClicked:)])
    [_delegate filterOptionClicked:2];
}

-(IBAction)createAInterestClicked:(id)sender{
        if (self.delegate && [self.delegate respondsToSelector:@selector(filterOptionClicked:)])
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
