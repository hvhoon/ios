//
//  LocationBlurView.h
//  Beagle
//
//  Created by Kanav Gupta on 14/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol LocationBlurViewDelegate <NSObject>

@optional
- (void)dismissEventFilter;
@end
@interface LocationBlurView : UIView
@property(nonatomic,assign)id<LocationBlurViewDelegate>delegate;
+ (LocationBlurView *) loadLocationFilter:(UIView *) view;
- (void) unload;
- (void) crossDissolveShow;
- (void) crossDissolveHide;
- (void) blurWithColor;

@end
