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
+ (UIButton *)defaultSendButton
{
    UIButton *sendButton;
    
    if ([MessageInputView inputBarStyle] == InputBarStyleFlat)
    {
        sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    }
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton setTitle:@"Send" forState:UIControlStateHighlighted];
    [sendButton setTitle:@"Send" forState:UIControlStateDisabled];
    sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);
    
    return sendButton;
}
@end
