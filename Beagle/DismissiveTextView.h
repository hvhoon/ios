//
//  DismissiveTextView.h
//  Beagle
//
//  Created by Kanav Gupta on 9/17/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol DismissiveTextViewDelegate <NSObject>

@optional
- (void)keyboardDidShow;
- (void)keyboardDidScrollToPoint:(CGPoint)point;
- (void)keyboardWillBeDismissed;
- (void)keyboardWillSnapBackToPoint:(CGPoint)point;

@end

@interface DismissiveTextView : UITextView
@property (weak, nonatomic) id<DismissiveTextViewDelegate> keyboardDelegate;
@property (strong, nonatomic) UIPanGestureRecognizer *dismissivePanGestureRecognizer;
@end
