//
//  ActivityViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BeagleActivityClass;
@interface ActivityViewController : UIViewController
@property(nonatomic,strong)BeagleActivityClass *bg_activity;
@property(nonatomic,assign)BOOL editState;
@end
