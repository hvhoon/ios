//
//  CreateAnimationBlurView.h
//  Beagle
//
//  Created by Kanav Gupta on 10/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateAnimationBlurViewDelegate <NSObject>
@optional
-(void)changeVisibilityFilter:(NSInteger)index;
- (void)dismissEventFilter;
@end


@interface CreateAnimationBlurView : UIView

typedef enum {
    
	InterestCreate,
	InterestInvite
    
} BlurViewType;
@property(nonatomic,assign)BlurViewType blurType;
@property(nonatomic,assign)id<CreateAnimationBlurViewDelegate>delegate;
+ (CreateAnimationBlurView *) loadCreateAnimationView:(UIView *) view;
- (void) unload;
- (void) crossDissolveShow;
- (void) crossDissolveHide;
- (void) blurWithColor;
-(void)show;
-(void)loadDetailedInterestAnimationView:(NSString*)name;
-(void)loadCustomAnimationView:(UIImage*)pImage;
-(void)loadAnimationView:(UIImage*)pImage;
@end
