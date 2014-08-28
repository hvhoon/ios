//
//  CustomPickerView.h
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CustomPickerViewDelegate;
@interface CustomPickerView : UIView
@property (nonatomic, assign) id<CustomPickerViewDelegate> delegate;
-(void)buildTheLogic;
-(void)updateTheDateInEditMode;
@end
@protocol CustomPickerViewDelegate<NSObject>
@optional
-(void) filterIndex:(NSInteger) index;
-(void) datePicked:(NSDate*)dateSelected;
-(void)slideUpToSelectTime;
@end