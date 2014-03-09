//
//  TimeFilterView.h
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TimeFilterDelegate;
@interface TimeFilterView : UIView<UIGestureRecognizerDelegate>
@property (nonatomic, assign) id<TimeFilterDelegate> delegate;
@end


@protocol TimeFilterDelegate
@optional
-(void) filterIndex:(NSInteger) index;


@end