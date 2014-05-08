
//
//  EventBlurView.h
//  Beagle
//
//  Created by Kanav Gupta on 08/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

@class BlurColorComponents;

@protocol EventBlurViewDelegate <NSObject>

@optional
-(void)changeTimeFilter:(NSInteger)index;
- (void)dismissactivityTimeFilter;
@end

@interface EventBlurView : UIView
@property(nonatomic,assign)id<EventBlurViewDelegate>delegate;
+ (EventBlurView *) load:(UIView *) view;
+ (EventBlurView *) loadWithLocation:(CGPoint) point parent:(UIView *) view;
- (void) unload;
- (void) crossDissolveShow;
- (void) crossDissolveHide;
- (void) blurWithColor:(BlurColorComponents *) components;
- (void) blurWithColor:(BlurColorComponents *) components updateInterval:(float) interval;

@end

@interface BlurColorComponents : NSObject

@property(nonatomic, assign) CGFloat radius;
@property(nonatomic, strong) UIColor *tintColor;
@property(nonatomic, assign) CGFloat saturationDeltaFactor;
@property(nonatomic, strong) UIImage *maskImage;

+ (BlurColorComponents *) darkEffect;


@end