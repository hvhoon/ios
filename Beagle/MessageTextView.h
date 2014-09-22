//
//  MessageTextView.h
//  Beagle
//
//  Created by Kanav Gupta on 9/17/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "DismissiveTextView.h"

@interface MessageTextView : DismissiveTextView
@property (copy, nonatomic) NSString *placeHolder;
@property (strong, nonatomic) UIColor *placeHolderTextColor;
- (NSUInteger)numberOfLinesOfText;
+ (NSUInteger)maxCharactersPerLine;
+ (NSUInteger)numberOfLinesForMessage:(NSString *)text;

@end
