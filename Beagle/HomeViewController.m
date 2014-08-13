//
//  HomeViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "HomeViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "Constants.h"
#import "BGFlickrManager.h"
#import "ActivityViewController.h"
#import "UIView+HidingView.h"
#import "BlankHomePageView.h"
#import "HomeTableViewCell.h"
#import "IconDownloader.h"
#import "DetailInterestViewController.h"
#import "BeagleUtilities.h"
#import "EventInterestFilterBlurView.h"
#import "FriendsViewController.h"
#import "ExpressInterestPreview.h"
#import "JSON.h"
#import "CreateAnimationBlurView.h"
#define REFRESH_HEADER_HEIGHT 70.0f
#define stockCroppingCheck 0
#define kTimerIntervalInSeconds 10
#define rowHeight 164
#define kLeaveInterest 23
#define kSuggestedPost 24
#define waitBeforeLoadingDefaultImage 20.0f

@interface HomeViewController ()<UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate,HomeTableViewCellDelegate,ServerManagerDelegate,IconDownloaderDelegate,BlankHomePageViewDelegate,EventInterestFilterBlurViewDelegate,InAppNotificationViewDelegate,CreateAnimationBlurViewDelegate>{
    UIView *topNavigationView;
    UIView*bottomNavigationView;
    BOOL footerActivated;
    ServerManager *homeActivityManager;
    NSMutableDictionary *imageDownloadsInProgress;
    NSInteger count;
    BOOL isPushAuto;
    NSInteger interestIndex;
    NSInteger categoryFilterType;
    NSMutableDictionary *filterActivitiesOnHomeScreen;
    BOOL hideInAppNotification;
    NSTimer *timer;
    NSTimer *overlayTimer;
    CGFloat yOffset;
    UIColor *dominantColorFilter;
    CGFloat deltaAlpha;
    CGFloat _headerImageYOffset;
    UIImageView *stockImageView;
    UIActivityIndicatorView *_spinner;
    BOOL isLoading;
    BOOL firstTime;
}
@property (nonatomic, strong) UIView* middleSectionView;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property(nonatomic,strong)EventInterestFilterBlurView*filterBlurView;
@property(nonatomic, strong)UIView *filterView;
@property(nonatomic, weak) NSTimer *timer;
@property(nonatomic, weak) NSTimer *overlayTimer;
@property(nonatomic,strong)  NSMutableDictionary *imageDownloadsInProgress;
@property(nonatomic,strong)  NSMutableDictionary *filterActivitiesOnHomeScreen;
@property (nonatomic, strong) NSArray *tableData;
@property(nonatomic, weak) IBOutlet UITableView*tableView;
@property(nonatomic, strong) UITableViewController*tableViewController;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;
@property(strong,nonatomic)ServerManager *homeActivityManager;
@property(strong,nonatomic)ServerManager *interestUpdateManager;
@property(strong,nonatomic)UIView *topSection;
@property(nonatomic,strong)CreateAnimationBlurView *animationBlurView;
@end

@implementation HomeViewController
@synthesize homeActivityManager=_homeActivityManager;
@synthesize imageDownloadsInProgress;
@synthesize filterActivitiesOnHomeScreen;
@synthesize interestUpdateManager=_interestUpdateManager;
@synthesize timer=_timer;
@synthesize overlayTimer=_overlayTimer;
@synthesize middleSectionView=_middleSectionView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)updateViewConstraints {
    [super updateViewConstraints];
}
- (void)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (LocationAcquired) name:kLocationUpdateReceived object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (refresh) name:kErrorToGetLocation object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableInAppNotification) name:@"ECSlidingViewTopDidAnchorLeft" object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableInAppNotification) name:@"ECSlidingViewTopDidAnchorRight" object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"HomeViewRefresh" object:Nil];

    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    if(self.tableView!=nil){
        [self.tableView reloadData];
    }
   
}

-(void)notificationUpdate:(NSNotification*)note{
        id obj1=[note valueForKey:@"userInfo"];
    if(obj1!=nil && obj1!=[NSNull class] && [[obj1 allKeys]count]!=0){
        BeagleNotificationClass *notification=[[note valueForKey:@"userInfo"]objectForKey:@"notify"];
            [self updateHomeScreen:notification];
    }
}
-(void)disableInAppNotification{
    hideInAppNotification=TRUE;
}
-(void)enableInAppNotification{
    hideInAppNotification=FALSE;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    firstTime=true;
    yOffset = 0.0;
    deltaAlpha=0.8;
    dominantColorFilter=[UIColor clearColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (UpdateBadgeCount) name:kBeagleBadgeCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationUpdate:) name:kNotificationHomeAutoRefresh object:Nil];

    categoryFilterType=1;
    self.filterBlurView = [EventInterestFilterBlurView loadEventInterestFilter:self.view];
    self.filterBlurView.delegate=self;
    
    // If it's a 3.5" screen use the bounds below
    self.filterBlurView.frame=CGRectMake(0, 0, 320, 480);
    
    // Else use these bounds for the 4" screen
    if([UIScreen mainScreen].bounds.size.height > 480.0f)
        self.filterBlurView.frame=CGRectMake(0, 0, 320, 568);

    
    self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
    self.animationBlurView.delegate=self;
    
    // If it's a 3.5" screen use the bounds below
    self.animationBlurView.frame=CGRectMake(0, 0, 320, 480);
    
    // Else use these bounds for the 4" screen
    if([UIScreen mainScreen].bounds.size.height > 480.0f)
        self.animationBlurView.frame=CGRectMake(0, 0, 320, 568);
    
    if([[[BeagleManager SharedInstance]beaglePlayer]profileData]==nil){
        
        
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl]];
        [queue addOperation:operation];
        
    }



    if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
        [[BeagleManager SharedInstance]getUserObjectInAutoSignInMode];
    }else{
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"FacebookLogin"];
        [[NSUserDefaults standardUserDefaults]synchronize];

    }
    
    
    // Setting the user name for AppSee
    NSString *firstName = [[[BeagleManager SharedInstance]beaglePlayer]first_name];
    NSString *lastName = [[[BeagleManager SharedInstance]beaglePlayer]last_name];
    NSString *userFullName = [NSString stringWithFormat:@"%@ %@",firstName, lastName];
    [Appsee setUserID:userFullName];

    if (![self.slidingViewController.underLeftViewController isKindOfClass:[SettingsViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsScreen"];
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[NotificationsViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationsScreen"];
    }
      [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
#if stockCroppingCheck
    
    topNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 64)];
    topNavigationView.backgroundColor=[UIColor grayColor];
    UIImageView *topGradient=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient"]];
    topGradient.frame = CGRectMake(0, 0, 320, 64);
    [topNavigationView addSubview:topGradient];
    [self.view addSubview:topNavigationView];
    
    _middleSectionView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 92)];
    _middleSectionView.backgroundColor=[UIColor grayColor];
    _middleSectionView.tag=3457;

#else
    _topSection = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
//    _topSection.backgroundColor=[UIColor yellowColor];
    [self.view addSubview:_topSection];
    
    stockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
    stockImageView.backgroundColor = [UIColor grayColor];
    stockImageView.tag=3456;
    stockImageView.contentMode =UIViewContentModeScaleAspectFit;// UIViewContentModeScaleAspectFill;
    [_topSection addSubview:stockImageView];
     
    UIImageView *topGradient=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient"]];
    topGradient.frame = CGRectMake(0, 0, 320, 64+50);
    [_topSection addSubview:topGradient];
    
#endif

    [self addCityName:@"Hello"];
    _timer = [NSTimer scheduledTimerWithTimeInterval:waitBeforeLoadingDefaultImage
                                                  target: self
                                                selector:@selector(defaultLocalImage)
                                                userInfo: nil repeats:NO];
    

    
    UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [eventButton setBackgroundImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [eventButton addTarget:self action:@selector(createANewActivity:)forControlEvents:UIControlEventTouchUpInside];
    eventButton.frame = CGRectMake(263.0, 0.0, 57.0, 57.0);
    
#if stockCroppingCheck
    [topNavigationView addSubview:eventButton];
#else
    [_topSection addSubview:eventButton];
#endif
    
    // Setting up the filter pane
#if stockCroppingCheck
    _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIView*headerView=[self renderFilterHeaderView];
    headerView.backgroundColor=[UIColor grayColor];
    [_filterView addSubview:headerView];
    _filterView.tag=1346;
#else
    _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [_filterView addSubview:[self renderFilterHeaderView]];
//    [_topSection addSubview:_filterView];
#endif
    
    _tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self addChildViewController:_tableViewController];
    
    _tableViewController.refreshControl = [UIRefreshControl new];
    _tableViewController.refreshControl.tintColor=[UIColor clearColor];
    [_tableViewController.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    _tableViewController.tableView = self.tableView;
    
    // Setting up the table and the refresh animation
//    self.tableView.backgroundColor=[BeagleUtilities returnBeagleColor:2];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setBackgroundColor:[UIColor clearColor]];

    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
        [self LocationAcquired];
    }
    else{
        
     [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
    }
//    isPushAuto=TRUE;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (updateEventsInTransitionFromBg_Fg) name:@"AutoRefreshEvents" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (refresh) name:kUpdateHomeScreenAndNotificationStack object:nil];
    [self.view insertSubview:self.tableView aboveSubview:_topSection];
    
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    
    self.view.backgroundColor=[BeagleUtilities returnBeagleColor:2];
    
    
    // Create the underlying imageview and offset it
    _headerImageYOffset = -50.0;
    CGRect headerImageFrame = stockImageView.frame;
    headerImageFrame.origin.y = _headerImageYOffset;
    stockImageView.frame = headerImageFrame;
    
}

- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ECSlidingViewTopDidAnchorLeft" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ECSlidingViewTopDidAnchorRight" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"HomeViewRefresh" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationUpdateReceived object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kErrorToGetLocation object:nil];

}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kBeagleBadgeCount object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUpdateHomeScreenAndNotificationStack object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AutoRefreshEvents" object:nil];
    
    for (NSIndexPath *indexPath in [imageDownloadsInProgress allKeys]) {
        IconDownloader *d = [imageDownloadsInProgress objectForKey:indexPath];
        [d cancelDownload];
    }
    self.imageDownloadsInProgress=nil;
}
- (void)didReceiveBackgroundInNotification:(NSNotification*) note{
    
    [Appsee addEvent:@"Offline Notification Received"];
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationObject:note];

    if(!hideInAppNotification && notifObject.notifType==1){
        
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
        notifView.delegate=self;
        [notifView show];

    }else if(!hideInAppNotification && notifObject.notifType==2 && (notifObject.notificationType==WHAT_CHANGE_TYPE||notifObject.notificationType==DATE_CHANGE_TYPE||notifObject.notificationType==GOING_TYPE||notifObject.notificationType==LEAVED_ACTIVITY_TYPE|| notifObject.notificationType==ACTIVITY_CREATION_TYPE || notifObject.notificationType==JOINED_ACTIVITY_TYPE||notifObject.notificationType==CANCEL_ACTIVITY_TYPE) && notifObject.activity.activityId!=0){
        if(notifObject.notificationType!=CANCEL_ACTIVITY_TYPE){
            
        NSLog(@"DetailInterestViewController redirect");
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        [viewController.interestServerManager getDetailedInterest:notifObject.activity.activityId];
        [self.navigationController pushViewController:viewController animated:YES];
        }
        [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];

    }
    if(notifObject.notifType!=2)
        [self updateHomeScreen:notifObject];


}

-(void)updateHomeScreen:(BeagleNotificationClass*)notification{
    
    switch (notification.notificationType) {
        case GOING_TYPE:
        case LEAVED_ACTIVITY_TYPE:
        case WHAT_CHANGE_TYPE:
        case DATE_CHANGE_TYPE:
        case CHAT_TYPE:
        case ACTIVITY_UPDATE_TYPE:
        {
            
            NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];

            for(BeagleActivityClass *data in beagle_happenarndu){
                if(data.activityId==notification.activity.activityId){
                    if(notification.notificationType==GOING_TYPE||notification.notificationType==LEAVED_ACTIVITY_TYPE){
                    data.participantsCount=notification.activity.participantsCount;
                    data.dos1count=notification.activity.dos1count;
                    }
                    else if(notification.notificationType==WHAT_CHANGE_TYPE||notification.notificationType==DATE_CHANGE_TYPE){
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                    }
                    else if (notification.notificationType==CHAT_TYPE){
                        data.postCount=notification.activity.postCount;
                    }
                    else if (notification.notificationType==ACTIVITY_UPDATE_TYPE){
                        data.postCount=notification.activity.postCount;
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                    }
                    break;
                }
            }
            
            NSArray *beagle_friendsarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_friendsarndu"];
            
            for(BeagleActivityClass *data in beagle_friendsarndu){
                if(data.activityId==notification.activity.activityId){
                    if(notification.notificationType==GOING_TYPE||notification.notificationType==LEAVED_ACTIVITY_TYPE){
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                    }
                    else if(notification.notificationType==WHAT_CHANGE_TYPE||notification.notificationType==DATE_CHANGE_TYPE){
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                    }
                    else if (notification.notificationType==CHAT_TYPE){
                        data.postCount=notification.activity.postCount;
                    }

                    else if (notification.notificationType==ACTIVITY_UPDATE_TYPE){
                        data.postCount=notification.activity.postCount;
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                        
                    }

                    break;
                }
            }
            NSArray *beagle_expressint=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
            
            for(BeagleActivityClass *data in beagle_expressint){
                if(data.activityId==notification.activity.activityId){
                    if(notification.notificationType==GOING_TYPE||notification.notificationType==LEAVED_ACTIVITY_TYPE){
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                    }
                    else if(notification.notificationType==WHAT_CHANGE_TYPE||notification.notificationType==DATE_CHANGE_TYPE){
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                    }
                    else if (notification.notificationType==CHAT_TYPE){
                        data.postCount=notification.activity.postCount;
                    }

                    else if (notification.notificationType==ACTIVITY_UPDATE_TYPE){
                        data.postCount=notification.activity.postCount;
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                        
                    }

                    break;
                }
            }

            NSArray *beagle_crtbyu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_crtbyu"];
            for(BeagleActivityClass *data in beagle_crtbyu){
                if(data.activityId==notification.activity.activityId){
                    if(notification.notificationType==GOING_TYPE||notification.notificationType==LEAVED_ACTIVITY_TYPE){
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                    }
                    else if(notification.notificationType==WHAT_CHANGE_TYPE||notification.notificationType==DATE_CHANGE_TYPE){
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                    }
                    else if (notification.notificationType==CHAT_TYPE){
                        data.postCount=notification.activity.postCount;
                    }
                    else if (notification.notificationType==ACTIVITY_UPDATE_TYPE){
                        data.postCount=notification.activity.postCount;
                        data.participantsCount=notification.activity.participantsCount;
                        data.dos1count=notification.activity.dos1count;
                        data.activityDesc=notification.activity.activityDesc;
                        data.endActivityDate=notification.activity.endActivityDate;
                        data.startActivityDate=notification.activity.startActivityDate;
                        
                    }

                    break;
                }
            }
            
        }
            break;
            
        case CANCEL_ACTIVITY_TYPE:
            
        {
            BOOL isFound=false;
            NSInteger index=0;
            NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];

            for(BeagleActivityClass *data in beagle_happenarndu){
                if(data.activityId==notification.activity.activityId){
                    isFound=true;
                    break;
                }else{
                    isFound=false;
                }
                index++;
            }
            if(isFound){
                NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_happenarndu];
                [oldArray removeObjectAtIndex:index];
                [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_happenarndu"];

            }
            
            isFound=false;
            index=0;
            NSArray *beagle_friendsarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_friendsarndu"];
            
            for(BeagleActivityClass *data in beagle_friendsarndu){
                if(data.activityId==notification.activity.activityId){
                    isFound=true;
                    break;
                }else{
                    isFound=false;
                }
                index++;
            }
            if(isFound){
                NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_friendsarndu];
                [oldArray removeObjectAtIndex:index];
                [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_friendsarndu"];

            }
            isFound=false;
            index=0;
            NSArray *beagle_expressint=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
            
            for(BeagleActivityClass *data in beagle_expressint){
                if(data.activityId==notification.activity.activityId){
                    isFound=true;
                    break;
                }else{
                    isFound=false;
                }
                index++;
            }
            if(isFound){
                NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_expressint];
                [oldArray removeObjectAtIndex:index];
                [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_expressint"];

            }

            isFound=false;
            index=0;
            NSArray *beagle_crtbyu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_crtbyu"];
            
            for(BeagleActivityClass *data in beagle_crtbyu){
                if(data.activityId==notification.activity.activityId){
                    isFound=true;
                    break;
                }else{
                    isFound=false;
                }
                index++;
            }
            if(isFound){
                NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_crtbyu];
                [oldArray removeObjectAtIndex:index];
                [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_crtbyu"];

            }


        }
            break;

        case ACTIVITY_CREATION_TYPE:
        case JOINED_ACTIVITY_TYPE:
        case SUGGESTED_ACTIVITY_CREATION_TYPE:
        {
            NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];
                NSMutableArray *happenarnduArray=[NSMutableArray arrayWithArray:beagle_happenarndu];
                [happenarnduArray addObject:notification.activity];
                [self.filterActivitiesOnHomeScreen setObject:happenarnduArray forKey:@"beagle_happenarndu"];

            
            if(notification.notificationType==SUGGESTED_ACTIVITY_CREATION_TYPE){
                BOOL isFound=false;
                NSInteger index=0;
                NSArray *beagle_suggestedposts=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_suggestedposts"];
                
                for(BeagleActivityClass *data in beagle_suggestedposts){
                    if(data.suggestedId==notification.activity.suggestedId){
                        isFound=true;
                        break;
                    }else{
                        isFound=false;
                    }
                    index++;
                }
                if(isFound){
                    NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_suggestedposts];
                    [oldArray removeObjectAtIndex:index];
                    [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_suggestedposts"];
                    
                }
                
            }

            
            NSArray *beagle_crtbyu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_crtbyu"];
            
            NSMutableArray *crbuArray=[NSMutableArray arrayWithArray:beagle_crtbyu];
            [crbuArray addObject:notification.activity];
            [self.filterActivitiesOnHomeScreen setObject:crbuArray forKey:@"beagle_crtbyu"];

            
            NSArray *beagle_expressint=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
            
            NSMutableArray *exprsAray=[NSMutableArray arrayWithArray:beagle_expressint];
            [exprsAray addObject:notification.activity];
            [self.filterActivitiesOnHomeScreen setObject:exprsAray forKey:@"beagle_expressint"];
            
            



        }
            break;
    }
    
    [self filterByCategoryType:categoryFilterType];

}

-(void)postInAppNotification:(NSNotification*)note{
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationForInterestPost:note];
    if(!hideInAppNotification && notifObject.notifType==1){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
        notifView.delegate=self;
        [notifView show];

        }
    else if(!hideInAppNotification && notifObject.notifType==2 && (notifObject.notificationType==CHAT_TYPE) && notifObject.activity.activityId!=0){
        NSLog(@"DetailInterestViewController redirect postInAppNotification");
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
    if(notifObject.notifType!=2)
        [self updateHomeScreen:notifObject];

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
}

-(void)UpdateBadgeCount{
    BeagleManager *BG=[BeagleManager SharedInstance];
    UIButton *notificationsButton=(UIButton*)[self.view viewWithTag:5346];
    if(notificationsButton!=nil){
        [notificationsButton removeFromSuperview];
    }

    UIView*headerView=(UIView*)[self.view viewWithTag:43567];

    if(BG.badgeCount==0){
        
            UIButton *notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [notificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
            [notificationsButton setBackgroundImage:[UIImage imageNamed:@"Bell-(No-Notications)"] forState:UIControlStateNormal];
            notificationsButton.frame = CGRectMake(272, 0, 44, 44);
            notificationsButton.alpha = 0.6;
            notificationsButton.tag=5346;
            [headerView addSubview:notificationsButton];

    }
    else{
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
            
        UIButton *updateNotificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [updateNotificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
        updateNotificationsButton.frame = CGRectMake(276, 11, 33, 22);
        [updateNotificationsButton setTitle:[NSString stringWithFormat:@"%ld",(long)BG.badgeCount] forState:UIControlStateNormal];
        [updateNotificationsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        updateNotificationsButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        updateNotificationsButton.tag=5346;
        updateNotificationsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        updateNotificationsButton.backgroundColor=[UIColor colorWithRed:231.0f/255.0f green:60.0f/255.0f blue:48.0f/255.0f alpha:0.85f];
        updateNotificationsButton.layer.cornerRadius = 4.0f;
        updateNotificationsButton.layer.masksToBounds = YES;
        [headerView addSubview:updateNotificationsButton];
        }

}
-(void)updateEventsInTransitionFromBg_Fg{
    
    CLLocation *location=[(AppDelegate *)[[UIApplication sharedApplication] delegate] currentLocation];
    CLLocationCoordinate2D coordinate=location.coordinate;
    if(coordinate.latitude==0.0f && coordinate.longitude==0.0f){
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
        return;
    }
    BOOL isSixty=[BeagleUtilities hasBeenMoreThanSixtyMinutes];
    BOOL isMoreThan50_M=[BeagleUtilities LastDistanceFromLocationExceeds_50M];
    
    if((isSixty && isMoreThan50_M)||(isSixty && !isMoreThan50_M)){
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
    }
    else if(!isSixty && isMoreThan50_M){
//        isPushAuto=TRUE;
        [self LocationAcquired];
        
    }
}


-(void)addCityName:(NSString*)name{
    UILabel *textLabel=nil;
#if stockCroppingCheck
    textLabel=(UILabel*)[topNavigationView viewWithTag:1234];
#else
    textLabel=(UILabel*)[_topSection viewWithTag:1234];
#endif
    
    if(textLabel!=nil){
        [textLabel removeFromSuperview];
    }
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // Drawing the time label
    [style setAlignment:NSTextAlignmentLeft];

    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0], NSFontAttributeName,
             [UIColor whiteColor],NSForegroundColorAttributeName,
             style, NSParagraphStyleAttributeName, nil];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect cityTextRect = [name boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil];

    
    UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(16, 0, cityTextRect.size.width, 57)];
    
    fromLabel.text = name;
    fromLabel.tag=1234;
    fromLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0];
    fromLabel.numberOfLines = 1;
    fromLabel.adjustsFontSizeToFitWidth = NO;
    fromLabel.clipsToBounds = YES;
    fromLabel.backgroundColor = [UIColor clearColor];
    fromLabel.textColor = [UIColor whiteColor];
    fromLabel.textAlignment = NSTextAlignmentLeft;
    fromLabel.alpha = 1.0;
    
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _spinner.frame = CGRectMake(25+cityTextRect.size.width,13.5,37, 37);
    _spinner.hidesWhenStopped=YES;
    [_topSection addSubview:_spinner];
    [_spinner setHidden:YES];

    
    
    [UIView transitionWithView:_topSection duration:1.0f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction) animations:^{
#if stockCroppingCheck
        [topNavigationView addSubview:fromLabel];
#else

        [_topSection addSubview:fromLabel];
#endif
        
    } completion:NULL];
    

}
- (void)refresh {
    NSLog(@"Starting up query");
    if(isLoading)
        return;
    [_spinner setHidden:NO];
    [_spinner startAnimating];
    isLoading=true;
    if(isPushAuto) {
        [_tableViewController.refreshControl beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0, -REFRESH_HEADER_HEIGHT) animated:YES];
    }
        
    if(_homeActivityManager!=nil){
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
    }
    
    _homeActivityManager=[[ServerManager alloc]init];
    _homeActivityManager.delegate=self;
    [_homeActivityManager getActivities];
    
}

-(void)LocationAcquired{
    [self refresh];
    
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    CLLocation *newLocation=[[CLLocation alloc]initWithLatitude:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude longitude:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude];
    
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if(!error) {
            BeagleManager *BG=[BeagleManager SharedInstance];
            BG.placemark=[placemarks objectAtIndex:0];
            [self retrieveLocationAndUpdateBackgroundPhoto];
        }
        else
            NSLog(@"reverseGeocodeLocation: %@", error.description);
    }];
    
}
-(void)defaultLocalImage{
    
    [self performSelector:@selector(crossDissolvePhotos:withTitle:) withObject:[UIImage imageNamed:@"defaultLocation"] withObject:nil];
    
}
-(void)createANewActivity:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
    [self presentViewController:activityNavigationController animated:YES completion:nil];
    
}
- (void) retrieveLocationAndUpdateBackgroundPhoto {
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    
    NSLog(@"Getting ready to update the cover image");
    
    // Setup string to get weather conditions
    NSString *urlString=[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&APPID=%@",BG.placemark.location.coordinate.latitude,BG.placemark.location.coordinate.longitude, openWeatherAPIKey];
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"Weather request:%@", urlString);

    NSURL *url=[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 [self performSelectorOnMainThread:@selector(weatherMapReceivedData:) withObject:data waitUntilDone:NO];
         }];
}

-(void)weatherMapReceivedData:(NSData*)data{
    
    // Pull weather information

    BeagleManager *BG=[BeagleManager SharedInstance];
    NSDictionary* weatherDictionary = [[[NSString alloc] initWithData:data
                                                    encoding:NSUTF8StringEncoding] JSONValue];

        NSString *weather=@"Clear";
        NSString *time=@"d";
        
        NSDictionary *current_observation=[weatherDictionary objectForKey:@"weather"];
        
        // Parsing out the weather and time of day info.
        for(id mainWeather in current_observation) {
            weather=[mainWeather objectForKey:@"main"];
            time=[mainWeather objectForKey:@"icon"];
        }
        
        // Figuring out whether it's day or night.
        time = [time substringFromIndex: [time length] - 1];
        time = ([time isEqualToString:@"d"]) ? @"day": @"night";
        
        // Assigning the time of day and the weather
        if (time && weather) {
            BG.timeOfDay=time;
            BG.weatherCondition=weather;
        }
    
        
        NSLog(@"Time of day: %@, Weather Conditions: %@", time, weather);
        
        // Pull image from Flickr
        [[BGFlickrManager sharedManager] randomPhotoRequest:^(FlickrRequestInfo * flickrRequestInfo, NSError * error) {
            
            
            if(!error) {
                [self crossDissolvePhotos:flickrRequestInfo.photo withTitle:flickrRequestInfo.userInfo];
            }
            else {
                
                [[BGFlickrManager sharedManager] defaultStockPhoto:^(UIImage * photo) {
                    [self crossDissolvePhotos:photo withTitle:@"Hello"];
                }];
                
            }

            // Add the city name and the filter pane to the top section
            [self addCityName:[BG.placemark.addressDictionary objectForKey:@"City"]];
            [self.tableView reloadData];
            
        }];
        
}

- (void) crossDissolvePhotos:(UIImage *) photo withTitle:(NSString *) title {
    
    [self.timer invalidate];
    UIColor *dominantColor = [BeagleUtilities getDominantColor:photo];
    dominantColorFilter=[BeagleUtilities getDominantColor:photo];
    BeagleManager *BG=[BeagleManager SharedInstance];
    BG.lightDominantColor=[BeagleUtilities returnLightColor:[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.9] withWhiteness:0.7];
    BG.mediumDominantColor=[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.5];
    BG.darkDominantColor=[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.4];
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"HourlyUpdate"];

    
        
#if stockCroppingCheck


        UIImage *stockImageTop=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 0, 320, 64) withOrientation:UIImageOrientationDownMirrored];
        topNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockImageTop];
        
        UIImage *stockImageMiddle=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 64, 320, 92) withOrientation:UIImageOrientationDownMirrored];
        UIView *sectionView=(UIView*)[self.tableView viewWithTag:3457];
        sectionView.backgroundColor=[UIColor colorWithPatternImage:stockImageMiddle];
       [sectionView setNeedsDisplay];

        UIImage *stockImageBottom=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 156, 320, 44) withOrientation:UIImageOrientationDownMirrored];
           UIView*headerView=(UIView*)[self.view viewWithTag:43567];
           headerView.backgroundColor=[[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.5] colorWithAlphaComponent:0.8];
        _filterView.backgroundColor = [UIColor colorWithPatternImage:stockImageBottom];
    
        [self.tableView reloadData];
        

        
#else
        _filterView.backgroundColor = [[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.5] colorWithAlphaComponent:0.8];
    
//    UIView*headerView=(UIView*)[self.view viewWithTag:43567];
//    headerView.backgroundColor=[[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.5] colorWithAlphaComponent:0.8];
//    [headerView setNeedsDisplay];

        [UIView transitionWithView:_topSection duration:1.0f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction) animations:^{

//        UIImageView *stockImageView=(UIImageView*)[self.view viewWithTag:3456];
        stockImageView.image=photo;
        [stockImageView setContentMode:UIViewContentModeScaleAspectFit];
        stockImageView.image = photo;
            } completion:NULL];
#endif
        
    
}

-(UIView*)renderFilterHeaderView {

    UIView *headerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    CGSize size = CGSizeMake(220,999);
    NSString* filterText = @"Happening Around You";
    
    CGRect textRect = [filterText
                       boundingRectWithSize:size
                       options:NSStringDrawingUsesLineFragmentOrigin
                       attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]}
                       context:nil];
    
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    filterButton.frame = CGRectMake(0, 0, 16+textRect.size.width+8+15, 44.0);
    filterButton.userInteractionEnabled = YES;
    filterButton.backgroundColor = [UIColor clearColor];
    filterButton.tag=3737;
    
    // Setting up the title
    [filterButton setTitle:filterText forState:UIControlStateNormal];
    filterButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [filterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [filterButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [filterButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    filterButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    
    // Setting up the filter icon
    [filterButton setImage:[UIImage imageNamed:@"Filter"] forState:UIControlStateNormal];
    filterButton.imageEdgeInsets = UIEdgeInsetsMake(2.0f, textRect.size.width+16+8, 0.0f, 0.0f);
    
    [filterButton addTarget:self action:@selector(handleFilterHeaderTap:)forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:filterButton];
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    if(BG.badgeCount==0){
        
        UIButton *notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [notificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
        [notificationsButton setBackgroundImage:[UIImage imageNamed:@"Bell-(No-Notications)"] forState:UIControlStateNormal];
        notificationsButton.frame = CGRectMake(272, 0, 44, 44);
        notificationsButton.alpha = 0.6;
        notificationsButton.tag=5346;
        [headerView addSubview:notificationsButton];
        
    }else{
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
        
        NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                             [UIFont fontWithName:@"HelveticaNeue-Medium" size:24.0f], NSFontAttributeName,
                             [UIColor whiteColor],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName, nil];
        
        CGSize badgeCountSize=[[NSString stringWithFormat:@"%ld",(long)BG.badgeCount] boundingRectWithSize:CGSizeMake(44, 999)
                                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                                                          attributes:attrs
                                                                                             context:nil].size;
        
        
        
        UIButton *updateNotificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [updateNotificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
        if(badgeCountSize.width>32.0f){
            updateNotificationsButton.frame = CGRectMake(272, 0, 44, 44);
            
        }
        else{
            updateNotificationsButton.frame = CGRectMake(272, 0, 44, 44);
            
        }
        
        updateNotificationsButton.alpha = 0.6;
        [updateNotificationsButton setTitle:[NSString stringWithFormat:@"%ld",(long)BG.badgeCount] forState:UIControlStateNormal];
        [updateNotificationsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        updateNotificationsButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        updateNotificationsButton.tag=5346;
        updateNotificationsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        updateNotificationsButton.backgroundColor=[UIColor colorWithRed:122.0f/255.0f green:122.0f/255.0f blue:122.0f/255.0f alpha:1.0f];
        
        [headerView addSubview:updateNotificationsButton];
        
        
    }

    /* Disabled in the interim
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton addTarget:self action:@selector(revealMenu:)forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setBackgroundImage:[UIImage imageNamed:@"Settings"] forState:UIControlStateNormal];
    settingsButton.frame = CGRectMake(228, 0, 44, 44);
    settingsButton.alpha = 0.6;
    [headerView addSubview:settingsButton];
    */
     headerView.tag=43567;
     return headerView;
}
-(void)handleFilterHeaderTap:(UITapGestureRecognizer*)sender{
    
    [self.filterBlurView blurWithColor];
    [self.filterBlurView crossDissolveShow];
    [self.view addSubview:self.filterBlurView];
    [Appsee addEvent:@"Filter Clicked (Home Screen)"];

}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section==0)
             return 0;
    else{
        if([self.tableData count]>0)
            return [self.tableData count];
        else if(firstTime && [self.tableData count]==0){
            return 0;
        }else{
            return 1;
        }
        
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section==0)
        return 92.0f;
    else{
        return 44.0f;
        
    }

}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    if(indexPath.section==1 && [self.tableData count]>0){
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentLeft];

    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                           [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect textRect = [play.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:attrs context:nil];
    
    if(play.activityType==2){
        play.heightRow=rowHeight+(int)textRect.size.height+23;
        return rowHeight+(int)textRect.size.height+23;
    }
    
    // If there are no participants, reduce the size of the card
    if (play.participantsCount==0) {
        play.heightRow=rowHeight+(int)textRect.size.height;
        return rowHeight+(int)textRect.size.height;
    }
    play.heightRow=rowHeight+16+20+(int)textRect.size.height;
    return rowHeight+16+20+(int)textRect.size.height;
    }else if (indexPath.section==1 && [self.tableData count]==0){
        if([UIScreen mainScreen].bounds.size.height > 480.0f)
            return 368.0f;
        else{
            return 280.0f;
        }

        
    }
     return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
        if(section==0){
            UIView *translucentView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
            translucentView.backgroundColor=[UIColor clearColor];

            translucentView.frame=CGRectMake(0, 0, 320, 92);
            return translucentView;

        }else{
            return _filterView;
        }

    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    if([self.tableData count]>0){
    
        HomeTableViewCell *cell = [[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellEditingStyleNone;
        
        BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
        
        cell.delegate=self;
        cell.cellIndexPath=indexPath;
        
        cell.bg_activity = play;
        
        UIImage*checkImge=nil;
        if(play.ownerid!=0 && play.activityType==1)
            checkImge= [BeagleUtilities loadImage:play.ownerid];
        
        if(checkImge==nil){
            
            if (!play.profilePhotoImage)
            {
                if (tableView.dragging == NO && tableView.decelerating == NO)
                {
                    [self startIconDownload:play forIndexPath:indexPath];
                }
                // if a download is deferred or in progress, return a placeholder image
                cell.photoImage = [UIImage imageNamed:@"picbox.png"];
                
            }
            else
            {
                cell.photoImage = play.profilePhotoImage;
            }
        }else{
            cell.photoImage = play.profilePhotoImage=checkImge;
        }
        [cell setNeedsDisplay];
        return cell;
        
    }else{
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellEditingStyleNone;
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BlankHomePageView" owner:self options:nil];
        BlankHomePageView *blankHomePageView=[nib objectAtIndex:0];
        
        // If it's a 3.5" screen use the bounds below
        blankHomePageView.frame=CGRectMake(0, 0, 320, 280);
        
        // Else use these bounds for the 4" screen
        if([UIScreen mainScreen].bounds.size.height > 480.0f)
            blankHomePageView.frame=CGRectMake(0, 0, 320, 368);
        
        blankHomePageView.delegate=self;
        blankHomePageView.userInteractionEnabled=YES;
        blankHomePageView.tag=1245;
        [cell.contentView addSubview:blankHomePageView];
        return cell;

    }
        return nil;
}
- (void)startIconDownload:(BeagleActivityClass*)appRecord forIndexPath:(NSIndexPath *)indexPath{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload:kParticipantInActivity];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows{
    if ([self.tableData count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            BeagleActivityClass *appRecord = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
            
            
            if (!appRecord.profilePhotoImage) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
        }
    }
    
    
}

- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];

        // Display the newly loaded image
        cell.photoImage =play.profilePhotoImage=iconDownloader.appRecord.profilePhotoImage ;
        [BeagleUtilities saveImage:iconDownloader.appRecord.profilePhotoImage withFileName:play.ownerid];
    }
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if (!decelerate)
    {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadImagesForOnscreenRows];
    if(scrollView.contentOffset.y >=170){
        deltaAlpha=1.0f;
        _filterView.backgroundColor = [[BeagleUtilities returnShadeOfColor:dominantColorFilter withShade:0.5] colorWithAlphaComponent:deltaAlpha];

    }
    if(scrollView.contentOffset.y <=0){
        deltaAlpha=0.8f;
        _filterView.backgroundColor = [[BeagleUtilities returnShadeOfColor:dominantColorFilter withShade:0.5] colorWithAlphaComponent:deltaAlpha];

    }
     */
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    // Set the y offset correctly
    if (scrollView.contentOffset.y <=0)
        yOffset = 0;
    else if(scrollView.contentOffset.y >=136)
        yOffset = 136;
    else
        yOffset = scrollView.contentOffset.y;
    
    deltaAlpha = 0.8 + (0.18 * (yOffset/136));

    // Color filter view
    _filterView.backgroundColor = [[BeagleUtilities returnShadeOfColor:dominantColorFilter withShade:0.5] colorWithAlphaComponent:deltaAlpha];
    [_filterView setNeedsDisplay];
    
    // Logs
    NSLog(@"Offset: %f, ScollView: %f, Alpha = %f", yOffset, scrollView.contentOffset.y, deltaAlpha);
    
    if (scrollView.contentOffset.y <=0) {
        UIImageView *stockImageView=(UIImageView*)[self.view viewWithTag:3456];
        [stockImageView setContentMode:UIViewContentModeScaleAspectFill];
        CGFloat scrollOffset = scrollView.contentOffset.y;
        CGRect headerImageFrame = stockImageView.frame;
        headerImageFrame.size.height = 200 - (scrollOffset);
        stockImageView.frame = headerImageFrame;
    }
    
    /*
    if (scrollView.contentOffset.y < yOffset) {
        
        // scrolls down.
        yOffset = scrollView.contentOffset.y;
        _filterView.backgroundColor = [[BeagleUtilities returnShadeOfColor:dominantColorFilter withShade:0.5] colorWithAlphaComponent:deltaAlpha];
        [_filterView setNeedsDisplay];
        deltaAlpha-=0.003;
        if(deltaAlpha<=0.8){
            deltaAlpha=0.8;
        }
        
//        NSLog(@"deltaDown=%f",deltaAlpha);

    }
    else
    {
        // scrolls up.
        yOffset = scrollView.contentOffset.y;
        _filterView.backgroundColor = [[BeagleUtilities returnShadeOfColor:dominantColorFilter withShade:0.5] colorWithAlphaComponent:deltaAlpha];
        [_filterView setNeedsDisplay];
        deltaAlpha+=0.003;
        if(deltaAlpha>=1.0f){
            deltaAlpha=1.0f;
        }
//        NSLog(@"deltaUp=%f",deltaAlpha);

    }
//    NSLog(@"scrollView.contentOffset.y=%f",scrollView.contentOffset.y);
    
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGRect headerImageFrame = stockImageView.frame;
    
    if (scrollOffset < 0) {
        // Adjust image proportionally
        headerImageFrame.origin.y = _headerImageYOffset - ((scrollOffset/3));
    } else {
        // We're scrolling up, return to normal behavior
//        headerImageFrame.origin.y = _headerImageYOffset - scrollOffset;
    }
    stockImageView.frame = headerImageFrame;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self hideSearchBarAndAnimateWithListViewInMiddle];

    
}

-(void)searchIconClicked:(id)sender{
    
    //[self showSearchBarAndAnimateWithListViewInMiddle];
}
-(void)showSearchBarAndAnimateWithListViewInMiddle{
    
    if (!footerActivated) {
		[UIView beginAnimations:@"expandFooter" context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 64;
        
        
		[bottomNavigationView setHidden:YES];
        [self.tableView setFrame:tableViewFrame];
        
        self.tableView.tableHeaderView=nil;
        
        UISearchBar *headerView = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        headerView.hidden = NO;
        headerView.delegate=self;
        self.tableView.tableHeaderView = headerView;
        headerView.showsCancelButton=YES;
        [headerView becomeFirstResponder];

		[UIView commitAnimations];
		footerActivated = YES;
	}

}

-(void)hideSearchBarAndAnimateWithListViewInMiddle{
    
    if (footerActivated) {
		[UIView beginAnimations:@"collapseFooter" context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[bottomNavigationView setHidden:NO];
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 211;
        
        [self.tableView setFrame:tableViewFrame];
		[UIView commitAnimations];
		footerActivated = NO;
	}
}

- (NSInteger)tableViewHeight
{
	[self.tableView layoutIfNeeded];
	NSInteger tableheight;
	tableheight=[self.tableView contentSize].height;
    [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:tableheight] forKey:@"height"];
	return tableheight;
}
#pragma mark - EventInterestFilterBlurView delegate calls

-(void)changeInterestFilter:(NSInteger)index{
    UIButton *headerText=(UIButton*)[self.view viewWithTag:3737];
    categoryFilterType=index;
    NSString* filterText = nil;
    CGSize size = CGSizeMake(220,999);
    
    switch (index) {
        case 1:
        {
            filterText = @"Happening Around You";
            CGRect textRect = [filterText
                               boundingRectWithSize:size
                               options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]}
                               context:nil];
            
            headerText.frame = CGRectMake(0, 0, 16+textRect.size.width+8+15, 44.0);
            [headerText setTitle:filterText forState:UIControlStateNormal];
            headerText.imageEdgeInsets = UIEdgeInsetsMake(2.0f, textRect.size.width+16+8, 0.0f, 0.0f);
            [Appsee addEvent:@"Filter changed: Happening Around You"];
        }
            break;
        case 2:
        {
            filterText = @"Created by Friends";
            CGRect textRect = [filterText
                               boundingRectWithSize:size
                               options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]}
                               context:nil];
            
            headerText.frame = CGRectMake(0, 0, 16+textRect.size.width+8+15, 44.0);
            [headerText setTitle:filterText forState:UIControlStateNormal];
            headerText.imageEdgeInsets = UIEdgeInsetsMake(2.0f, textRect.size.width+16+8, 0.0f, 0.0f);
            [Appsee addEvent:@"Filter changed: Created by Friends"];
        }
            break;
        case 3:
        {
            filterText = @"Your Interests";
            CGRect textRect = [filterText
                               boundingRectWithSize:size
                               options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]}
                               context:nil];
            
            headerText.frame = CGRectMake(0, 0, 16+textRect.size.width+8+15, 44.0);
            [headerText setTitle:filterText forState:UIControlStateNormal];
            headerText.imageEdgeInsets = UIEdgeInsetsMake(2.0f, textRect.size.width+16+8, 0.0f, 0.0f);
            [Appsee addEvent:@"Filter changed: Your Interests"];
        }
            break;
        case 4:
        {
            filterText = @"Created by You";
            CGRect textRect = [filterText
                               boundingRectWithSize:size
                               options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]}
                               context:nil];
            
            headerText.frame = CGRectMake(0, 0, 16+textRect.size.width+8+15, 44.0);
            [headerText setTitle:filterText forState:UIControlStateNormal];
            headerText.imageEdgeInsets = UIEdgeInsetsMake(2.0f, textRect.size.width+16+8, 0.0f, 0.0f);
            [Appsee addEvent:@"Filter changed: Created by You"];
        }
            break;
    }
    [self filterByCategoryType:index];
}
- (void)dismissEventFilter{
    
}



-(void)filterByCategoryType:(NSInteger)type{
    footerActivated=TRUE;
    firstTime=FALSE;
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    switch (type) {
        case 1:
        {
            NSArray *listArray=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];
            
            if([listArray count]!=0){
                listArray = [listArray sortedArrayUsingComparator: ^(BeagleActivityClass *a, BeagleActivityClass *b) {
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                    
                    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                    [dateFormatter setTimeZone:utcTimeZone];
                    
                    NSDate *s1 = [dateFormatter dateFromString:a.endActivityDate];//add the string
                    NSDate *s2 = [dateFormatter dateFromString:b.endActivityDate];
                    
                    return [s1 compare:s2];
                }];
                
                

            }
            NSArray*suggestedListArray=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_suggestedposts"];
            if([suggestedListArray count]!=0){
                
                suggestedListArray = [suggestedListArray sortedArrayUsingComparator: ^(BeagleActivityClass *a, BeagleActivityClass *b) {
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                    
                    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                    [dateFormatter setTimeZone:utcTimeZone];
                    
                    NSDate *s1 = [dateFormatter dateFromString:a.endActivityDate];//add the string
                    NSDate *s2 = [dateFormatter dateFromString:b.endActivityDate];
                    
                    return [s1 compare:s2];
                }];

                NSMutableArray *consolidateArray=[NSMutableArray new];
                if([listArray count]!=0)
                    [consolidateArray addObjectsFromArray:listArray];
                    [consolidateArray addObjectsFromArray:suggestedListArray];
                    self.tableData=[NSArray arrayWithArray:consolidateArray];
            }

            else
               self.tableData=[NSArray arrayWithArray:listArray];
        }
            break;
            
        case 2:
        {
            NSArray *listArray=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_friendsarndu"];
            
            if([listArray count]!=0){
                listArray = [listArray sortedArrayUsingComparator: ^(BeagleActivityClass *a, BeagleActivityClass *b) {
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                    
                    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                    [dateFormatter setTimeZone:utcTimeZone];
                    
                    NSDate *s1 = [dateFormatter dateFromString:a.endActivityDate];//add the string
                    NSDate *s2 = [dateFormatter dateFromString:b.endActivityDate];
                    
                    return [s1 compare:s2];
                }];
                
            }
            self.tableData=[NSArray arrayWithArray:listArray];
            
        }
            break;
            
            
        case 3:
        {
            NSArray *listArray=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
            if([listArray count]!=0){
                listArray = [listArray sortedArrayUsingComparator: ^(BeagleActivityClass *a, BeagleActivityClass *b) {
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                    
                    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                    [dateFormatter setTimeZone:utcTimeZone];
                    
                    NSDate *s1 = [dateFormatter dateFromString:a.endActivityDate];//add the string
                    NSDate *s2 = [dateFormatter dateFromString:b.endActivityDate];
                    
                    return [s1 compare:s2];
                }];
                
            }
            self.tableData=[NSArray arrayWithArray:listArray];
            
        }
            break;
            
            
        case 4:
        {
            NSArray *listArray=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_crtbyu"];
            if([listArray count]!=0){
            listArray = [listArray sortedArrayUsingComparator: ^(BeagleActivityClass *a, BeagleActivityClass *b) {
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                
                NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                [dateFormatter setTimeZone:utcTimeZone];
                
                NSDate *s1 = [dateFormatter dateFromString:a.endActivityDate];//add the string
                NSDate *s2 = [dateFormatter dateFromString:b.endActivityDate];
                
                return [s1 compare:s2];
            }];
            
            }

            self.tableData=[NSArray arrayWithArray:listArray];
            
        }
            break;
    }
    if([self.tableData count]!=0){
        
        if([self.tableData count]>=3){
            footerActivated=FALSE;
        }
            self.tableView.scrollEnabled=YES;
    }
    else{
        self.tableView.scrollEnabled=NO;
        
    }

    [self.tableView reloadData];

}
#pragma mark - filter  option calls
-(void)filterOptionClicked:(NSInteger)index{
    switch (index) {
        case 0:
        {
            // Show the table again and hide the blank view
            
            NSMutableArray *tableDataArray = [NSMutableArray arrayWithArray:self.tableData];
            
            [tableDataArray removeAllObjects];
            
            self.tableData=[NSArray arrayWithArray:tableDataArray];
            [self.tableView reloadData];
//            isPushAuto = true;

            if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
                [self LocationAcquired];
            }
            else{
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
            }

        }
            break;
        case 1:
        {
            [self.filterBlurView blurWithColor];
            [self.filterBlurView crossDissolveShow];
            [self.view addSubview:self.filterBlurView];
        }
            break;
        case 2:
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
            viewController.inviteFriends=YES;
            [self.navigationController pushViewController:viewController animated:YES];

        }
            break;
        case 3:
        {
            [self createANewActivity:self];
        }
            break;

            
    }
}






#pragma mark - detail Interest Selected 

-(void)detailedInterestScreenRedirect:(NSInteger)index{
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:index];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
    viewController.interestServerManager=[[ServerManager alloc]init];
    viewController.interestServerManager.delegate=viewController;
    [viewController.interestServerManager getDetailedInterest:play.activityId];
    viewController.interestActivity=play;
    [self.navigationController pushViewController:viewController animated:YES];
}

-(void)updateInterestedStatus:(NSInteger)index {
    
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:index];
    interestIndex=index;
    
    if(_interestUpdateManager!=nil){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
    }
    
    _interestUpdateManager=[[ServerManager alloc]init];
    _interestUpdateManager.delegate=self;
    
    if (play.isParticipant) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you no longer want to do this?"
                                                        message:nil
                                                       delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No",nil];
        alert.tag=kLeaveInterest;
        [alert show];
        [Appsee addEvent:@"Cancel Interest"];


//        [_interestUpdateManager removeMembership:play.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
    }
    else{
        [self createAnOverlayOnAUITableViewCell:[NSIndexPath indexPathForRow:index inSection:1]];
        HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:1]];
        UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)index]integerValue]];
        [button setEnabled:NO];
        [Appsee addEvent:@"Express Interest"];
        [_interestUpdateManager participateMembership:play.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
    }
}

#pragma mark - Mutual Friends Redirect
-(void)profileScreenRedirect:(NSInteger)index{
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:index];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
    BeagleUserClass *player=[[BeagleUserClass alloc]initWithActivityObject:play];
    viewController.friendBeagle=player;
    [self.navigationController pushViewController:viewController animated:YES];

}

-(void)createAnOverlayOnAUITableViewCell:(NSIndexPath*)indexpath {
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexpath.row];
    HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:indexpath];
    ExpressInterestPreview *preview=[[ExpressInterestPreview alloc]initWithFrame:CGRectMake(0, 0, 320, play.heightRow) orgn:play.organizerName];
    preview.tag=1374;
    [cell insertSubview:preview aboveSubview:cell.contentView];
    self.tableView.scrollEnabled=NO;
    
    // Animation
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFade];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFillMode:kCAFillModeBoth];
    [animation setDuration:0.75];
    [[cell layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];

}

-(void)showView{
    
    HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
    UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)interestIndex]integerValue]];
    [button setEnabled:YES];

    ExpressInterestPreview *preview=(ExpressInterestPreview*) [cell viewWithTag:1374];
    [preview ShowViewFromCell];
    
    // Animation
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFade];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFillMode:kCAFillModeBoth];
    [animation setDuration:0.75];
    [[cell layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];

    [self performSelector:@selector(hideView:) withObject:preview afterDelay:3];

    
    

}
-(void)hideView:(UIView*)pView{
    
    HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];

    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         [pView setAlpha:0.0];
                         [cell setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         // Completion Block

                         self.tableView.scrollEnabled=YES;
                         [self filterByCategoryType:categoryFilterType];
                         [pView removeFromSuperview];
                         
    }];

    
}

#pragma mark - askNearbyFriendsToPartOfSuggestedPost call
-(void)askNearbyFriendsToPartOfSuggestedPost:(NSInteger)index{
    
    interestIndex=index;
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                    message:@"Should we create this interest on your behalf and ask your friends in the city to join you?"
                                                   delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes, do it!",nil];
    alert.tag=kSuggestedPost;
    [alert show];
}

#pragma mark -
#pragma mark UIAlertView methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    [alertView resignFirstResponder];
    
    if (buttonIndex == 0) {
        
        switch (alertView.tag) {
            case kLeaveInterest:
            {
                if(_interestUpdateManager!=nil){
                    _interestUpdateManager.delegate = nil;
                    [_interestUpdateManager releaseServerManager];
                    _interestUpdateManager = nil;
                }
                
                _interestUpdateManager=[[ServerManager alloc]init];
                _interestUpdateManager.delegate=self;
                
                BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
                HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
                UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)interestIndex]integerValue]];
                [button setEnabled:NO];
                
                [_interestUpdateManager removeMembership:play.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
            }
                break;
                
                
        }
    }
    
    else{
        switch (alertView.tag) {
            case kSuggestedPost:
                
            {
                
                BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
                play.suggestedId=play.activityId;
                HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
                UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"444%ld",(long)index]integerValue]];
                [button setEnabled:NO];
                
                
                if([[[BeagleManager SharedInstance]beaglePlayer]profileData]==nil){
                    
                    [self.animationBlurView loadAnimationView:[UIImage imageNamed:@"picbox.png"]];
                    
                    
                }
                else{
                    [self.animationBlurView loadAnimationView:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];
                }
                

                
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
                [self.animationBlurView blurWithColor];
                [self.animationBlurView crossDissolveShow];
                [self.view addSubview:self.animationBlurView];
                
                [Appsee addEvent:@"Activate Suggested Post"];
                if(_interestUpdateManager!=nil){
                    _interestUpdateManager.delegate = nil;
                    [_interestUpdateManager releaseServerManager];
                    _interestUpdateManager = nil;
                }

                _interestUpdateManager=[[ServerManager alloc]init];
                _interestUpdateManager.delegate=self;
                
                [_interestUpdateManager updateSuggestedPostMembership:play.activityId];
                
            }
                break;
                
        }
    }
}


#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    [_tableViewController.refreshControl endRefreshing];
    
    if(serverRequest==kServerCallGetActivities){
        [_spinner stopAnimating];
        isLoading=false;

        self.filterActivitiesOnHomeScreen=[[NSMutableDictionary alloc]init];
        
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                id badge=[response objectForKey:@"badge"];
                if (badge != nil && [badge class] != [NSNull class]){
                    
                    NSLog(@"check for badge count in Home Screen=%@",badge);
                    [[BeagleManager SharedInstance]setBadgeCount:[badge integerValue]];
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[BeagleManager SharedInstance]badgeCount]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
                    
                }
                id activities=[response objectForKey:@"activities"];
                if (activities != nil && [activities class] != [NSNull class]) {
                    
                    NSArray *suggestedPosts=[activities objectForKey:@"beagle_suggestedposts"];
                    if (suggestedPosts != nil && [suggestedPosts class] != [NSNull class] && [suggestedPosts count]!=0) {
                        NSMutableArray *suggestedPostsArray=[[NSMutableArray alloc]init];
                        for(id el in suggestedPosts){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                            [suggestedPostsArray addObject:actclass];
                        }
                        
                        NSArray *suggestedListArray=[NSArray arrayWithArray:suggestedPostsArray];
                        
                        if([suggestedListArray count]!=0){
                            [self.filterActivitiesOnHomeScreen setObject:suggestedListArray forKey:@"beagle_suggestedposts"];
                            
                        }

                    }else{
                        [self.filterActivitiesOnHomeScreen setObject:[NSMutableArray new] forKey:@"beagle_suggestedposts"];
                        
                    }
                    NSArray *happenarndu=[activities objectForKey:@"beagle_happenarndu"];
                    if (happenarndu != nil && [happenarndu class] != [NSNull class] && [happenarndu count]!=0) {
                        NSMutableArray *activitiesArray=[[NSMutableArray alloc]init];
                        for(id el in happenarndu){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                            [activitiesArray addObject:actclass];
                        }
                        
                        NSArray *listArray=[NSArray arrayWithArray:activitiesArray];
                        
                        [self.filterActivitiesOnHomeScreen setObject:listArray forKey:@"beagle_happenarndu"];
                    }else{
                            [self.filterActivitiesOnHomeScreen setObject:[NSMutableArray new] forKey:@"beagle_happenarndu"];
                        }
                    
                    NSArray * friendsarndu=[activities objectForKey:@"beagle_friendsarndu"];
                    if (friendsarndu != nil && [friendsarndu class] != [NSNull class]&& [friendsarndu count]!=0) {
                        NSMutableArray *friendsAroundYouArray=[[NSMutableArray alloc]init];
                        for(id el in friendsarndu){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                            [friendsAroundYouArray addObject:actclass];
                        }
                        
                        NSArray *listArray=[NSArray arrayWithArray:friendsAroundYouArray];
                        
                        [self.filterActivitiesOnHomeScreen setObject:listArray forKey:@"beagle_friendsarndu"];
                        
                        
                    }else{
                        [self.filterActivitiesOnHomeScreen setObject:[NSMutableArray new] forKey:@"beagle_friendsarndu"];
                        
                    }
                    
                    
                    
                    
                    NSArray *expressint=[activities objectForKey:@"beagle_expressint"];
                    if (expressint != nil && [expressint class] != [NSNull class]&& [expressint count]!=0) {
                        NSMutableArray *expressInterestArray=[[NSMutableArray alloc]init];
                        for(id el in expressint){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                            [expressInterestArray addObject:actclass];
                        }
                        
                        NSArray *listArray=[NSArray arrayWithArray:expressInterestArray];
                        
                        [self.filterActivitiesOnHomeScreen setObject:listArray forKey:@"beagle_expressint"];
                        
                        
                    }
                    
                    else{
                        [self.filterActivitiesOnHomeScreen setObject:[NSMutableArray new] forKey:@"beagle_expressint"];
                        
                    }
                    
                    
                    NSArray * crtbyu=[activities objectForKey:@"beagle_crtbyu"];
                    if (crtbyu != nil && [crtbyu class] != [NSNull class]&& [crtbyu count]!=0) {
                        NSMutableArray *createdByYouArray=[[NSMutableArray alloc]init];
                        for(id el in crtbyu){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                            [createdByYouArray addObject:actclass];
                        }
                        
                        NSArray *listArray=[NSArray arrayWithArray:createdByYouArray];
                        
                        [self.filterActivitiesOnHomeScreen setObject:listArray forKey:@"beagle_crtbyu"];
                        
                        
                    }
                    
                    else{
                        [self.filterActivitiesOnHomeScreen setObject:[NSMutableArray new] forKey:@"beagle_crtbyu"];
                        
                    }
                    
                    
                    [self filterByCategoryType:categoryFilterType];
                    
                }
            }
        }
        if(isPushAuto){
            isPushAuto=FALSE;
        }
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
            
            id status=[response objectForKey:@"status"];
            id message=[response objectForKey:@"message"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                if([message isEqualToString:@"Joined"]){
                    id participantsCount=[response objectForKey:@"participantsCount"];
                    if (participantsCount != nil && [participantsCount class] != [NSNull class]){

                   play.participantsCount=[participantsCount integerValue];
                    play.isParticipant=true;
                        NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];
                        for(BeagleActivityClass *data in beagle_happenarndu){
                            if(data.activityId==play.activityId){
                                data.participantsCount=[participantsCount integerValue];
                                data.isParticipant=TRUE;
                                break;
                            }
                            
                        }
                        NSArray *beagle_friendsarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_friendsarndu"];
                        
                        for(BeagleActivityClass *data in beagle_friendsarndu){
                            if(data.activityId==play.activityId){
                                data.participantsCount=[participantsCount integerValue];
                                data.isParticipant=TRUE;
                                break;
                            }
                        }
                    BOOL isFound=FALSE;

                        NSArray *beagle_expressint=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
                        
                        for(BeagleActivityClass *data in beagle_expressint){
                            if(data.activityId==play.activityId){
                                data.participantsCount=[participantsCount integerValue];
                                data.isParticipant=TRUE;
                                 isFound=true;
                                break;
                            }
                        }
                    if(!isFound){
                        NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_expressint];
                        [oldArray addObject:play];
                        [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_expressint"];
                        
                    }
                    }
                }
                else if([message isEqualToString:@"Already Joined"]){
                    
                    HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
                    UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)interestIndex]integerValue]];
                    [button setEnabled:YES];

                    ExpressInterestPreview *preview=(ExpressInterestPreview*) [cell viewWithTag:1374];
                    [preview removeFromSuperview];
                    self.tableView.scrollEnabled=YES;
                    NSString *message = NSLocalizedString (@"You have already joined.",
                                                           @"Already Joined");
                    BeagleAlertWithMessage(message);
                    return;
                    
                }
                else{
                    id participantsCount=[response objectForKey:@"participantsCount"];
                    if (participantsCount != nil && [participantsCount class] != [NSNull class]){

                    play.isParticipant=FALSE;
                   play.participantsCount=[participantsCount integerValue];
                    NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];
                    
                    for(BeagleActivityClass *data in beagle_happenarndu){
                        if(data.activityId==play.activityId){
                            data.participantsCount=[participantsCount integerValue];
                            data.isParticipant=FALSE;
                            break;
                        };
                    }
                    NSArray *beagle_friendsarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_friendsarndu"];
                    
                    for(BeagleActivityClass *data in beagle_friendsarndu){
                        if(data.activityId==play.activityId){
                            data.participantsCount=[participantsCount integerValue];
                            data.isParticipant=FALSE;
                            break;
                        }
                    }
                    NSArray *beagle_expressint=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
                    BOOL isFound=FALSE;
                    NSInteger index=0;
                    
                    for(BeagleActivityClass *data in beagle_expressint){
                        if(data.activityId==play.activityId){
                            data.participantsCount=[participantsCount integerValue];
                            data.isParticipant=FALSE;
                            isFound=true;

                            break;
                        }
                        index++;
                    }
                    
                    if(isFound){
                        NSMutableArray *oldArray=[NSMutableArray arrayWithArray:beagle_expressint];
                        [oldArray removeObjectAtIndex:index];
                        [self.filterActivitiesOnHomeScreen setObject:oldArray forKey:@"beagle_expressint"];
                     }
                    }
                }
                if(play.isParticipant){
                    [self showView];

                }else{
                    [self filterByCategoryType:categoryFilterType];
                    
                }
            }else{
                HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
                UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)interestIndex]integerValue]];
                [button setEnabled:YES];
                NSString *message = NSLocalizedString (@"That didn't quite go as planned, try again?",
                                                       @"NSURLConnection initialization method failed.");
                BeagleAlertWithMessage(message);


                if(play.isParticipant){
                    
                    ExpressInterestPreview *preview=(ExpressInterestPreview*) [cell viewWithTag:1374];
                    [preview removeFromSuperview];
                    self.tableView.scrollEnabled=YES;

                }
            }
        }
        
    }
    else if (serverRequest==kServerCallSuggestedPostMembership){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
                _interestUpdateManager=[[ServerManager alloc]init];
                _interestUpdateManager.delegate=self;
                NSArray *commaSeperated=[play.locationName componentsSeparatedByString:@","];
                if([commaSeperated count]==2){
                    play.city=[commaSeperated objectAtIndex:0];
                    play.state=[commaSeperated objectAtIndex:1];
                }
                else if([commaSeperated count]==1){
                    play.city=[commaSeperated objectAtIndex:0];
                    play.state=@"";
                    
                }
                play.visibility=@"private";
                play.activityType=1;
                [_interestUpdateManager createActivityOnBeagle:play];

            }
        }
        
        
    }else if (serverRequest==kServerCallCreateActivity){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                if(serverRequest==kServerCallCreateActivity){
                    
                    id player=[response objectForKey:@"player"];
                    if (player != nil && [status class] != [NSNull class]){

                    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
                    play.activityId=[[player objectForKey:@"id"]integerValue];
                    play.organizerName =[NSString stringWithFormat:@"%@ %@",[[[BeagleManager SharedInstance]beaglePlayer]first_name],[[[BeagleManager SharedInstance]beaglePlayer]last_name]];
                    play.dosRelation = 0;
                    play.dos1count = 0;
                    play.participantsCount = 0;
                    play.isParticipant=1;
                    play.postCount = 0;
                    play.activityType=1;
                    play.ownerid=[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId];
                    play.photoUrl=[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl];
                    play.profilePhotoImage=[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]];
                    }
                    
                    [self.animationBlurView show];
                    _overlayTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                                     target: self
                                                                   selector:@selector(hideCreateOverlay)
                                                                   userInfo: nil repeats:NO];

                }
                
            }else{
                id message=[response objectForKey:@"message"];
                if (message != nil && [status class] != [NSNull class]){
                    
                        NSString *alertMessage = NSLocalizedString (@"That didn't quite go as planned, try again?",
                                                               @"NSURLConnection initialization method failed.");
                        BeagleAlertWithMessage(alertMessage);

                        [self.animationBlurView hide];
                        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                        [[UIApplication sharedApplication] setStatusBarHidden:YES];

            }
          }
        }
        
        
        
    }
}


- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    if(isPushAuto){
        isPushAuto=FALSE;
    }
    [_tableViewController.refreshControl endRefreshing];
    if(serverRequest==kServerCallGetActivities)
    {
        [_spinner stopAnimating];
        isLoading=false;

        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
        [self filterByCategoryType:categoryFilterType];
    }
    else if(serverRequest==kServerCallLeaveInterest ||serverRequest==kServerCallParticipateInterest||serverRequest==kServerCallSuggestedPostMembership||serverRequest==kServerCallCreateActivity){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        
        if(serverRequest==kServerCallCreateActivity||serverRequest==kServerCallSuggestedPostMembership){
                [self.animationBlurView hide];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];

            }

    }
    
    NSString *message = NSLocalizedString (@"That didn't quite go as planned, try again?",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
    
    if(serverRequest==kServerCallParticipateInterest||serverRequest==kServerCallLeaveInterest){
        HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
        UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)interestIndex]integerValue]];
        [button setEnabled:YES];
        if(serverRequest==kServerCallParticipateInterest){
            
            ExpressInterestPreview *preview=(ExpressInterestPreview*) [cell viewWithTag:1374];
            
            [preview removeFromSuperview];
            self.tableView.scrollEnabled=YES;
        }
    }
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    if(isPushAuto){
        isPushAuto=FALSE;
    }
    [_tableViewController.refreshControl endRefreshing];
    if(serverRequest==kServerCallGetActivities)
    {
        [_spinner stopAnimating];
        isLoading=false;

        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
        [self filterByCategoryType:categoryFilterType];
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest||serverRequest==kServerCallSuggestedPostMembership||serverRequest==kServerCallCreateActivity){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        if(serverRequest==kServerCallCreateActivity||serverRequest==kServerCallSuggestedPostMembership){
            [self.animationBlurView hide];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];

        }

    }
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
    if(serverRequest==kServerCallParticipateInterest||serverRequest==kServerCallLeaveInterest){
        HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:1]];
        UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)interestIndex]integerValue]];
        [button setEnabled:YES];
        if(serverRequest==kServerCallParticipateInterest){

        ExpressInterestPreview *preview=(ExpressInterestPreview*) [cell viewWithTag:1374];
        
        [preview removeFromSuperview];
        self.tableView.scrollEnabled=YES;
        }
    }

}
-(void)hideCreateOverlay{
    [_overlayTimer invalidate];
    [self.animationBlurView hide];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];

    BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
    notifObject.activity=play;
    notifObject.notificationType=SUGGESTED_ACTIVITY_CREATION_TYPE;
    [self updateHomeScreen:notifObject];
}
-(void)dismissCreateAnimationBlurView{
    [_overlayTimer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
    
    BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
    notifObject.activity=play;
    notifObject.notificationType=SUGGESTED_ACTIVITY_CREATION_TYPE;
    
    [self updateHomeScreen:notifObject];
}

@end

