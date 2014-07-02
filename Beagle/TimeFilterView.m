//
//  TimeFilterView.m
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "TimeFilterView.h"
@interface TimeFilterView ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpacingFromStatusBarLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpacingFromStatusBarRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenFiltersLeftFirst;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenFiltersRightFirst;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenFiltersLeftSecond;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenFiltersRightSecond;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenFiltersLeftThird;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingBetweenFiltersRightThird;

@end

@implementation TimeFilterView
@synthesize delegate = _delegate;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TimeFilterView" owner:self options:nil];
        
        self=[nib objectAtIndex:0];
        [self setUserInteractionEnabled:YES];

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        // make your gesture recognizer priority
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        _topSpacingFromStatusBarLeft.constant =
        [UIScreen mainScreen].bounds.size.height > 480.0f ? 58 : 29;
        _topSpacingFromStatusBarRight.constant =
        [UIScreen mainScreen].bounds.size.height > 480.0f ? 58 : 29;

        _spacingBetweenFiltersLeftFirst.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 31 : 21;
        _spacingBetweenFiltersRightFirst.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 31 : 21;
        
        _spacingBetweenFiltersLeftSecond.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 31 : 21;
        _spacingBetweenFiltersRightSecond.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 31 : 21;
        
        _spacingBetweenFiltersLeftThird.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 31 : 21;
        _spacingBetweenFiltersRightThird.constant=[UIScreen mainScreen].bounds.size.height > 480.0f ? 31 : 21;



        
    }
    return self;
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(filterIndex:)])
        [_delegate filterIndex:0];
    
}
-(IBAction)timeFilterSelected:(UIButton*)sender{
    
 if (self.delegate && [self.delegate respondsToSelector:@selector(filterIndex:)])
        [_delegate filterIndex:sender.tag];

    
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
