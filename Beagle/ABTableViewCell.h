//
//  ABTableViewCell.h
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABTableViewCell : UITableViewCell
{
	UIView *contentView;
    
}

- (void)drawContentView:(CGRect)r; // subclasses should implement

@end
