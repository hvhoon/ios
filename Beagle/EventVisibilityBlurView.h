//
//  EventVisibilityBlurView.h
//  Beagle
//
//  Created by Kanav Gupta on 09/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


@protocol EventVisibilityBlurViewDelegate <NSObject>

@optional
-(void)changeVisibilityFilter:(NSInteger)index;
- (void)dismissEventFilter;
@end


@interface EventVisibilityBlurView : UIView
@property(nonatomic,assign)id<EventVisibilityBlurViewDelegate>delegate;
+ (EventVisibilityBlurView *) loadVisibilityFilter:(UIView *) view;
- (void) unload;
- (void) crossDissolveShow;
- (void) crossDissolveHide;
- (void) blurWithColor;

@end

