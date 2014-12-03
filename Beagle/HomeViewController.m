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
#import "BlankHomePageView.h"
#import "HomeTableViewCell.h"
#import "IconDownloader.h"
#import "DetailInterestViewController.h"
#import "BeagleUtilities.h"
#import "EventInterestFilterBlurView.h"
#import "FriendsViewController.h"
#import "ExpressInterestPreview.h"
#import "CreateAnimationBlurView.h"
#import "LinkViewController.h"
#import "BeagleLabel.h"
#define kTimerIntervalInSeconds 10
#define rowHeight 164
#define kLeaveInterest 23
#define kSuggestedPost 24
#define waitBeforeLoadingDefaultImage 20.0f
#define goldenRatio 1.6f

@interface HomeViewController ()<UITableViewDataSource,UITableViewDelegate,HomeTableViewCellDelegate,ServerManagerDelegate,IconDownloaderDelegate,BlankHomePageViewDelegate,EventInterestFilterBlurViewDelegate,InAppNotificationViewDelegate,CreateAnimationBlurViewDelegate>{
    UIView *topNavigationView;
    UIView*bottomNavigationView;
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
    CGFloat deltaAlpha;
    BOOL firstTime;
    BOOL isLoading;
    NSString *flickrCreditInfo;
    BOOL isPhotoCredit;
    NSString *photoCreditUserName;
    BOOL eventsLoadingComplete;
}
@property (nonatomic, strong) UIView* middleSectionView;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property(strong,nonatomic)ServerManager *homeActivityManager;
@property(strong,nonatomic)ServerManager *interestUpdateManager;
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
@property(strong,nonatomic)UIView *topSection;
@property(nonatomic,strong)CreateAnimationBlurView *animationBlurView;
@end

@implementation HomeViewController
@synthesize imageDownloadsInProgress;
@synthesize homeActivityManager=_homeActivityManager;
@synthesize interestUpdateManager=_interestUpdateManager;
@synthesize filterActivitiesOnHomeScreen;
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
    _tableViewController.refreshControl.tintColor=[UIColor whiteColor];
    
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
    isLoading=true;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (UpdateBadgeCount) name:kBeagleBadgeCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationUpdate:) name:kNotificationHomeAutoRefresh object:Nil];
    
    categoryFilterType=1;
    self.filterBlurView = [EventInterestFilterBlurView loadEventInterestFilter:self.view];
    self.filterBlurView.delegate=self;
    self.filterBlurView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
    self.animationBlurView.delegate=self;
    self.animationBlurView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
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
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[SettingsViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsScreen"];
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[NotificationsViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationsScreen"];
    }
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    _topSection = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, roundf([UIScreen mainScreen].bounds.size.width/goldenRatio))];
    _topSection.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_topSection];
    
    UIImageView *stockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, roundf([UIScreen mainScreen].bounds.size.width/goldenRatio))];
    stockImageView.backgroundColor = [UIColor grayColor];
    stockImageView.tag=3456;
    [_topSection addSubview:stockImageView];
    
    // Dynamic cover image height calculations!
    NSLog(@"The Header height is %f", roundf([UIScreen mainScreen].bounds.size.width/goldenRatio));
    NSLog(@"The List height is %f", [UIScreen mainScreen].bounds.size.height - roundf([UIScreen mainScreen].bounds.size.width/goldenRatio));
    NSLog(@"The Screen height is %f", roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)+ ([UIScreen mainScreen].bounds.size.height - roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)));
    
    UIImageView *topGradient=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient"]];
    topGradient.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64);
    [_topSection addSubview:topGradient];
    
    
    [self addCityName:@"Hello"];
    _timer = [NSTimer scheduledTimerWithTimeInterval:waitBeforeLoadingDefaultImage
                                              target: self
                                            selector:@selector(defaultLocalImage)
                                            userInfo: nil repeats:NO];
    
    UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [eventButton setBackgroundImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [eventButton addTarget:self action:@selector(createANewActivity:)forControlEvents:UIControlEventTouchUpInside];
    eventButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-57.0, 0.0, 57.0, 57.0);
    
    [_topSection addSubview:eventButton];
    
    // Setting up the filter pane
    _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    [_filterView addSubview:[self renderFilterHeaderView]];
    _filterView.backgroundColor=[UIColor grayColor];
    
    _tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self addChildViewController:_tableViewController];
    
    _tableViewController.refreshControl = [UIRefreshControl new];
    [_tableViewController.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    _tableViewController.tableView = self.tableView;
    
    // Setting up the table and the refresh animation
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
        [self LocationAcquired];
    }
    else{
        
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
    }
    isPushAuto=TRUE;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (updateEventsInTransitionFromBg_Fg) name:@"AutoRefreshEvents" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (refresh) name:kUpdateHomeScreenAndNotificationStack object:nil];
    [self.view insertSubview:self.tableView aboveSubview:_topSection];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor=[BeagleUtilities returnBeagleColor:2];
    
}


- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
}
-(UIView*)addPhotoCreditForFlickr:(NSString*)userName{
    
    isPhotoCredit=true;
    
    CGFloat photoCreditOriginY=self.tableView.contentSize.height+self.tableView.frame.origin.y;
    if(photoCreditOriginY<self.view.bounds.size.height){
        photoCreditOriginY=self.view.bounds.size.height;
    }
    UIView *contributorView=[[UIView alloc]initWithFrame:CGRectMake(0, photoCreditOriginY, self.view.bounds.size.width, 44.0f)];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleStockImageTap:)];
    singleTap.numberOfTapsRequired = 1;
    [contributorView addGestureRecognizer:singleTap];
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    UILabel *photoCreditNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,0, self.view.bounds.size.width-32, 44.0f)];
    photoCreditNameLabel.backgroundColor = [UIColor clearColor];
    photoCreditNameLabel.text = [NSString stringWithFormat:@"Cover Image by %@",userName];
    photoCreditNameLabel.textColor = [BeagleUtilities returnBeagleColor:3];
    photoCreditNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    photoCreditNameLabel.textAlignment = NSTextAlignmentCenter;
    [contributorView addSubview:photoCreditNameLabel];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Cover Image by %@",userName]];
    [attributedString beginEditing];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f]
                             range:NSMakeRange(15,[userName length])];
    [attributedString endEditing];
    photoCreditNameLabel.attributedText = attributedString;
    return contributorView;
    
}

-(void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
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
                        
                        if(notification.notificationType==GOING_TYPE){
                            data.isParticipant=YES;
                        }else{
                            data.isParticipant=NO;
                        }
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
            
        case SELF_ACTIVITY_CREATION_TYPE:
        {
            NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];
            NSMutableArray *happenarnduArray=[NSMutableArray arrayWithArray:beagle_happenarndu];
            [happenarnduArray addObject:notification.activity];
            [self.filterActivitiesOnHomeScreen setObject:happenarnduArray forKey:@"beagle_happenarndu"];
            if(notification.notificationType!=JOINED_ACTIVITY_TYPE){
                
                NSArray *beagle_crtbyu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_crtbyu"];
                
                NSMutableArray *crbuArray=[NSMutableArray arrayWithArray:beagle_crtbyu];
                [crbuArray addObject:notification.activity];
                [self.filterActivitiesOnHomeScreen setObject:crbuArray forKey:@"beagle_crtbyu"];
            }
            
            NSArray *beagle_expressint=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_expressint"];
            
            NSMutableArray *exprsAray=[NSMutableArray arrayWithArray:beagle_expressint];
            [exprsAray addObject:notification.activity];
            [self.filterActivitiesOnHomeScreen setObject:exprsAray forKey:@"beagle_expressint"];
            
        }
            break;
            
        case ACTIVITY_CREATION_TYPE:
        case JOINED_ACTIVITY_TYPE:
            
        {
            
            CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:notification.activity.latitude longitude:notification.activity.longitude];
            
            CLLocationDistance kmeters = [[[BeagleManager SharedInstance]currentLocation] distanceFromLocation:oldLocation]/1000.0;
            if(kmeters/1.6<=50.0f){
                
                NSArray *beagle_happenarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_happenarndu"];
                NSMutableArray *happenarnduArray=[NSMutableArray arrayWithArray:beagle_happenarndu];
                [happenarnduArray addObject:notification.activity];
                [self.filterActivitiesOnHomeScreen setObject:happenarnduArray forKey:@"beagle_happenarndu"];
            }
            
            NSArray *beagle_friendsarndu=[self.filterActivitiesOnHomeScreen objectForKey:@"beagle_friendsarndu"];
            
            NSMutableArray *friendsarnduArray=[NSMutableArray arrayWithArray:beagle_friendsarndu];
            [friendsarnduArray addObject:notification.activity];
            [self.filterActivitiesOnHomeScreen setObject:friendsarnduArray forKey:@"beagle_friendsarndu"];
            
            
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

-(void) beginIgnoringIteractions {
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
}
-(void) endIgnoringInteractions {
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
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
    
    if(headerView==nil ||notificationsButton==nil)
        return;
    if(BG.badgeCount==0){
        
        UIButton *notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [notificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
        [notificationsButton setBackgroundImage:[UIImage imageNamed:@"Bell-(No-Notications)"] forState:UIControlStateNormal];
        notificationsButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-48, 0, 44, 44);
        notificationsButton.alpha = 0.6;
        notificationsButton.tag=5346;
        [headerView addSubview:notificationsButton];
        
    }
    else{
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
        
        UIButton *updateNotificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [updateNotificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
        updateNotificationsButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-44, 11, 33, 22);
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
        isPushAuto=TRUE;
        [self LocationAcquired];
        
    }
}


-(void)addCityName:(NSString*)name{
    
    UILabel *textLabel=(UILabel*)[_topSection viewWithTag:1234];
    
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
    
    [UIView transitionWithView:_topSection duration:1.0f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction) animations:^{
        [_topSection addSubview:fromLabel];
        
    } completion:NULL];
    
    
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
- (void)refresh {
    
    NSLog(@"Starting up query");
    eventsLoadingComplete=false;
    if(isPushAuto) {
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void){
            [self.tableView setContentOffset:CGPointMake(0, -1.0f) animated:NO];
            [self.tableView setContentOffset:CGPointMake(0, -_tableViewController.refreshControl.frame.size.height)];
        } completion:^(BOOL finished) {
            [_tableViewController.refreshControl beginRefreshing];
        }];
    }
    
        if(_homeActivityManager!=nil){
                _homeActivityManager.delegate = nil;
                _homeActivityManager = nil;
            }
    _homeActivityManager=[[ServerManager alloc]init];
    _homeActivityManager.delegate=self;
    [_homeActivityManager getActivities];
    
}

-(void)defaultLocalImage{
    
    [self crossDissolvePhotos:[UIImage imageNamed:@"defaultLocation"] withUrl:nil userInfo:nil];
    
}
-(void)createANewActivity:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
    [self presentViewController:activityNavigationController animated:YES completion:nil];
    
}
- (void) retrieveLocationAndUpdateBackgroundPhoto {
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    flickrCreditInfo = @"";
    isPhotoCredit=false;
    NSLog(@"Getting ready to update the cover image");
    
    // Setup string to get weather conditions
    NSString *urlString=[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&APPID=%@",BG.placemark.location.coordinate.latitude,BG.placemark.location.coordinate.longitude, openWeatherAPIKey];
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"Weather request:%@", urlString);
#if 1
    NSURL *url=[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];

    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = [AFJSONResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *weather=@"Clear";
        NSString *time=@"d";
        
        NSDictionary *current_observation=[responseObject objectForKey:@"weather"];
        
        // Parsing out the weather and time of day info.
        for(id mainWeather in current_observation) {
            weather=[mainWeather objectForKey:@"main"];
            time=[mainWeather objectForKey:@"icon"];
        }
        
        // Parsing and playing God :)
        // Get rid of any clouds!
        if ([weather rangeOfString:@"Clouds"].location != NSNotFound) {
            weather = @"Clear";
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
#if 1
        // Pull image from Flickr
        [[BGFlickrManager sharedManager] randomPhotoRequest:^(FlickrRequestInfo * flickrRequestInfo, NSError * error) {
            
            if(!error) {
                [self crossDissolvePhotos:flickrRequestInfo.photo withUrl:[flickrRequestInfo.userPhotoWebPageURL absoluteString] userInfo:flickrRequestInfo.userInfo];
            }
            else {
                
                [[BGFlickrManager sharedManager] defaultStockPhoto:^(UIImage * photo) {
                    [self crossDissolvePhotos:photo withUrl:[flickrRequestInfo.userPhotoWebPageURL absoluteString] userInfo:flickrRequestInfo.userInfo];
                }];
                
            }

            // Add the city name and the filter pane to the top section
            [self addCityName:[BG.placemark.addressDictionary objectForKey:@"City"]];
            [self.tableView reloadData];
            
        }];
        
#endif
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Image error: %@", error);
    }];
    [requestOperation start];
#endif
}


- (void) crossDissolvePhotos:(UIImage *) photo withUrl:(NSString *)title userInfo:(NSString*)userInfo{
    
    [self.timer invalidate];
    flickrCreditInfo=title;
    NSLog(@"userInfo=%@",userInfo);
    
    if([userInfo length]!=0){
        photoCreditUserName=userInfo;
    }
    
    UIColor *dominantColor = [BeagleUtilities getDominantColor:photo];
    BeagleManager *BG=[BeagleManager SharedInstance];
    BG.lightDominantColor=[BeagleUtilities returnLightColor:[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.9] withWhiteness:0.7];
    BG.mediumDominantColor=[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.5];
    BG.darkDominantColor=[BeagleUtilities returnShadeOfColor:dominantColor withShade:0.4];
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"HourlyUpdate"];
    
    _filterView.backgroundColor = [BG.mediumDominantColor colorWithAlphaComponent:0.8];
    _topSection.backgroundColor = BG.mediumDominantColor;
    isLoading=FALSE;
    
    [UIView transitionWithView:_topSection duration:1.0f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction) animations:^{
        
        UIImageView *stockImageView=(UIImageView*)[self.view viewWithTag:3456];
        stockImageView.image=photo;
        [stockImageView setContentMode:UIViewContentModeScaleAspectFill];
        
    } completion:^(BOOL finished){
        [self showPhotoCreditNameWithAnimation];
    }];
}
-(void)showPhotoCreditNameWithAnimation{
    
    [UIView animateWithDuration:1.0f
                          delay:0.0
                        options: UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{if(eventsLoadingComplete){
        if([photoCreditUserName length]!=0){
            self.tableView.tableFooterView=[self addPhotoCreditForFlickr:photoCreditUserName];
        }else{
            self.tableView.tableFooterView=nil;
        }
    }}
                     completion:nil];
    
}
-(void)handleStockImageTap:(UITapGestureRecognizer*)sender{
    if([flickrCreditInfo length]!=0)
        [self redirectToWebPage:flickrCreditInfo];
}
-(UIView*)renderFilterHeaderView {
    
    UIView *headerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
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
        notificationsButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-48, 0, 44, 44);
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
            updateNotificationsButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-48, 0, 44, 44);
            
        }
        else{
            updateNotificationsButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-48, 0, 44, 44);
            
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
        return roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)-44-64;
    else{
        return 44.0f;
        
    }
    
}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    if(indexPath.section==1 && [self.tableData count]>0){
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        style.lineBreakMode=NSLineBreakByWordWrapping;
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                               [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];
        
        BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString :play.activityDesc  attributes : attrs];
        
        CGFloat height=[BeagleUtilities heightForAttributedStringWithEmojis:attributedString forWidth:[UIScreen mainScreen].bounds.size.width-32];
        
        
        if(play.activityType==2){
            play.heightRow=rowHeight+(int)height+23+kHeightClip;
            return rowHeight+(int)height+23+kHeightClip;
        }
        
        // If there are no participants, reduce the size of the card
        if (play.participantsCount==0) {
            play.heightRow=rowHeight+(int)height+kHeightClip;
            return rowHeight+(int)height+kHeightClip;
        }
        play.heightRow=rowHeight+16+20+(int)height+kHeightClip;
        return rowHeight+16+20+(int)height+kHeightClip;
    }else if (indexPath.section==1 && [self.tableData count]==0){
        return ([UIScreen mainScreen].bounds.size.height - roundf([UIScreen mainScreen].bounds.size.width/goldenRatio));
    }
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    if(section==0){
        UIView *translucentView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        translucentView.backgroundColor=[UIColor clearColor];
        translucentView.tag=9765;
        translucentView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)-44-64);
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleStockImageTap:)];
        singleTap.numberOfTapsRequired = 1;
        [translucentView addGestureRecognizer:singleTap];
        
        return translucentView;
        
    }else{
        return _filterView;
    }
    
    
}

#define DISABLED_ALPHA 0.5f
#if 0
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    if([self.tableData count]>0){
        
        HomeTableViewCell *cell = [[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellEditingStyleNone;
        
        BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
        
        cell.delegate=self;
        cell.cellIndex=indexPath.row;
        
        cell.bg_activity = play;
#if 0
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
#endif
        [cell setNeedsDisplay];
        return cell;
        
    }else{
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellEditingStyleNone;
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BlankHomePageView" owner:self options:nil];
        BlankHomePageView *blankHomePageView=[nib objectAtIndex:0];
        
        blankHomePageView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-roundf([UIScreen mainScreen].bounds.size.width/goldenRatio));
        blankHomePageView.delegate=self;
        blankHomePageView.userInteractionEnabled=YES;
        blankHomePageView.tag=1245;
        [cell.contentView addSubview:blankHomePageView];
        return cell;
        
    }
    return nil;
}

#else
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if([self.tableData count]>0){
        
        int fromTheTop = 0;
        CGFloat organizerName_y=60.0f;

        static NSString *CellIdentifier = @"MediaTableCell";
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsZero;
        
        BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
        
        cell.backgroundColor = [UIColor whiteColor];
        
        // Setting up the card (background)
        UIView *_backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, fromTheTop, [UIScreen mainScreen].bounds.size.width, 400)];
        _backgroundView.backgroundColor=[UIColor whiteColor];

        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        
        // Drawing the time label
        [style setAlignment:NSTextAlignmentLeft];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Bold" size:11.0f], NSFontAttributeName,
                               [BeagleUtilities returnBeagleColor:12],NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];
        
        
        if(play.activityType==2){
            
            CGSize suggestedBySize = [@"SUGGESTED POST" boundingRectWithSize:CGSizeMake(288, 999)
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:attrs
                                                                     context:nil].size;

            UILabel *suggestedPostLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,10,suggestedBySize.width,suggestedBySize.height)];
            suggestedPostLabel.backgroundColor = [UIColor clearColor];
            suggestedPostLabel.text = @"SUGGESTED POST";
            suggestedPostLabel.textColor = [BeagleUtilities returnBeagleColor:12];
            suggestedPostLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:11.0f];
            suggestedPostLabel.textAlignment = NSTextAlignmentLeft;
            [_backgroundView addSubview:suggestedPostLabel];

            fromTheTop += suggestedBySize.height+10;
            organizerName_y=organizerName_y+suggestedBySize.height+10;
        }


        fromTheTop = fromTheTop+10;
        
        
        // Profile picture
        UIImageView *_profileImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, fromTheTop, 52.5, 52.5)];
        [_backgroundView addSubview:_profileImageView];

#if 0
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
                
                _profileImageView.image = [BeagleUtilities imageCircularBySize:[UIImage imageNamed:@"picbox.png"] sqr:105.0f];
                
            }
            else
            {
                _profileImageView.image = [BeagleUtilities imageCircularBySize:play.profilePhotoImage sqr:105.0f];
            }
        }else{
             play.profilePhotoImage=checkImge;
            _profileImageView.image=[BeagleUtilities imageCircularBySize:play.profilePhotoImage sqr:105.0f];
        }
#endif
        if(play.activityType!=2){
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageTapped:)];
            tapRecognizer.numberOfTapsRequired = 1;
            _profileImageView.tag=indexPath.row;
            [_profileImageView addGestureRecognizer:tapRecognizer];
            [_profileImageView setUserInteractionEnabled:YES];
        }

        
        [style setAlignment:NSTextAlignmentRight];
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue" size:14.0f], NSFontAttributeName,
                 [[BeagleManager SharedInstance] darkDominantColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        // time label
        CGSize dateTextSize = [[BeagleUtilities activityTime:play.startActivityDate endate:play.endActivityDate] boundingRectWithSize:CGSizeMake(300, 999)
                                                                                                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                         attributes:attrs
                                                                                                                                            context:nil].size;
        
        
        UILabel *dateTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-16)-dateTextSize.width,
                                                                           fromTheTop,
                                                                           dateTextSize.width,dateTextSize.height)];
        dateTextLabel.backgroundColor = [UIColor clearColor];
        dateTextLabel.text = [BeagleUtilities activityTime:play.startActivityDate endate:play.endActivityDate];
        dateTextLabel.textColor = [[BeagleManager SharedInstance] darkDominantColor];
        dateTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
        dateTextLabel.textAlignment = NSTextAlignmentRight;
        [_backgroundView addSubview:dateTextLabel];
        
        
        
        // Drawing the organizer name
        [style setAlignment:NSTextAlignmentLeft];
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        CGSize organizerNameSize=[play.organizerName boundingRectWithSize:CGSizeMake(300, 999)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil].size;
        
        UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75,organizerName_y-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height)];
        organizerNameLabel.backgroundColor = [UIColor clearColor];
        organizerNameLabel.text = play.organizerName;
        organizerNameLabel.textColor = [BeagleUtilities returnBeagleColor:4];
        organizerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        organizerNameLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:organizerNameLabel];
        
        if(play.activityType!=2){
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageTapped:)];
            tapRecognizer.numberOfTapsRequired = 1;
            organizerNameLabel.tag=indexPath.row;
            [organizerNameLabel addGestureRecognizer:tapRecognizer];
            [organizerNameLabel setUserInteractionEnabled:YES];
        }

        
        // Adding the height of the profile picture
        fromTheTop += 52.5;
        
        // Adding buffer below the top section with the profile picture
        fromTheTop = fromTheTop+8;
        
        // Drawing the activity description
        style.lineBreakMode=NSLineBreakByWordWrapping;
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        
        CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width-32,999);
        
        CGRect commentTextRect = [play.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                          attributes:attrs
                                                                             context:nil];
        
        if([play.activityDesc length]!=0){
            
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString :play.activityDesc attributes : attrs];
            
            CGFloat height=[BeagleUtilities heightForAttributedStringWithEmojis:attributedString forWidth:[UIScreen mainScreen].bounds.size.width-32];
            BeagleLabel *beagleLabel = [[BeagleLabel alloc] initWithFrame:CGRectMake(16, fromTheTop, commentTextRect.size.width,height+kHeightClip) type:1];
            [beagleLabel setText:play.activityDesc];
            [beagleLabel setAttributes:attrs];
            beagleLabel.textAlignment = NSTextAlignmentLeft;
            beagleLabel.numberOfLines = 0;
            beagleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [_backgroundView addSubview:beagleLabel];
            [beagleLabel setDetectionBlock:^(BeagleHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
                if  (hotWord==BeagleLink)
                      [self redirectToWebPage:string];
                }];
            fromTheTop = fromTheTop+height+kHeightClip;
        }
        
        // Drawing the location
        [style setAlignment:NSTextAlignmentLeft];
        attrs =[NSDictionary dictionaryWithObjectsAndKeys:
                [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                style, NSParagraphStyleAttributeName, nil];
        
        CGSize locationTextSize = [play.locationName boundingRectWithSize:CGSizeMake(288, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
        
        
        fromTheTop = fromTheTop+8; // Adding buffer between the description and location
        
        UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, fromTheTop,
                                                                           locationTextSize.width, locationTextSize.height)];
        locationLabel.backgroundColor = [UIColor clearColor];
        locationLabel.text = play.locationName;
        locationLabel.textColor = [BeagleUtilities returnBeagleColor:4];
        locationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        locationLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:locationLabel];

        fromTheTop = fromTheTop+locationTextSize.height;
        fromTheTop = fromTheTop+16; // Adding space after location
        

        // Suggested post
        if(play.activityType==2){
            UIColor *outlineButtonColor = [[BeagleManager SharedInstance] darkDominantColor];
            UIButton *suggestedButton = [UIButton buttonWithType:UIButtonTypeCustom];
            suggestedButton.frame=CGRectMake(16, fromTheTop,
                                             165,33);
            suggestedButton.tag=[[NSString stringWithFormat:@"444%ld",(long)indexPath.row]integerValue];
            [suggestedButton.titleLabel setUserInteractionEnabled: NO];
            [_backgroundView addSubview:suggestedButton];
            
            
            [[suggestedButton titleLabel]setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f]];
            [suggestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            [suggestedButton setTitle:@"ASK FRIENDS NEARBY" forState:UIControlStateNormal];
            
            // Normal state
            [suggestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
            [suggestedButton setTitleColor:outlineButtonColor forState:UIControlStateNormal];
            // Pressed state
            [suggestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
            [suggestedButton setTitleColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
            
            [suggestedButton addTarget:self action:@selector(suggestedBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
            [suggestedButton setEnabled:YES];
            
        }
        else{
            
            // Drawing number of interested text
            [style setAlignment:NSTextAlignmentLeft];
            attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                   [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                   [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                   style, NSParagraphStyleAttributeName, nil];
            
            // If your friends are interested
            if(play.participantsCount>0){
                
                int countFromTheLeft = 0;
                countFromTheLeft += 16;
                
                CGSize participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)play.participantsCount]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                
                // Adding the Star image
                UIImageView *starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Star-Wireframe"]];
                starImageView.frame = CGRectMake(countFromTheLeft, fromTheTop, 17, 16);
                [_backgroundView addSubview:starImageView];
                countFromTheLeft += 17+5;

                
                // Adding the # Interested
                
                
                NSString* interestedText = [NSString stringWithFormat:@"%ld Interested", (long)play.participantsCount];
                UILabel* participantsText = [[UILabel alloc] initWithFrame:CGRectMake(countFromTheLeft, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height)];
                participantsText.attributedText = [[NSAttributedString alloc] initWithString:interestedText attributes:attrs];
                [_backgroundView addSubview:participantsText];

                countFromTheLeft += participantsCountTextSize.width+16;
                
                // If of the people interested you have friends interested
                if(play.dos1count>0) {
                    
                    NSString* relationship = nil;
                    
                    if(play.dos1count > 1)
                        relationship = @"Friends";
                    else
                        relationship = @"Friend";
                    
                    // Adding the Friend Image
                    UIImageView *dosImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DOS2-Wireframe"]];
                    dosImageView.frame = CGRectMake(countFromTheLeft, fromTheTop, 28, 16);
                    [_backgroundView addSubview:dosImageView];

                    countFromTheLeft += 28+5;
                    
                    // Adding the # of Friends
                    CGSize friendCountTextSize = [[NSString stringWithFormat:@"%ld %@",(long)play.dos1count, relationship]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                    
                    UILabel* friendsText = [[UILabel alloc] initWithFrame:CGRectMake(countFromTheLeft, fromTheTop, friendCountTextSize.width, friendCountTextSize.height)];
                    friendsText.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld %@",(long)play.dos1count, relationship] attributes:attrs];
                    [_backgroundView addSubview:friendsText];

                    countFromTheLeft +=friendCountTextSize.width+16;
                }
                
                // Adding comment count
                if(play.postCount>0) {
                    
                    // Adding the Comment icon
                    UIImageView *commentImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Comment-Wireframe"]];
                    commentImageView.frame = CGRectMake(countFromTheLeft, fromTheTop, 20, 18);
                    [_backgroundView addSubview:commentImageView];

                    countFromTheLeft +=20+5;
                    
                    // Addinf the Comment # text
                    [style setAlignment:NSTextAlignmentLeft];
                    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                             [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                             [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName, nil];
                    
                    CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)play.postCount]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                    
                    UILabel* postText = [[UILabel alloc] initWithFrame:CGRectMake(countFromTheLeft, fromTheTop, postCountTextSize.width, postCountTextSize.height)];
                    postText.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",(long)play.postCount] attributes:attrs];
                    [_backgroundView addSubview:postText];
                  }
                
                // Adding spacing after the Count section
                fromTheTop += participantsCountTextSize.height+20;
            }
            //  the Button
            UIButton *interestedButton = [UIButton buttonWithType:UIButtonTypeCustom];
            interestedButton.frame=CGRectMake(16, fromTheTop, 151, 34);
            interestedButton.tag=[[NSString stringWithFormat:@"333%ld",(long)indexPath.row]integerValue];
            UIColor *buttonColor = [[BeagleManager SharedInstance] mediumDominantColor];
            UIColor *outlineButtonColor = [[BeagleManager SharedInstance] darkDominantColor];
            [interestedButton.titleLabel setUserInteractionEnabled: NO];
            [_backgroundView addSubview:interestedButton];
            
            if(play.activityType==1){
                [interestedButton addTarget:self action:@selector(interestedBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
                [interestedButton setEnabled:YES];
            }
            else{
                [interestedButton setEnabled:NO];
            }
            
            // If it's the organizer
            if (play.dosRelation==0) {
                
                // Setup text
                [[interestedButton titleLabel]setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0f]];
                [interestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                [interestedButton setTitle:@"Created by you" forState:UIControlStateNormal];
                
                // Normal state
                [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:buttonColor] forState:UIControlStateNormal];
                [interestedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                // Pressed state
                [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:[buttonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                [interestedButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
                
                // Setting up alignments
                [interestedButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
                [interestedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
            }
            // You are not the organizer and have already expressed interest
            else if(play.dosRelation > 0 && play.isParticipant)
            {
                // Setup text
                [[interestedButton titleLabel]setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0f]];
                [interestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                [interestedButton setTitle:@"I'm Interested" forState:UIControlStateNormal];
                
                // Normal state
                [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:buttonColor] forState:UIControlStateNormal];
                [interestedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star"] withColor:[UIColor whiteColor]] forState:UIControlStateNormal];
                
                // Pressed state
                [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:[buttonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                [interestedButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
                [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star"] withColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                
                // Setting up alignments
                [interestedButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, -12.0f, 0.0f, 0.0f)];
                [interestedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
            }
            // You are not the organizer and have not expressed interest
            else {
                
                // Setup text
                [[interestedButton titleLabel]setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0f]];
                [interestedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                [interestedButton setTitle:@"I'm Interested" forState:UIControlStateNormal];
                
                // Normal state
                [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
                [interestedButton setTitleColor:outlineButtonColor forState:UIControlStateNormal];
                [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
                
                // Pressed state
                [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                [interestedButton setTitleColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
                [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                
                // Setting up alignments
                [interestedButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, -12.0f, 0.0f, 0.0f)];
                [interestedButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
            }
        }

        
        // Adding the public and invite only icons when necessary!
        // Text attributes
        [style setAlignment:NSTextAlignmentRight];
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:6],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        // Indicate if the activity is Invite only
        if([play.visibility isEqualToString:@"custom"]) {
            
            // Adding the lock image
            UIImageView *inviteOnlyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Invite-only-icon"]];
            inviteOnlyIcon.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-12-16, fromTheTop+10, 12, 15);
            [_backgroundView addSubview:inviteOnlyIcon];

            
            // Adding the # of Friends
            
            NSString* inviteText = @"Invite Only";
            CGSize inviteOnlyTextSize = [inviteText boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
            
            UILabel* inviteOnlyText = [[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-(35+inviteOnlyTextSize.width)), fromTheTop+10, inviteOnlyTextSize.width, inviteOnlyTextSize.height)];
            inviteOnlyText.attributedText = [[NSAttributedString alloc] initWithString:inviteText attributes:attrs];
            [_backgroundView addSubview:inviteOnlyText];

         }
        else if([play.visibility isEqualToString:@"public"] && play.activityType != 2) {
            
            // Adding the globe icon
            UIImageView *publicIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Public"]];
            publicIcon.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-15-16, fromTheTop+10, 15, 15);
            [_backgroundView addSubview:publicIcon];

            
            // Adding the public text
            NSString* publicText = @"Public";
            CGSize publicTextSize = [publicText boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
            
            UILabel* publicTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-(37+publicTextSize.width)), fromTheTop+9, publicTextSize.width, publicTextSize.height)];
            publicTextLabel.attributedText = [[NSAttributedString alloc] initWithString:publicText attributes:attrs];
            [_backgroundView addSubview:publicTextLabel];
       }
        else {
            // Do not add any icon!
        }
        
        // Space left after the button
        fromTheTop += 33+20;
        
        _backgroundView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, fromTheTop);
        [cell.contentView addSubview:_backgroundView];
        
        //  the card seperator
        CGRect stripRect = {0, fromTheTop, [UIScreen mainScreen].bounds.size.width, 1};

        UIView*cardSeperatorView=[[UIView alloc]initWithFrame:stripRect];
        cardSeperatorView.backgroundColor=[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
        
        [cell.contentView addSubview:cardSeperatorView];

        [cell setNeedsDisplay];
        return cell;
        
    }else{
        
      static NSString *CellIdentifier = @"BlankTableviewCell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellEditingStyleNone;
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BlankHomePageView" owner:self options:nil];
        BlankHomePageView *blankHomePageView=[nib objectAtIndex:0];
        
        blankHomePageView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-roundf([UIScreen mainScreen].bounds.size.width/goldenRatio));
        blankHomePageView.delegate=self;
        blankHomePageView.userInteractionEnabled=YES;
        blankHomePageView.tag=1245;
        [cell.contentView addSubview:blankHomePageView];
        return cell;
        
    }
    return nil;
}
#endif

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
    if(play.activityType!=2){
        [self detailedInterestScreenRedirect:indexPath.row];
    }

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

-(void)profileImageTapped:(UITapGestureRecognizer*)sender{
    
    UIView *view = sender.view;
    NSLog(@"%d", view.tag);
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:view.tag];
    if(play.dosRelation!=0){
       [self profileScreenRedirect:view.tag];
    }else{
        [self detailedInterestScreenRedirect:view.tag];
    }
}
-(void)suggestedBtnPressed:(id)sender{
    UIButton *btn=(UIButton*)sender;
    [self askNearbyFriendsToPartOfSuggestedPost:btn.tag%444];
}

-(void)interestedBtnPressed:(id)sender{
    UIButton *btn=(UIButton*)sender;
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:btn.tag%333];
    if(play.dosRelation!=0){
         [self updateInterestedStatus:btn.tag%333];
    }
    
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
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CGRect topFrame = _topSection.frame;
    
    UIImageView *stockImageView=(UIImageView*)[self.view viewWithTag:3456];
    CGRect moveTopFrame = stockImageView.frame;
    
    // Let the scrolling begin, keep track of where you are
    // If the user scrolls up, increase the opacity of the filter bar
    if (scrollView.contentOffset.y >= 0.0) {
        if (scrollView.contentOffset.y >=(roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)-44-64))
            yOffset = roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)-44-64;
        else
            yOffset = scrollView.contentOffset.y;
        
        deltaAlpha = 0.8 + (0.18 * (yOffset/(roundf([UIScreen mainScreen].bounds.size.width/goldenRatio)-44-64)));
        moveTopFrame.origin.y = -(yOffset/3);
        stockImageView.frame = moveTopFrame;
    }
    // If the user scrolls down, descrease the opacity of the filter bar
    else {
        // If the user pulls the filter bar below the cover image, increase it's opacity
        if (scrollView.contentOffset.y <=-22.0)
            yOffset = -22.0;
        // If the user just pulls down a bit, increase the opacity
        else
            yOffset = scrollView.contentOffset.y;
        
        // Always keep the height of the top section in sync with how far down the user is pulling
        topFrame.size.height = roundf([UIScreen mainScreen].bounds.size.width/goldenRatio) - (scrollView.contentOffset.y);
        _topSection.frame = topFrame;
        moveTopFrame.origin.y = 0;
        stockImageView.frame = moveTopFrame;
        deltaAlpha = 0.8 + (0.2 * (yOffset/-22.0));
    }
    
    // For testing purposes only!
    //NSLog(@"yImageFrame = %f, yOffset = %f", moveTopFrame.origin.y, yOffset);
    
    // Update the filter color appropriately if the screen is not loading for the first time!
    if (!isLoading) {
        _filterView.backgroundColor = [[[BeagleManager SharedInstance] mediumDominantColor] colorWithAlphaComponent:deltaAlpha];
        [_filterView setNeedsDisplay];
    }
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        }
            break;
    }
    [self filterByCategoryType:index];
}
- (void)dismissEventFilter{
    
}



-(void)filterByCategoryType:(NSInteger)type{
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
        
        self.tableView.scrollEnabled=YES;
    }
    else{
        self.tableView.scrollEnabled=NO;
        
    }
    if([photoCreditUserName length]!=0 && [self.tableData count]!=0){
        self.tableView.tableFooterView=[self addPhotoCreditForFlickr:photoCreditUserName];
    }else{
        self.tableView.tableFooterView=nil;
    }
    
    [self.tableView reloadData];
    
}
#pragma mark - filter  option calls
-(void)filterOptionClicked:(NSInteger)index{
    switch (index) {
        case 0:
        {
            
            firstTime=YES;
            self.tableView.tableFooterView=nil;
            [self.tableView reloadData];
            isPushAuto = true;
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
    
    
    if (play.isParticipant) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you no longer want to do this?"
                                                        message:nil
                                                       delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No",nil];
        alert.tag=kLeaveInterest;
        [alert show];
        
        
        //        [_interestUpdateManager removeMembership:play.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
    }
    else{
        [self createAnOverlayOnAUITableViewCell:[NSIndexPath indexPathForRow:index inSection:1]];
        HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:1]];
        UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)index]integerValue]];
        [button setEnabled:NO];
            if(_interestUpdateManager!=nil){
                    _interestUpdateManager.delegate = nil;
                    _interestUpdateManager = nil;
                }
        
            _interestUpdateManager=[[ServerManager alloc]init];
            _interestUpdateManager.delegate=self;
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
    ExpressInterestPreview *preview=[[ExpressInterestPreview alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, play.heightRow) orgn:play.organizerName];
    preview.tag=1374;
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f)
        [cell insertSubview:preview aboveSubview:cell];
    else
        [cell insertSubview:preview aboveSubview:cell.contentView];
    
    
    //    self.tableView.scrollEnabled=NO;
    
    [self beginIgnoringIteractions];
    
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
    [self endIgnoringInteractions];
    [self performSelector:@selector(hideView:) withObject:preview afterDelay:3.0f];
    
    
    
    
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
                         
                         //                         self.tableView.scrollEnabled=YES;
                         //                             [self endIgnoringInteractions];
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
#pragma mark redirectToWebPage method

-(void)redirectToWebPage:(NSString*)webLink{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LinkViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"webLinkScreen"];
    viewController.linkString=webLink;
    [self.navigationController pushViewController:viewController animated:YES];
    
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
                
                if(_interestUpdateManager!=nil){
                    _interestUpdateManager.delegate = nil;
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
        
        self.filterActivitiesOnHomeScreen=[[NSMutableDictionary alloc]init];
         _homeActivityManager.delegate = nil;
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
        eventsLoadingComplete=true;
        [self showPhotoCreditNameWithAnimation];
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        
        _interestUpdateManager.delegate = nil;
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
                    //                    self.tableView.scrollEnabled=YES;
                    [self endIgnoringInteractions];
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
                    //                    self.tableView.scrollEnabled=YES;
                    [self endIgnoringInteractions];
                    
                }
            }
        }
        
    }
    else if (serverRequest==kServerCallSuggestedPostMembership){
        
        _interestUpdateManager.delegate = nil;
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
        _homeActivityManager.delegate = nil;
        _homeActivityManager = nil;
        [self filterByCategoryType:categoryFilterType];
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest||serverRequest==kServerCallSuggestedPostMembership||serverRequest==kServerCallCreateActivity){
            _interestUpdateManager.delegate = nil;
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
            //            self.tableView.scrollEnabled=YES;
            [self endIgnoringInteractions];
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
        _homeActivityManager.delegate = nil;
        _homeActivityManager = nil;
        [self filterByCategoryType:categoryFilterType];
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest||serverRequest==kServerCallSuggestedPostMembership||serverRequest==kServerCallCreateActivity){
        _interestUpdateManager.delegate = nil;
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
            //        self.tableView.scrollEnabled=YES;
            [self endIgnoringInteractions];
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

