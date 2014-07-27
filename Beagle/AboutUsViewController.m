//
//  AboutUsViewController.m
//  Beagle
//
//  Created by Harish Hoon on 7/1/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "AboutUsViewController.h"
#import "DetailInterestViewController.h"
#import "InAppNotificationView.h"
@interface AboutUsViewController ()<InAppNotificationViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *aboutUS;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation AboutUsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];

}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[BeagleManager SharedInstance] mediumDominantColor];
    [_aboutUS setTextColor:[[BeagleManager SharedInstance] lightDominantColor]];
    // Do any additional setup after loading the view.
    
}
- (void)didReceiveBackgroundInNotification:(NSNotification*) note{
    
    [Appsee addEvent:@"Offline Notification Received"];
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationObject:note];
    
    if(notifObject.notifType==1){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
        notifView.delegate=self;
        [notifView show];
    }
    else if(notifObject.notifType==2 && notifObject.activity.activityId!=0 && (notifObject.notificationType==WHAT_CHANGE_TYPE||notifObject.notificationType==DATE_CHANGE_TYPE||notifObject.notificationType==GOING_TYPE||notifObject.notificationType==LEAVED_ACTIVITY_TYPE|| notifObject.notificationType==ACTIVITY_CREATION_TYPE || notifObject.notificationType==JOINED_ACTIVITY_TYPE)){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        [viewController.interestServerManager getDetailedInterest:notifObject.activity.activityId];
        [self.navigationController pushViewController:viewController animated:YES];
        [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];
        
    }
    
    if(notifObject.notifType!=2){
        NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
        [notificationDictionary setObject:notifObject forKey:@"notify"];
        NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    
    
}


-(void)postInAppNotification:(NSNotification*)note{
    
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationForInterestPost:note];
    
    if(notifObject.notifType==1){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
        notifView.delegate=self;
        [notifView show];
    }else if(notifObject.notifType==2 && notifObject.activity.activityId!=0 && notifObject.notificationType==CHAT_TYPE){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        [viewController.interestServerManager getDetailedInterest:notifObject.activity.activityId];
        [self.navigationController pushViewController:viewController animated:YES];
        [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];

        
    }
    if(notifObject.notifType!=2){
        NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
        [notificationDictionary setObject:notifObject forKey:@"notify"];
        NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    
    
}

-(void)backgroundTapToPush:(BeagleNotificationClass *)notification{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
    viewController.interestServerManager=[[ServerManager alloc]init];
    viewController.interestServerManager.delegate=viewController;
    viewController.isRedirected=TRUE;
    if(notification.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;
    
    [viewController.interestServerManager getDetailedInterest:notification.activity.activityId];
    [self.navigationController pushViewController:viewController animated:YES];
    [BeagleUtilities updateBadgeInfoOnTheServer:notification.notificationId];

}

#pragma mark InAppNotificationView Handler
- (void)notificationView:(InAppNotificationView *)inAppNotification didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    NSLog(@"Button Index = %ld", (long)buttonIndex);
    //    [BeagleUtilities updateBadgeInfoOnTheServer:inAppNotification.notification.notificationId];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)settingsButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
