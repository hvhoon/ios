//
//  UIImage+HidingView.h
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HidingView)

@property (nonatomic) NSInteger startContentOffset;
@property (nonatomic) NSInteger lastContentOffset;

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end
