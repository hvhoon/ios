//
//  BlankHomePageView.h
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol BlankHomePageViewDelegate <NSObject>

@optional
-(void)filterOptionClicked:(NSInteger)index;
@end

@interface BlankHomePageView : UIView
@property(nonatomic,strong)id<BlankHomePageViewDelegate>delegate;
- (void)updateViewConstraints;
@end
