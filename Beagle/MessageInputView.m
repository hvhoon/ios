//
//  MessageInputView.m
//  Beagle
//
//  Created by Kanav Gupta on 9/17/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "MessageInputView.h"
#import "NSString+MessagesView.h"
#define SEND_BUTTON_WIDTH 78.0f

static id<MessageInputViewDelegate> __delegate;

@interface MessageInputView ()

- (void)setup;
- (void)setupTextView;

@end


@implementation MessageInputView
@synthesize sendButton;

#pragma mark - Initialization
- (id)initWithFrame:(CGRect)frame delegate:(id<UITextViewDelegate, MessageInputViewDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if(self) {
        __delegate = delegate;
        [self setup];
        self.textView.delegate = delegate;
    }
    return self;
}

+ (InputBarStyle)inputBarStyle
{
    return InputBarStyleFlat;
}

- (void)dealloc
{
    self.textView = nil;
    self.sendButton = nil;
}

- (BOOL)resignFirstResponder
{
    [self.textView resignFirstResponder];
    return [super resignFirstResponder];
}
#pragma mark - Setup
- (void)setup
{
    self.image = [UIImage imageNamed:@"input-bar-flat"];
    self.backgroundColor = [UIColor whiteColor];
    self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    self.opaque = YES;
    self.userInteractionEnabled = YES;
    [self setupTextView];
}

- (void)setupTextView
{
    CGFloat width = self.frame.size.width - SEND_BUTTON_WIDTH;
    CGFloat height = [MessageInputView textViewLineHeight];
    
    InputBarStyle style = [MessageInputView inputBarStyle];
    
    if (style == InputBarStyleDefault)
    {
        self.textView = [[MessageTextView  alloc] initWithFrame:CGRectMake(6.0f, 3.0f, width, height)];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.backgroundColor = [UIColor redColor];
    }
    else
    {
        self.textView = [[MessageTextView  alloc] initWithFrame:CGRectMake(8.0f, 6.0f, width, height)];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.backgroundColor = [UIColor clearColor];
        
        self.textView.layer.borderColor = [[UIColor colorWithWhite:.8 alpha:1.0] CGColor];
        self.textView.layer.borderWidth = 0.65f;
        self.textView.layer.cornerRadius = 6.0f;
    }
    
    [self addSubview:self.textView];
    
    if (style == InputBarStyleDefault)
    {
        UIImageView *inputFieldBack = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x - 1.0f,
                                                                                    0.0f,
                                                                                    self.textView.frame.size.width + 2.0f,
                                                                                    self.frame.size.height)];
        inputFieldBack.image = nil;
        inputFieldBack.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        inputFieldBack.backgroundColor = [UIColor clearColor];
        [self addSubview:inputFieldBack];
    }
}

#pragma mark - Setters
- (void)setSendButton:(UIButton *)btn
{
    if(sendButton)
        [sendButton removeFromSuperview];
    
    sendButton = btn;
    [self addSubview:self.sendButton];
}

#pragma mark - Message input view
- (void)adjustTextViewHeightBy:(CGFloat)changeInHeight
{
    CGRect prevFrame = self.textView.frame;
    
    NSInteger numLines = MAX([self.textView numberOfLinesOfText],
                       [self.textView.text numberOfLines]);
    
    NSLog(@"number line == %ld",numLines);
    
    self.textView.frame = CGRectMake(prevFrame.origin.x,
                                     prevFrame.origin.y,
                                     prevFrame.size.width,
                                     prevFrame.size.height + changeInHeight);
    
    self.textView.contentInset = UIEdgeInsetsMake((numLines >= 6 ? 4.0f : 0.0f),
                                                  0.0f,
                                                  (numLines >= 6 ? 4.0f : 0.0f),
                                                  0.0f);
    
    self.textView.scrollEnabled = (numLines >= 4);
    
    if(numLines >= 6) {
        CGPoint bottomOffset = CGPointMake(0.0f, self.textView.contentSize.height - self.textView.bounds.size.height);
        [self.textView setContentOffset:bottomOffset animated:YES];
    }
}

+ (CGFloat)textViewLineHeight
{
    return 36.0f; // for fontSize 16.0f
}

+ (CGFloat)maxLines
{
    return 4.0f;
}

+ (CGFloat)maxHeight
{
    return ([MessageInputView maxLines] + 1.0f) * [MessageInputView textViewLineHeight];
}

@end
