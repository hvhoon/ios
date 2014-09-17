//
//  MessageInputView.h
//  Beagle
//
//  Created by Kanav Gupta on 9/17/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageTextView.h"
typedef enum
{
    InputBarStyleDefault,
    InputBarStyleFlat
} InputBarStyle;

@protocol MessageInputViewDelegate <NSObject>

@optional
- (InputBarStyle)inputBarStyle;

@end

@interface MessageInputView : UIImageView
@property (strong, nonatomic) MessageTextView *textView;
@property (strong, nonatomic) UIButton *sendButton;
#pragma mark - Initialization
- (id)initWithFrame:(CGRect)frame delegate:(id<UITextViewDelegate, MessageInputViewDelegate>)delegate;

#pragma mark - Message input view
- (void)adjustTextViewHeightBy:(CGFloat)changeInHeight;

+ (CGFloat)textViewLineHeight;
+ (CGFloat)maxLines;
+ (CGFloat)maxHeight;
+ (InputBarStyle)inputBarStyle;


@end
