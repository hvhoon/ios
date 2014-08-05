//
//  UIImage+HidingView.m
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "UIView+HidingView.h"
#import <objc/runtime.h>

#define ANIMATION_HIDE_BUTTONS_TIME 0.2

static char const * const ObjectTagKeyLastContentOffset = "lastContentOffset";
static char const * const ObjectTagKeyStartContentOffset = "startContentOffset";

typedef enum ScrollDirection {
    ScrollDirectionUp,
    ScrollDirectionDown
} ScrollDirection;

@implementation UIView (HidingView)

@dynamic startContentOffset;
@dynamic lastContentOffset;

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.startContentOffset = self.lastContentOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    __block BOOL wasAnimated = NO;
    ScrollDirection scrollDirection = ScrollDirectionDown;
    NSLog(@"LastOffset=%ld",self.lastContentOffset);
    
    if (self.lastContentOffset > scrollView.contentOffset.y){
        scrollDirection = ScrollDirectionUp;
        NSLog(@"up");
    }
    
    else {
        scrollDirection = ScrollDirectionDown;
                NSLog(@"down");
    }
    
    CGFloat currentOffset = scrollView.contentOffset.y;
    NSLog(@"CurrentOffset=%f",currentOffset);
    CGFloat differenceFromLast = self.lastContentOffset - currentOffset;
    NSLog(@"differenceFromLast=%f",differenceFromLast);
    self.lastContentOffset = currentOffset;
    NSLog(@"viewframeHeight=%f",self.frame.size.height);
    NSLog(@"scrollView.frame.origin.y=%f",scrollView.frame.origin.y);
    if(scrollView.contentOffset.y <= 0 && scrollView.frame.origin.y != (self.frame.size.height+64)) {
        
        scrollView.frame = CGRectMake(scrollView.bounds.origin.x,
                                      self.frame.size.height+64,
                                      scrollView.bounds.size.width,
                                      scrollView.bounds.size.height
                                      );
        
        
        self.frame = CGRectMake(self.bounds.origin.x,
                                self.bounds.origin.y,
                                self.bounds.size.width,
                                self.bounds.size.height);
        wasAnimated = YES;
        
    } else if(scrollView.contentOffset.y > 0 && scrollView.frame.origin.y != 108){
        
        scrollView.frame = CGRectMake(scrollView.bounds.origin.x,
                                      64+44,
                                      scrollView.bounds.size.width,
                                      scrollView.bounds.size.height
                                      +  self.frame.size.height-44); //minus because self.currentTableHideY is negative
        
    }
    
    if((abs(differenceFromLast)>1) && scrollView.isTracking && !wasAnimated ) {
        if(scrollDirection == ScrollDirectionDown) {
            [UIView animateWithDuration:ANIMATION_HIDE_BUTTONS_TIME
                             animations:^{
                                 
                                 UIView *middleView=(UIView*)[self viewWithTag:3457];
                                 UIView*filterView=(UIView*)[self viewWithTag:1346];
//                                 middleView.hidden=YES;
                                 
                                     middleView.frame = CGRectMake(0,
                                                                                          - middleView.bounds.size.height*2,
                                                                                          320,
                                                                                          middleView.bounds.size.height);
                                 
                                 filterView.frame = CGRectMake(0,
                                                               64,
                                                               320,
                                                               filterView.bounds.size.height);
                                 
                                 
                                 
                                 self.frame = CGRectMake(self.frame.origin.x,
                                                         self.bounds.origin.y,
                                                         self.bounds.size.width,
                                                         filterView.bounds.size.height);
                             }];
        } else {
            [UIView animateWithDuration:ANIMATION_HIDE_BUTTONS_TIME
                             animations:^{
                                 
                                 UIView *middleView=(UIView*)[self viewWithTag:3457];
                                 UIView*filterView=(UIView*)[self viewWithTag:1346];
//                                 middleView.hidden=NO;
                                 middleView.frame = CGRectMake(0,
                                                              64,
                                                              320,
                                                              middleView.bounds.size.height);
                                 
                                 filterView.frame = CGRectMake(0,
                                                               156,
                                                               320,
                                                               filterView.bounds.size.height);
                                 
                                 self.frame = CGRectMake(self.bounds.origin.x,
                                                         64,
                                                         self.bounds.size.width,
                                                         136);
                             }];
        }
    }
}


- (NSInteger)startContentOffset {
    return [objc_getAssociatedObject(self, ObjectTagKeyStartContentOffset) integerValue];
}

- (void)setStartContentOffset:(NSInteger)newObjectTag {
    objc_setAssociatedObject(self, ObjectTagKeyStartContentOffset, @(newObjectTag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)lastContentOffset {
    return [objc_getAssociatedObject(self, ObjectTagKeyLastContentOffset) integerValue];
}

- (void)setLastContentOffset:(NSInteger)newObjectTag {
    objc_setAssociatedObject(self, ObjectTagKeyLastContentOffset, @(newObjectTag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
