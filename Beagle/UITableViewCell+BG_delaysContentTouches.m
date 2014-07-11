//
//  UITableViewCell+BG_delaysContentTouches.m
//  Beagle
//
//  Created by Kanav Gupta on 11/07/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "UITableViewCell+BG_delaysContentTouches.h"

@implementation UITableViewCell (BG_delaysContentTouches)
- (UIScrollView*) bg_scrollView
{
    id sv = self.contentView.superview;
    while ( ![sv isKindOfClass: [UIScrollView class]] && sv != self )
    {
        sv = [sv superview];
    }
    
    return sv == self ? nil : sv;
}

- (void) setBg_delaysContentTouches:(BOOL)delaysContentTouches
{
    [self willChangeValueForKey: @"bg_delaysContentTouches"];
    
    [[self bg_scrollView] setDelaysContentTouches: delaysContentTouches];
    
    [self didChangeValueForKey: @"bg_delaysContentTouches"];
}

- (BOOL) bg_delaysContentTouches
{
    return [[self bg_scrollView] delaysContentTouches];
}
@end
