//
//  AppDelegate.h
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate,MBProgressHUDDelegate>{
        MBProgressHUD *progressIndicator;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong)MBProgressHUD *progressIndicator;
-(void)showProgressIndicator:(NSInteger)type;
-(void)hideProgressView;

@end
