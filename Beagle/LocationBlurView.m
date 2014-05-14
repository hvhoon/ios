//
//  LocationBlurView.m
//  Beagle
//
//  Created by Kanav Gupta on 14/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LocationBlurView.h"
#import "UIImage+ImageEffects.h"
#import "UIScreen+Screenshot.h"
@interface LocationBlurView ()<UIGestureRecognizerDelegate>
@property(nonatomic, weak)  UIView *parent;
@property(nonatomic, assign) CGPoint location;
@property(nonatomic, strong) dispatch_source_t timer;

@end

@implementation LocationBlurView

@synthesize delegate;
- (id) initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        
        
    }
    
    return self;
}



+ (LocationBlurView *) loadLocationFilter:(UIView *) view {
    LocationBlurView *blur = [[[NSBundle mainBundle] loadNibNamed:@"LocationBlurView" owner:nil options:nil] objectAtIndex:0];
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
        snapshot=[snapshot applyBlurWithRadius:8 tintColor:[BeagleUtilities returnBeagleColor:9] saturationDeltaFactor:1.8 maskImage:nil];
        
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


@end