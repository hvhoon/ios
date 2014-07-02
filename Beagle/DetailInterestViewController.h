//
//  DetailInterestViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BeagleActivityClass;
@interface DetailInterestViewController : UIViewController<ServerManagerDelegate>
@property(nonatomic,strong)BeagleActivityClass*interestActivity;
@property(nonatomic,strong)ServerManager*interestServerManager;
@property(nonatomic,assign)BOOL isRedirected;
@property(nonatomic,assign)BOOL toLastPost;
@end
