//
//  CreateAnimationBlurView.m
//  Beagle
//
//  Created by Kanav Gupta on 10/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "CreateAnimationBlurView.h"
#import "UIImage+ImageEffects.h"
#import "UIScreen+Screenshot.h"
@interface CreateAnimationBlurView ()<UIGestureRecognizerDelegate>
@property(nonatomic, weak)  UIView *parent;
@property(nonatomic, assign) CGPoint location;
@property(nonatomic, strong) dispatch_source_t timer;
@property(nonatomic,weak)IBOutlet UIImageView*bigStarImageView;
@property(nonatomic,weak)IBOutlet UIImageView*profileImageView;
@property(nonatomic,weak)IBOutlet UILabel*superstarTextLabel;
@property(nonatomic,weak)IBOutlet UILabel*friendsNotifyLabel;
@property(nonatomic,weak)IBOutlet UILabel*joinChatInfoLabel;
@property(nonatomic,weak)IBOutlet UIActivityIndicatorView*loadingIndicatorView;
@end
@implementation CreateAnimationBlurView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
@synthesize delegate;
- (id) initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        // make your gesture recognizer priority
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
    }
    
    return self;
}
-(void)loadAnimationView:(UIImage*)pImage{
    _blurType=InterestCreate;
    
    _profileImageView.image=[BeagleUtilities imageCircularBySize:pImage sqr:210.0f];
    [_profileImageView setHidden:YES];
    [_superstarTextLabel setHidden:YES];
    [_friendsNotifyLabel setHidden:YES];
    [_joinChatInfoLabel setHidden:YES];
    _loadingIndicatorView.transform=CGAffineTransformMakeScale(1.35, 1.35);

}

-(void)loadCustomAnimationView:(UIImage*)pImage{
        _blurType=InterestCreate;
    _friendsNotifyLabel.text=@"Now let us tell the friends               you selected about your post";
    _profileImageView.image=[BeagleUtilities imageCircularBySize:pImage sqr:210.0f];
    [_profileImageView setHidden:YES];
    [_superstarTextLabel setHidden:YES];
    [_friendsNotifyLabel setHidden:YES];
    [_joinChatInfoLabel setHidden:YES];
    _loadingIndicatorView.transform=CGAffineTransformMakeScale(1.35, 1.35);
    
}

-(void)loadDetailedInterestAnimationView:(NSString*)name{
    
        _blurType=InterestInvite;
    _superstarTextLabel.text=@"Awesome";
    _friendsNotifyLabel.text=[NSString stringWithFormat:@"We'll let %@ know you're interested!",[[name componentsSeparatedByString:@" "] objectAtIndex:0]];
    _joinChatInfoLabel.text=@"Post a chat message,join in the planning,or just have some fun";
    [_bigStarImageView setHidden:YES];
    [_profileImageView setHidden:YES];
    [_superstarTextLabel setHidden:YES];
    [_friendsNotifyLabel setHidden:YES];
    [_joinChatInfoLabel setHidden:YES];
    _loadingIndicatorView.transform=CGAffineTransformMakeScale(1.35, 1.35);
    
}

-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    [self crossDissolveHide];
}
+ (CreateAnimationBlurView *) loadCreateAnimationView:(UIView *) view {
    CreateAnimationBlurView *blur = [[[NSBundle mainBundle] loadNibNamed:@"CreateAnimationBlurView" owner:nil options:nil] objectAtIndex:0];
    blur.userInteractionEnabled=YES;
    blur.parent = view;
    blur.location = CGPointMake(0, 0);
    blur.frame = CGRectMake(blur.location.x, -(blur.frame.size.height + blur.location.y), blur.frame.size.width, blur.frame.size.height);
    
    return blur;
}

- (void) awakeFromNib {
    self.layer.cornerRadius = 1;
}

- (void) unload {
    if(self.timer != nil) {
        
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    
    [self removeFromSuperview];
}



- (void) blurBackground {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGRectGetWidth(self.parent.frame), CGRectGetHeight(self.parent.frame)), NO, 1);
    
    [self.parent drawViewHierarchyInRect:CGRectMake(0, 0, CGRectGetWidth(self.parent.frame), CGRectGetHeight(self.parent.frame)) afterScreenUpdates:YES];
    
    
    UIGraphicsEndImageContext();
    
    __block UIImage *snapshot=[UIScreen screenshot];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        snapshot=[snapshot applyBlurWithRadius:8 tintColor:[[BeagleUtilities returnBeagleColor:13] colorWithAlphaComponent:0.75] saturationDeltaFactor:1.8 maskImage:nil];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.backgroundColor=[UIColor colorWithPatternImage:snapshot];
        });
    });
}

- (void) blurWithColor{
    [self blurBackground];
}

- (void) crossDissolveShow {

    self.frame = CGRectMake(self.location.x, self.location.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    self.alpha =  0.0f;
    
    [UIView transitionWithView:self duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
    
    
    
}

-(void)show{
    if(_blurType==InterestCreate){
        [_loadingIndicatorView stopAnimating];
        [_profileImageView setHidden:NO];
    }else if (_blurType==InterestInvite){
            [_bigStarImageView setHidden:NO];
            [_loadingIndicatorView stopAnimating];
            [_profileImageView setHidden:YES];

    }
    [_superstarTextLabel setHidden:NO];
    [_friendsNotifyLabel setHidden:NO];
    [_joinChatInfoLabel setHidden:NO];

}

- (void) crossDissolveHide {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissEventFilter)])
        [self.delegate dismissEventFilter];
    
    
    if(self.timer != nil) {
        
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    self.frame = CGRectMake(self.location.x, -(self.frame.size.height + self.location.y), self.frame.size.width, self.frame.size.height);
    
    
    [UIView transitionWithView:self duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.alpha =0.0f;
    } completion:^(BOOL finished) {
        
    }];
    
    
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
