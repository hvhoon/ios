//
//  ActivityTimeViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 02/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ActivityTimeViewControllerDelegate;
@interface ActivityTimeViewController : UIViewController
@property (assign, nonatomic) id <ActivityTimeViewControllerDelegate>delegate;
@end

@protocol ActivityTimeViewControllerDelegate<NSObject>
@optional
- (void)dismissactivityTimeFilter:(ActivityTimeViewController*)viewController;
@end
