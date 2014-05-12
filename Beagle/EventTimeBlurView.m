//
//  EventBlurView.m
//  Beagle
//
//  Created by Kanav Gupta on 08/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "EventTimeBlurView.h"
#import "UIImage+ImageEffects.h"
#import "UIScreen+Screenshot.h"
#import "TimeFilterView.h"
#import "CustomPickerView.h"
@interface EventTimeBlurView ()<UIGestureRecognizerDelegate,TimeFilterDelegate,CustomPickerViewDelegate,UIScrollViewDelegate>
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, weak)  UIView *parent;
@property(nonatomic, assign) CGPoint location;
@property(nonatomic, strong) BlurColorComponents *colorComponents;
@property(nonatomic, strong) dispatch_source_t timer;

@end

@implementation EventTimeBlurView
@synthesize delegate;
- (id) initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        // make your gesture recognizer priority
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        
            
            
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame=CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _scrollView.alwaysBounceHorizontal = NO;
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        

            for (int i = 0; i < 2; i++) {
                
                switch (i) {
                    case 0:
                    {
                        TimeFilterView *filterView = [[TimeFilterView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
                        filterView.delegate=self;
                        filterView.userInteractionEnabled=YES;
                        [filterView setBackgroundColor:[UIColor clearColor]];
                        [_scrollView addSubview:filterView];
                        
                    }
                        
                        
                        
                        break;
                    case 1:
                    {
                        
                        
                        UIView *customPickerView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, self.frame.size.height)];
                        [customPickerView setBackgroundColor:[UIColor clearColor]];

                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomPickerView" owner:self options:nil];
                        CustomPickerView *view=[nib objectAtIndex:0];
                        view.frame=CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
                        view.userInteractionEnabled=YES;
                        
                        customPickerView.userInteractionEnabled=YES;
                        [_scrollView addSubview:customPickerView];
                        [customPickerView addSubview:view];
                        [view buildTheLogic];
                        view.delegate=self;
                        
                    }
                        break;
                        
                        
                    default:
                        break;
                }
                
                
            }
            _scrollView.pagingEnabled = YES;
            _scrollView.bounces=NO;
            _scrollView.userInteractionEnabled=YES;
            _scrollView.clipsToBounds=YES;
            _scrollView.contentSize = CGSizeMake(320,2*self.frame.size.height);
        
            [self addSubview:_scrollView];
            
           self.userInteractionEnabled=YES;

    }
    
    return self;
}

-(void) filterIndex:(NSInteger) index{
    
    switch (index) {
        case 0:
        {
           
            [self crossDissolveHide];
        }
            break;

         case 1:
         case 2:
         case 3:
         case 4:
         case 5:
         case 6:
         case 7:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(changeTimeFilter:)])
                [self.delegate changeTimeFilter:index];

                [self crossDissolveHide];
        }
            break;
            
        case 8:
        {
                CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
                [self.scrollView setContentOffset:bottomOffset animated:YES];

        }
            break;


    }
    
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    [self crossDissolveHide];
}
+ (EventTimeBlurView *) loadTimeFilter:(UIView *) view {
    EventTimeBlurView *blur = [[[NSBundle mainBundle] loadNibNamed:@"EventTimeBlurView" owner:nil options:nil] objectAtIndex:0];
    blur.userInteractionEnabled=YES;
    blur.parent = view;
    blur.location = CGPointMake(0, 0);
    blur.frame = CGRectMake(blur.location.x, -(blur.frame.size.height + blur.location.y), blur.frame.size.width, blur.frame.size.height);
    
    return blur;
}

+ (EventTimeBlurView *) loadWithLocation:(CGPoint) point parent:(UIView *) view {
    EventTimeBlurView *blur = [[[NSBundle mainBundle] loadNibNamed:@"EventTimeBlurView" owner:nil options:nil] objectAtIndex:0];
    
    blur.parent = view;
    blur.location = point;
    
    blur.frame = CGRectMake(0, 0, blur.frame.size.width, blur.frame.size.height);
    
    return blur;
}

- (void) awakeFromNib {
    self.scrollView.layer.cornerRadius = 1;
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

//    __block UIImage *snapshot2 = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    __block UIImage *snapshot=[UIScreen screenshot];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        snapshot=[snapshot applyBlurWithRadius:5 tintColor:self.colorComponents.tintColor saturationDeltaFactor:1.8 maskImage:nil];
        
//        snapshot = [snapshot applyBlurWithCrop:CGRectMake(self.location.x, self.location.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) resize:CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) blurRadius:self.colorComponents.radius tintColor:self.colorComponents.tintColor saturationDeltaFactor:self.colorComponents.saturationDeltaFactor maskImage:self.colorComponents.maskImage];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.backgroundColor=[UIColor colorWithPatternImage:snapshot];
        });
    });
}

- (void) blurWithColor:(BlurColorComponents *) components {
    self.colorComponents = components;
    [self blurBackground];
}

- (void) blurWithColor:(BlurColorComponents *) components updateInterval:(float) interval {
    self.colorComponents = components;
    
    self.timer = CreateDispatchTimer(interval * NSEC_PER_SEC, 1ull * NSEC_PER_SEC, dispatch_get_main_queue(), ^{[self blurWithColor:components];});
}

dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block) {
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        
        dispatch_resume(timer);
    }
    
    return timer;
}

- (void) crossDissolveShow {
    
    [self.scrollView setContentOffset:CGPointZero animated:NO];
    self.frame = CGRectMake(self.location.x, self.location.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    self.alpha =  0.0f;

    [UIView transitionWithView:self duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
            //[self blurWithColor:self.colorComponents];
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
    
    
    [UIView transitionWithView:self duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.alpha =0.0f;
    } completion:^(BOOL finished) {
        
    }];
    

}

@end

@interface BlurColorComponents()
@end

@implementation BlurColorComponents



+ (BlurColorComponents *) darkEffect {
    BlurColorComponents *components = [[BlurColorComponents alloc] init];
    
    components.radius = 5;
    components.tintColor = [UIColor colorWithRed:162.0/255.0 green:162.0/255.0 blue:162.0/255.0 alpha:0.69];
    components.saturationDeltaFactor = 1.8f;
    components.maskImage = nil;
    
    return components;
}



@end
