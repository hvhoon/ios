//
//  NSString+MessagesView.h
//  Beagle
//
//  Created by Kanav Gupta on 9/17/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MessagesView)
- (NSString *)trimWhitespace;
- (NSUInteger)numberOfLines;

@end
