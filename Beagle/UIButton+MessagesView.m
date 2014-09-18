//
//  UIButton+MessagesView.m
//  Beagle
//
//  Created by Kanav Gupta on 9/17/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "UIButton+MessagesView.h"
#import "MessageInputView.h"
@implementation UIButton (MessagesView)
+ (UIButton *)defaultPostButton{
    
        UIButton *_rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
        _rightButton.titleLabel.textColor=[BeagleUtilities returnBeagleColor:13];
        [_rightButton setTitle:NSLocalizedString(@"Post", nil)
                      forState:UIControlStateNormal];
        
        return _rightButton;
}

@end
