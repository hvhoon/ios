//
//  TimeFilterView.m
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "TimeFilterView.h"

@implementation TimeFilterView
@synthesize delegate = _delegate;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TimeFilterView" owner:self options:nil];
        
        self=[nib objectAtIndex:0];

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        // make your gesture recognizer priority
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        
    }
    return self;
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    [_delegate filterIndex:0];
    
}
-(IBAction)timeFilterSelected:(id)sender{
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
