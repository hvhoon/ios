//
//  AppDelegate.h
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Appsee/Appsee.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate,MBProgressHUDDelegate,NSURLSessionDelegate>{
        MBProgressHUD *progressIndicator;
}
@property (nonatomic,strong)id listViewController;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong)MBProgressHUD *progressIndicator;
-(void)showProgressIndicator:(NSInteger)type;
-(void)hideProgressView;
typedef void (^CompletionHandlerType)();
#if TARGET_OS_IPHONE
@property NSMutableDictionary *completionHandlerDictionary;
#endif
- (void) addCompletionHandler: (CompletionHandlerType) handler forSession: (NSString *)identifier;
- (void) callCompletionHandlerForSession: (NSString *)identifier;
@end
