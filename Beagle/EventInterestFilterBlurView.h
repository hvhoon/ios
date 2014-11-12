//
//  EventInterestFilterBlurView.h
//  Beagle
//
//  Created by Kanav Gupta on 12/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EventInterestFilterBlurViewDelegate <NSObject>

@optional
-(void)changeInterestFilter:(NSInteger)index;
- (void)dismissEventFilter;
@end

@interface EventInterestFilterBlurView : UIView
@property(nonatomic,assign)id<EventInterestFilterBlurViewDelegate>delegate;
+ (EventInterestFilterBlurView *) loadEventInterestFilter:(UIView *) view;
- (void) unload;
- (void) crossDissolveShow;
- (void) crossDissolveHide;
- (void) blurWithColor;

@end
