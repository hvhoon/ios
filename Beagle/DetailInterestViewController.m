//
//  DetailInterestViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "DetailInterestViewController.h"
#import "BeaglePlayerScrollMenu.h"
#import "PlayerProfileItem.h"
#import "InterestChatClass.h"
#import "HomeTableViewCell.h"
#import "MessageKeyboardView.h"
#import "IconDownloader.h"
#import "ActivityViewController.h"
#import "PostSoundEffect.h"
#import "FriendsViewController.h"
#import "FeedbackReporting.h"
#import "CreateAnimationBlurView.h"
#define DISABLED_ALPHA 0.5f
#define kLeaveInterest 12
static NSString * const CellIdentifier = @"cell";
@interface DetailInterestViewController ()<BeaglePlayerScrollMenuDelegate,ServerManagerDelegate,UIGestureRecognizerDelegate,UITableViewDelegate,UITableViewDataSource,IconDownloaderDelegate,InAppNotificationViewDelegate,UIAlertViewDelegate,MessageKeyboardViewDelegate,UIGestureRecognizerDelegate,CreateAnimationBlurViewDelegate>{
    BOOL scrollViewResize;
    UIActivityIndicatorView *activityIndicatorView;
    BOOL postsLoadComplete;
    NSTimer *timer;
    UIImageView *_partcipantScrollArrowImageView;
}

@property(nonatomic,strong)ServerManager*chatPostManager;
@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@property (strong, nonatomic) UIImageView *profileImageView;
@property (strong,nonatomic)BeaglePlayerScrollMenu *scrollMenu;
@property(nonatomic,strong)ServerManager*interestUpdateManager;
@property(nonatomic,strong)NSMutableArray *chatPostsArray;
@property(nonatomic,strong)UITableView *detailedInterestTableView;
@property (nonatomic, strong) MessageKeyboardView *contentWrapper;
@property (nonatomic, strong) UIProgressView* sendMessage;
@property(nonatomic,strong)CreateAnimationBlurView *animationBlurView;
@end

@implementation DetailInterestViewController
@synthesize interestActivity,interestServerManager=_interestServerManager ;
@synthesize scrollMenu=_scrollMenu;
@synthesize imageDownloadsInProgress;
@synthesize interestUpdateManager=_interestUpdateManager;
@synthesize profileImageView=_profileImageView;
@synthesize chatPostManager=_chatPostManager;
@synthesize chatPostsArray;
@synthesize isRedirected,toLastPost,inappNotification;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (getPostsUpdateInBackground) name:kUpdatePostsOnInterest object:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar setTintColor:[[BeagleManager SharedInstance] darkDominantColor]];

    BeagleManager *BG=[BeagleManager SharedInstance];
    if(BG.activityDeleted){
        BG.activityDeleted=FALSE;
        [self.navigationController popViewControllerAnimated:NO];
        return;
    }
    
    // Setup the progress indicator
    _sendMessage = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, 320, 1)];
    [_sendMessage setProgressTintColor:[BeagleUtilities returnBeagleColor:13]];
    [self.view addSubview:_sendMessage];
    [_sendMessage setHidden:YES];
    
    scrollViewResize=TRUE;
    NSString* screenTitle = [BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:self.interestActivity.endActivityDate];
    self.navigationItem.title = screenTitle;
    [self.detailedInterestTableView reloadData];
    
}
-(void)viewDidAppear:(BOOL)animated{
    [self.contentWrapper _registerForNotifications];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUpdatePostsOnInterest object:nil];
    [self.contentWrapper _unregisterForNotifications];
    
    
}
-(void)getPostsUpdateInBackground{
    
    if(_chatPostManager!=nil){
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
    }
    
    _chatPostManager=[[ServerManager alloc]init];
    _chatPostManager.delegate=self;
    if([self.chatPostsArray count]!=0){
        [_chatPostManager getMoreBackgroundPostsForAnInterest:[self.chatPostsArray lastObject] activId:self.interestActivity.activityId];
        
    }else{
        [_chatPostManager getNewBackgroundPostsForAnInterest:self.interestActivity.activityId];
    }

}

- (void)didReceiveBackgroundInNotification:(NSNotification*) note{
    
    [Appsee addEvent:@"Offline Notification Received"];
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationObject:note];
    
    if(notifObject.notifType!=2){
    NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
    [notificationDictionary setObject:notifObject forKey:@"notify"];
    NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    if(notifObject.activity.activityId==self.interestActivity.activityId && (notifObject.notificationType==WHAT_CHANGE_TYPE || notifObject.notificationType==DATE_CHANGE_TYPE||notifObject.notificationType==CANCEL_ACTIVITY_TYPE)){

        //do the description and text update
        if(notifObject.notificationType!=CANCEL_ACTIVITY_TYPE){
 
            if(notifObject.notifType==1){
                if(![self.navigationItem.rightBarButtonItem.title isEqualToString:@"Done"]){
                InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
                notifView.delegate=self;
                [notifView show];
                }
                else{
                    [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];
                    
                }
            }
        self.interestActivity.startActivityDate=notifObject.activity.startActivityDate;
        self.interestActivity.endActivityDate=notifObject.activity.endActivityDate;
        NSString* screenTitle = [BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:notifObject.activity.endActivityDate];
        self.navigationItem.title = screenTitle;
        self.interestActivity.activityDesc=notifObject.activity.activityDesc;
        scrollViewResize=TRUE;
        [self.detailedInterestTableView reloadData];
        }else{

            

            NSString *message = NSLocalizedString (@"This activity has been cancelled, let's show you what else is happening around you",
                                                   @"Cancel Activity Type");

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            alert.tag=1467;
            [alert show];
            [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];


        }

    }else if(notifObject.activity.activityId==self.interestActivity.activityId){
        
        if(notifObject.notifType==1){
            if(![self.navigationItem.rightBarButtonItem.title isEqualToString:@"Done"]){
                InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
                notifView.delegate=self;
                [notifView show];
            }
            else{
                [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];
                
            }
        }

    if(notifObject.notificationType==LEAVED_ACTIVITY_TYPE){

        
        BeagleUserClass *userObject=[[BeagleUserClass alloc]init];
        userObject.profileImageUrl=notifObject.photoUrl;
        userObject.first_name=notifObject.playerName;
        userObject.beagleUserId=notifObject.referredId;
        self.interestActivity.participantsCount=notifObject.activity.participantsCount;
        UILabel *participantsCountTextLabel=(UILabel*)[self.view viewWithTag:347];

        if(notifObject.activity.dosRelation==1){
            self.interestActivity.dos1count=notifObject.activity.dos1count;
            NSString* relationship = @"Friend";
            UILabel *friendCountTextLabel=(UILabel*)[self.view viewWithTag:348];
            
            if(self.interestActivity.dos1count > 1) relationship = @"Friends";
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested", (long)self.interestActivity.participantsCount];
            friendCountTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)self.interestActivity.dos1count, relationship];

        }else{
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];

        }
        
        NSMutableArray *testArray=[NSMutableArray new];
        for(BeagleUserClass *data in self.interestActivity.participantsArray){
            if(data.beagleUserId!=userObject.beagleUserId){
                
                [testArray addObject:data];
            }
        }
        self.interestActivity.participantsArray=testArray;
        scrollViewResize=YES;
        [self.detailedInterestTableView reloadData];


        
    }
    else if(notifObject.notificationType==GOING_TYPE){
        BeagleUserClass *userObject=[[BeagleUserClass alloc]init];
        userObject.profileImageUrl=notifObject.photoUrl;
        userObject.first_name=notifObject.playerName;
        userObject.beagleUserId=notifObject.referredId;
        
        self.interestActivity.participantsCount=notifObject.activity.participantsCount;
        UILabel *participantsCountTextLabel=(UILabel*)[self.view viewWithTag:347];

        if(notifObject.activity.dosRelation==1){
            self.interestActivity.dos1count=notifObject.activity.dos1count;
            NSString* relationship = @"Friend";
            UILabel *friendCountTextLabel=(UILabel*)[self.view viewWithTag:348];
            
            if(self.interestActivity.dos1count > 1) relationship = @"Friends";
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested", (long)self.interestActivity.participantsCount];
            friendCountTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)self.interestActivity.dos1count, relationship];
        }
        else{
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];

        }
            NSMutableArray*interestArray=[NSMutableArray new];
            
            if([self.interestActivity.participantsArray count]!=0){
                [interestArray addObject:userObject];
                [interestArray addObjectsFromArray:self.interestActivity.participantsArray];
                self.interestActivity.participantsArray=interestArray;
            }else{
                [interestArray addObject:userObject];
                self.interestActivity.participantsArray=interestArray;
            }
        scrollViewResize=YES;
        [self.detailedInterestTableView reloadData];
        
    }

    
    }
    else if(notifObject.notifType==1){
        
    
        if(![self.navigationItem.rightBarButtonItem.title isEqualToString:@"Done"]){
            InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
            notifView.delegate=self;
            [notifView show];
        }
        
    }
    

    
}


-(void)postInAppNotification:(NSNotification*)note{
    
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationForInterestPost:note];
    
    if(notifObject.activity.activityId==self.interestActivity.activityId && notifObject.notificationType==CHAT_TYPE){
        
        
        if(_chatPostManager!=nil){
            _chatPostManager.delegate = nil;
            [_chatPostManager releaseServerManager];
            _chatPostManager = nil;
        }
        
        _chatPostManager=[[ServerManager alloc]init];
        _chatPostManager.delegate=self;
        [_chatPostManager getPostDetail:notifObject.postChatId];
   }

 else if(notifObject.notifType==1){
    
    if(![self.navigationItem.rightBarButtonItem.title isEqualToString:@"Done"]){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
        notifView.delegate=self;
        [notifView show];
    }
    NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
    [notificationDictionary setObject:notifObject forKey:@"notify"];
    NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    }
    
    
}
-(void)backgroundTapToPush:(BeagleNotificationClass *)notification{
    
    if(notification.activity.activityId!=self.interestActivity.activityId){
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
    viewController.interestServerManager=[[ServerManager alloc]init];
    viewController.interestServerManager.delegate=viewController;
    viewController.isRedirected=TRUE;
    if(notification.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;

    [viewController.interestServerManager getDetailedInterest:notification.activity.activityId];
    [self.navigationController pushViewController:viewController animated:YES];
    }
    [BeagleUtilities updateBadgeInfoOnTheServer:notification.notificationId];

}

#pragma mark InAppNotificationView Handler
- (void)notificationView:(InAppNotificationView *)inAppNotification didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    NSLog(@"Button Index = %ld", (long)buttonIndex);
    [BeagleUtilities updateBadgeInfoOnTheServer:inAppNotification.notification.notificationId];
}

-(void)backButtonClicked:(id)sender{
    [self.contentWrapper.inputView.textView resignFirstResponder];
    [self.view endEditing:YES];
    [self.contentWrapper.inputView.textView setText:nil];
    [self.contentWrapper.dummyInputView.textView setText:nil];
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)cancelButtonClicked:(id)sender{
    [self.contentWrapper.inputView.textView resignFirstResponder];
    [self.view endEditing:YES];
    [self.contentWrapper.inputView.textView setText:nil];
    [self.contentWrapper.dummyInputView.textView setText:nil];
    [self dismissViewControllerAnimated:YES completion:Nil];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.topItem.title = @"";

    self.automaticallyAdjustsScrollViewInsets = NO;
    if(!isRedirected)
      [self createInterestInitialCard];

}

-(void)createInterestInitialCard{
    
    self.interestActivity.participantsArray=[[NSMutableArray alloc]init];
    if(self.interestActivity.dosRelation==0){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
        
    }else{
        
        self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
        self.animationBlurView.delegate=self;
        
        // If it's a 3.5" screen use the bounds below
        self.animationBlurView.frame=CGRectMake(0, 0, 320, 480);
        
        // Else use these bounds for the 4" screen
        if([UIScreen mainScreen].bounds.size.height > 480.0f)
            self.animationBlurView.frame=CGRectMake(0, 0, 320, 568);
        
        [self.animationBlurView loadDetailedInterestAnimationView:self.interestActivity.organizerName];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flag" style:UIBarButtonItemStylePlain target:self action:@selector(flagButtonClicked:)];
        
    }
    
    if(inappNotification){
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClicked:)];
        
    }
    // Set the screen title.
    NSString* screenTitle = [BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:self.interestActivity.endActivityDate];
    self.navigationItem.title = screenTitle;
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [BeagleUtilities returnBeagleColor:4]}];
    
    self.detailedInterestTableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                                  style:UITableViewStylePlain];
    self.detailedInterestTableView.dataSource = self;
    self.detailedInterestTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.detailedInterestTableView.separatorInset = UIEdgeInsetsZero;
    self.detailedInterestTableView.delegate = self;
    self.detailedInterestTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.detailedInterestTableView setBackgroundColor:[BeagleUtilities returnBeagleColor:2]];
    self.contentWrapper = [[MessageKeyboardView alloc] initWithScrollView:self.detailedInterestTableView];
    self.contentWrapper.interested=YES;
     if(!self.interestActivity.isParticipant)
         self.contentWrapper.interested=NO;
    self.contentWrapper.frame = self.view.bounds;
    self.contentWrapper.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.contentWrapper.delegate=self;
    [self.view addSubview:self.contentWrapper];
    self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
    [self.contentWrapper.inputView.rightButton addTarget:self action:@selector(postClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if(!self.interestActivity.isParticipant){
        [self.contentWrapper.inputView setHidden:YES];
        [self.contentWrapper.dummyInputView setHidden:YES];
    }

}


#pragma mark -
#pragma mark Show/Hide Delegate Method

- (void)show{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonClicked:)];
    
    self.navigationItem.hidesBackButton = YES;
}
-(void)hide{
    
    if(self.interestActivity.dosRelation==0){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
        
    }else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flag" style:UIBarButtonItemStylePlain target:self action:@selector(flagButtonClicked:)];
        
    }

    self.navigationItem.hidesBackButton = NO;

}

-(void)doneButtonClicked:(id)sender{
    [self.contentWrapper.inputView.textView resignFirstResponder];
    [self.view endEditing:YES];
    [self.contentWrapper textViewDidChange:self.contentWrapper.inputView.textView];
    if(self.contentWrapper.inputView.textView.text.length==0)
        self.contentWrapper.dummyInputView.textView.text=@"Join the conversation";
    
    UIEdgeInsets contentInset = self.contentWrapper.scrollView.contentInset;
    contentInset.bottom = 0;
    self.contentWrapper.scrollView.contentInset = contentInset;
    
    UIEdgeInsets scrollIndicatorInsets = self.contentWrapper.scrollView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = 0;
    self.contentWrapper.scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    
    [self.detailedInterestTableView reloadData];
    [self.detailedInterestTableView beginUpdates];
    
    [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: 0 inSection:0]
                                          atScrollPosition:UITableViewScrollPositionTop
                                                  animated:YES];
    
    [self.detailedInterestTableView endUpdates];
    
    
}
-(void)flagButtonClicked:(id)sender{
    
    NSString* flagMessage = [NSString stringWithFormat:@"Please tell us why you find this activity objectionable? (Enter below):\n\n\n\n--\nFlag Report:\nActivity: %@ (%ld)\nOrganizer: %@ (%ld)", self.interestActivity.activityDesc, (long)self.interestActivity.activityId, self.interestActivity.organizerName, (long)self.interestActivity.ownerid];

    
    if ([[FeedbackReporting sharedInstance] canSendFeedback]) {
        MFMailComposeViewController* flagAnInterestController = [[FeedbackReporting sharedInstance] flagAnActivityController:flagMessage];
        [self presentViewController:flagAnInterestController animated:YES completion:Nil];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please setup your email account" message:nil
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
        
    }

}
-(void)editButtonClicked:(id)sender{
    
    [self.contentWrapper _unregisterForNotifications];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    viewController.bg_activity=self.interestActivity;
    viewController.editState=TRUE;
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
    
    [self.navigationController presentViewController:activityNavigationController animated:YES completion:nil];

}

-(void)postClicked:(id)sender{
    if([BeagleUtilities checkIfTheTextIsBlank:[self.contentWrapper.inputView.textView text]]){
        
        [Appsee addEvent:@"Post Chat"];
        
        // Gray out 'Post' button
        self.contentWrapper.inputView.rightButton.enabled = NO;
        self.contentWrapper.inputView.rightButton.tintColor = [[BeagleUtilities returnBeagleColor:13] colorWithAlphaComponent:DISABLED_ALPHA];
        
        // Show progress indicator
        [_sendMessage setProgress:0.0f];
        [_sendMessage setHidden:NO];
        [_sendMessage setProgress:0.25f animated:YES];
        
        if(_chatPostManager!=nil){
            _chatPostManager.delegate = nil;
            [_chatPostManager releaseServerManager];
            _chatPostManager = nil;
        }
        
        _chatPostManager=[[ServerManager alloc]init];
        _chatPostManager.delegate=self;
        [_chatPostManager postAComment:self.interestActivity.activityId desc:[self.contentWrapper.inputView.textView text]];
        
    }else{
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Blank Post"
                                                            message:@"I'm sure you can do better than that!"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok", nil];
            [alert show];
            
        }
    }
}

-(void)removeProgressIndicator {
    [_sendMessage setHidden:YES];
    [_sendMessage setProgress:0.0f];
}

-(void)handleTapGestures:(UITapGestureRecognizer*)sender{
    
    if(self.interestActivity.dosRelation!=0){
        if(_interestUpdateManager!=nil){
            _interestUpdateManager.delegate = nil;
            [_interestUpdateManager releaseServerManager];
            _interestUpdateManager = nil;
        }
        
        _interestUpdateManager=[[ServerManager alloc]init];
        _interestUpdateManager.delegate=self;
        
        if (self.interestActivity.isParticipant) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you no longer want to do this?"
                                                            message:nil
                                                           delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No",nil];
            alert.tag=kLeaveInterest;
            [alert show];
            [Appsee addEvent:@"Cancel Interest"];

//            [_interestUpdateManager removeMembership:self.interestActivity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
        }
        else{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
            
            [self.animationBlurView blurWithColor];
            [self.animationBlurView crossDissolveShow];
            UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
            [keyboard addSubview:self.animationBlurView];
            
            UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
            [interestedButton setEnabled:NO];
            [Appsee addEvent:@"Express Interest"];
            [_interestUpdateManager participateMembership:self.interestActivity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
        }
        
    }
  }

- (void)loadProfileImage:(NSString*)url {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    interestActivity.profilePhotoImage =[[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:interestActivity.profilePhotoImage waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:105.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)setUpPlayerScroll:(NSArray*)elements{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (BeagleUserClass * player in elements)
    {
        
		PlayerProfileItem *item = [[PlayerProfileItem alloc] initProfileItem:player.profileImageUrl
                                   
                                                label:player.first_name playerId:player.beagleUserId
                                           andAction: ^(PlayerProfileItem *item)  {
                                               
                                               NSLog(@"Block called! %ld", (long)player.beagleUserId);
                                               //DO somenthing here
                                           }];
        
		[array addObject:item];
	}
    
	[_scrollMenu setUpPlayerScrollMenu:array];
    
	//We choose an animation when the user touch the item (you can create your own animation)
	[_scrollMenu setAnimationType:PlayerZoomOut];
	_scrollMenu.delegate = self;
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    return [self.chatPostsArray count]+1;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    // For the main card section
    if(indexPath.row==0) {
        int cardHeight=0;
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
    
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                           [UIColor blackColor],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
        CGSize maximumLabelSize = CGSizeMake(288,999);
    
        CGRect textRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
        
        if(self.interestActivity.participantsCount==0)
            cardHeight=136+(int)textRect.size.height;
        else
            cardHeight=241+(int)textRect.size.height;
        
        return cardHeight;
    }
    
    else{
        {
            InterestChatClass *chatCell=[self.chatPostsArray objectAtIndex:indexPath.row-1];
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setAlignment:NSTextAlignmentLeft];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f], NSFontAttributeName,
                                   [UIColor blackColor],NSForegroundColorAttributeName,
                                   style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
            
            CGSize maximumLabelSize = CGSizeMake(245,999);
            
            CGRect textRect = [chatCell.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                            attributes:attrs
                                                                               context:nil];
            
            if(indexPath.row==1)
                return 45.0f+8.0f+textRect.size.height;
            
            return 45.0f+textRect.size.height;
        }
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // For the INFO part of the card
    if(indexPath.row==0){
        // Let's begin spacing from the top
        int fromTheTop = 10;

        static NSString *CellIdentifier = @"MediaTableCell";
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsZero;
        
        // Setting up the title of the screen
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
        
        cell.backgroundColor = [UIColor whiteColor];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                               [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];
        
        // Setting up the card (background)
        UIView *_backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, fromTheTop, 320, 400)];
        _backgroundView.backgroundColor=[UIColor whiteColor];
        
        // Profile picture
        _profileImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, fromTheTop, 52.5, 52.5)];
        [_backgroundView addSubview:_profileImageView];
        
        if(self.interestActivity.dosRelation!=0){
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageTapped:)];
            tapRecognizer.numberOfTapsRequired = 1;
            [_profileImageView addGestureRecognizer:tapRecognizer];
            [_profileImageView setUserInteractionEnabled:YES];
        }
        
        // If there's no profile picture please get it
        if(interestActivity.profilePhotoImage==nil){
            [self imageCircular:[UIImage imageNamed:@"picbox"]];
            NSOperationQueue *queue = [NSOperationQueue new];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                initWithTarget:self
                                                selector:@selector(loadProfileImage:)
                                                object:interestActivity.photoUrl];
            [queue addOperation:operation];
            
        }
        else
            _profileImageView.image=[BeagleUtilities imageCircularBySize:interestActivity.profilePhotoImage sqr:105.0f];
        
        // Location information
        [style setAlignment:NSTextAlignmentRight];
        UIColor *color=[BeagleUtilities returnBeagleColor:4];
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                 color,NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize locationTextSize = [interestActivity.locationName boundingRectWithSize:CGSizeMake(300, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
        
        UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(304-locationTextSize.width, fromTheTop, locationTextSize.width, locationTextSize.height)];
        locationLabel.backgroundColor = [UIColor clearColor];
        locationLabel.text = interestActivity.locationName;
        locationLabel.textColor = color;
        locationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        locationLabel.textAlignment = NSTextAlignmentRight;
        [_backgroundView addSubview:locationLabel];
        
        // Organizer information
        [style setAlignment:NSTextAlignmentLeft];
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        CGSize organizerNameSize=[interestActivity.organizerName boundingRectWithSize:CGSizeMake(300, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
        
        UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75,60-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height)];
        organizerNameLabel.backgroundColor = [UIColor clearColor];
        organizerNameLabel.text = interestActivity.organizerName;
        organizerNameLabel.textColor = [BeagleUtilities returnBeagleColor:4];
        organizerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        organizerNameLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:organizerNameLabel];
        
        if(self.interestActivity.dosRelation!=0){
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageTapped:)];
            tapRecognizer.numberOfTapsRequired = 1;
            [organizerNameLabel addGestureRecognizer:tapRecognizer];
            [organizerNameLabel setUserInteractionEnabled:YES];
        }

        
        // Adding the appropriate DOS icon
        if(self.interestActivity.dosRelation==1) {
            UIImageView *dos1RelationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(75+8+organizerNameSize.width, 43, 27, 15)];
            dos1RelationImageView.image = [UIImage imageNamed:@"DOS2"];
            [_backgroundView addSubview:dos1RelationImageView];
        }
        else if(self.interestActivity.dosRelation==2){
            UIImageView *dos2RelationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(75+8+organizerNameSize.width, 43, 32, 15)];
            dos2RelationImageView.image = [UIImage imageNamed:@"DOS3"];
            [_backgroundView addSubview:dos2RelationImageView];
        }
        
        // Adding the height of the profile picture
        fromTheTop += 52.5;
        
        // Adding buffer below the top section with the profile picture
        fromTheTop = fromTheTop+8.0f;
        
        // Activity description
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
        
        CGSize maximumLabelSize = CGSizeMake(288,999);
        
        CGRect commentTextRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                               attributes:attrs
                                                                                  context:nil];
        
        UILabel *activityDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,fromTheTop,commentTextRect.size.width,commentTextRect.size.height)];
        activityDescLabel.numberOfLines=0;
        activityDescLabel.lineBreakMode=NSLineBreakByWordWrapping;
        activityDescLabel.backgroundColor = [UIColor clearColor];
        activityDescLabel.text = interestActivity.activityDesc;
        activityDescLabel.textColor = [UIColor blackColor];
        activityDescLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        activityDescLabel.textAlignment = NSTextAlignmentLeft;
        activityDescLabel.tag=3569;
        [_backgroundView addSubview:activityDescLabel];
        
        fromTheTop = fromTheTop+commentTextRect.size.height;
        fromTheTop = fromTheTop+16.0f; // buffer after the description

        // Adding the counts panel here
        // If there is more than 1 participant
        if(self.interestActivity.participantsCount > 0) {
            attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                   [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                   [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                   style, NSParagraphStyleAttributeName, nil];
            UILabel *participantsCountTextLabel = [[UILabel alloc] init];
            participantsCountTextLabel.backgroundColor = [UIColor clearColor];
            participantsCountTextLabel.textColor = [BeagleUtilities returnBeagleColor:4];
            participantsCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
            participantsCountTextLabel.textAlignment = NSTextAlignmentLeft;
            participantsCountTextLabel.tag=347;
            
            int countFromTheLeft = 0;
            countFromTheLeft += 16;
            
            CGSize participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested", (long)self.interestActivity.participantsCount]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
            
            // Adding the Star image
            UIImageView *starWireframe = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Star-Wireframe"]];
            starWireframe.frame = CGRectMake(countFromTheLeft, fromTheTop, 17, 16);
            [_backgroundView addSubview:starWireframe];
            countFromTheLeft += 17+5;
            
            // Add the actual participant count
            participantsCountTextLabel.frame=CGRectMake(countFromTheLeft, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height);
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested", (long)self.interestActivity.participantsCount];
            [_backgroundView addSubview:participantsCountTextLabel];
            countFromTheLeft += participantsCountTextSize.width+16;
            
            // Are any of your friends participants?
            if (self.interestActivity.dos1count>0) {
                
                NSString* relationship = nil;
                
                if(self.interestActivity.dos1count > 1)
                    relationship = @"Friends";
                else
                    relationship = @"Friend";

                CGSize friendCountTextSize = [[NSString stringWithFormat:@"%ld %@", (long)self.interestActivity.dos1count, relationship]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                
                // Adding the DOS2 image
                UIImageView *DOS2Wireframe = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DOS2-Wireframe"]];
                DOS2Wireframe.frame = CGRectMake(countFromTheLeft, fromTheTop, 28, 16);
                [_backgroundView addSubview:DOS2Wireframe];
                countFromTheLeft += 28+5;
                
                // Adding the Friend count label
                UILabel *friendCountTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(countFromTheLeft, fromTheTop, friendCountTextSize.width, friendCountTextSize.height)];
                friendCountTextLabel.textColor = [BeagleUtilities returnBeagleColor:4];
                friendCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
                friendCountTextLabel.textAlignment = NSTextAlignmentLeft;
                friendCountTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)self.interestActivity.dos1count, relationship];
                friendCountTextLabel.tag = 348;
                [_backgroundView addSubview:friendCountTextLabel];
            }
            
            fromTheTop = fromTheTop + participantsCountTextSize.height;
            fromTheTop = fromTheTop + 16.0f; // Added buffer at the end of the participant count
            
            // Setup the participants panel
            [style setAlignment:NSTextAlignmentLeft];
            attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                 [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
                _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, fromTheTop, 264, 53)];
                scrollViewResize=FALSE;
                _scrollMenu.tag=786;
                _partcipantScrollArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(264+16+8, fromTheTop+13.5, 15, 20)];
                _partcipantScrollArrowImageView.image = [UIImage imageNamed:@"Right-Scroll"];
               [_backgroundView addSubview:_scrollMenu];
               [self setUpPlayerScroll:self.interestActivity.participantsArray];

            [_backgroundView addSubview:_partcipantScrollArrowImageView];
            
            if([self.interestActivity.participantsArray count]>4){
                _partcipantScrollArrowImageView.hidden=NO;
            }else{
                _partcipantScrollArrowImageView.hidden=YES;
            }


            
            fromTheTop += 55;
            fromTheTop += 16;
            
        }
        
        // Draw the Button
        UIButton *interestedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        interestedButton.frame=CGRectMake(16, fromTheTop, 151, 34);
        interestedButton.tag=345;
        UIColor *buttonColor = [[BeagleManager SharedInstance] mediumDominantColor];
        UIColor *outlineButtonColor = [[BeagleManager SharedInstance] darkDominantColor];
        UIFont *forthTextFont=[UIFont fontWithName:@"HelveticaNeue" size:15.0f];
        
        if(self.interestActivity.activityType==1){
            [interestedButton addTarget:self action:@selector(handleTapGestures:) forControlEvents:UIControlEventTouchUpInside];
            [interestedButton setEnabled:YES];
        }
        else{
            [interestedButton setEnabled:NO];
        }

        // If it's the organizer
        if (self.interestActivity.dosRelation==0) {
            
            // Setup text
            [[interestedButton titleLabel] setFont:forthTextFont];
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
        else if(self.interestActivity.dosRelation > 0 && self.interestActivity.isParticipant)
        {
            // Setup text
            [[interestedButton titleLabel]setFont:forthTextFont];
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
            [[interestedButton titleLabel]setFont:forthTextFont];
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
        
        // Add button
        [_backgroundView addSubview:interestedButton];
    
        // Space left after the button
        fromTheTop += 33+20;

        // Add the view to the cell
        _backgroundView.frame=CGRectMake(0, 0, 320, fromTheTop);
        [cell.contentView addSubview:_backgroundView];
        
        if(!postsLoadComplete){
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

        [activityIndicatorView setColor:[BeagleUtilities returnBeagleColor:12]];
        activityIndicatorView.hidesWhenStopped=YES;
             if(self.interestActivity.isParticipant)
                 activityIndicatorView.frame=CGRectMake(141.5, 64+fromTheTop-25+(self.view.frame.size.height-(64+47+fromTheTop))/2, 37, 37);
             else{
                 activityIndicatorView.frame=CGRectMake(141.5, 64+fromTheTop-25+(self.view.frame.size.height-(64+fromTheTop))/2, 37, 37);
                 
             }
        [self.view insertSubview:activityIndicatorView aboveSubview:self.contentWrapper];
        [activityIndicatorView startAnimating];

        }else{
             [activityIndicatorView stopAnimating];
        }
        return cell;
    }
    
    // For the COMMENTS part of the card
    else {
        
        CGFloat cellTop = 0.0f;
        
        if(indexPath.row==1)
            cellTop = 16.0f;
        else
            cellTop = 8.0f;
        
        static NSString *CellIdentifier = @"MediaTableCell2";
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor=[[BeagleManager SharedInstance] lightDominantColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        InterestChatClass *chatCell=[self.chatPostsArray objectAtIndex:indexPath.row-1];
        
        // Profile picture
        UIImageView *cellImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, cellTop, 35, 35)];
        
        UIImage*checkImage= [BeagleUtilities loadImage:chatCell.player_id];
        if(checkImage==nil){
        if (!chatCell.playerImage)
        {
            if (tableView.dragging == NO && tableView.decelerating == NO)
            {
                [self startIconDownload:chatCell forIndexPath:indexPath];
            }
            // if a download is deferred or in progress, return a placeholder image
            cellImageView.image = [BeagleUtilities imageCircularBySize:[UIImage imageNamed:@"picbox.png"] sqr:70.0f];
        }
        else
            cellImageView.image = [BeagleUtilities imageCircularBySize:chatCell.playerImage sqr:70.0f];
        }else{
            chatCell.playerImage=checkImage;
            cellImageView.image = [BeagleUtilities imageCircularBySize:checkImage sqr:70.0f];

        }
        
        cellImageView.tag=[[NSString stringWithFormat:@"111%li",(long)indexPath.row]integerValue];
        [cell.contentView addSubview:cellImageView];
        
        
        // Organizer name
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        UIColor *color=[UIColor blackColor];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f], NSFontAttributeName,
                               color,NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];

        CGSize organizerNameSize=[[[chatCell.player_name componentsSeparatedByString:@" "] objectAtIndex:0] boundingRectWithSize:CGSizeMake(245, 999)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil].size;
        
        UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(59, cellTop, organizerNameSize.width, organizerNameSize.height)];
        organizerNameLabel.attributedText = [[NSAttributedString alloc] initWithString:[[chatCell.player_name componentsSeparatedByString:@" "] objectAtIndex:0] attributes:attrs];
        [cell.contentView addSubview:organizerNameLabel];
        
        // Time stamp
        color=[BeagleUtilities returnBeagleColor:3];
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f], NSFontAttributeName,
                 color,NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        NSString *timestamp=[BeagleUtilities calculateChatTimestamp:chatCell.timestamp];
        
        CGSize dateTextSize = [timestamp boundingRectWithSize:CGSizeMake(125,999)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:attrs
                                                           context:nil].size;
        
        UILabel *timeStampLabel = [[UILabel alloc] initWithFrame:CGRectMake(59+organizerNameSize.width+5,cellTop+2, dateTextSize.width, dateTextSize.height)];
        
        timeStampLabel.attributedText = [[NSAttributedString alloc] initWithString:timestamp attributes:attrs];
        [cell.contentView  addSubview:timeStampLabel];
        
        cellTop = cellTop + organizerNameSize.height; // size of the profile picture
        cellTop = cellTop + 2.0f; // buffer below profile section
        
        // Comment text
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, NSLineBreakByWordWrapping, nil];
        
        CGSize maximumLabelSize = CGSizeMake(245,999);
        
        CGRect commentTextRect = [chatCell.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
        
        UILabel *chatDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(59, cellTop, commentTextRect.size.width, commentTextRect.size.height)];
        chatDescLabel.attributedText = [[NSAttributedString alloc] initWithString:chatCell.text attributes:attrs];
        chatDescLabel.numberOfLines = 0;
        [cell.contentView addSubview:chatDescLabel];
        
        cellTop = cellTop + commentTextRect.size.height;
        cellTop = cellTop + 16.0f;
        
        return cell;
    }
}
- (void)startIconDownload:(InterestChatClass*)appRecord forIndexPath:(NSIndexPath *)indexPath{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.chatRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload:kInterestChat];
    }
}

-(void)showArrowIndicator{
    _partcipantScrollArrowImageView.hidden=NO;
}
-(void)hideArrowIndicator{
    _partcipantScrollArrowImageView.hidden=YES;
    
}


// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows{
    if ([self.chatPostsArray count] > 0)
    {
        NSArray *visiblePaths = [self.detailedInterestTableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            if(indexPath.row!=0){
            InterestChatClass *appRecord = (InterestChatClass *)[self.chatPostsArray objectAtIndex:indexPath.row-1];
            
            
            if (!appRecord.playerImage) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
        }
        }
    }
    
    
}
- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        InterestChatClass *appRecord = (InterestChatClass *)[self.chatPostsArray objectAtIndex:indexPath.row-1];

        UITableViewCell *cell = (UITableViewCell*)[self.detailedInterestTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        UIImageView *cellImageView=(UIImageView*)[cell viewWithTag:[[NSString stringWithFormat:@"111%ld",(long)indexPath.row]integerValue]];
        // Display the newly loaded image
        appRecord.playerImage=iconDownloader.chatRecord.playerImage;
        cellImageView.image = [BeagleUtilities imageCircularBySize:iconDownloader.chatRecord.playerImage sqr:70.0f] ;
        
        [BeagleUtilities saveImage:iconDownloader.chatRecord.playerImage withFileName:appRecord.player_id];

    }
    
    [self.detailedInterestTableView reloadData];
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

-(void)profileImageTapped:(UITapGestureRecognizer*)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
    BeagleUserClass *player=[[BeagleUserClass alloc]initWithActivityObject:self.interestActivity];
    viewController.friendBeagle=player;
    [self.navigationController pushViewController:viewController animated:YES];

}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    if(serverRequest==kServerCallGetDetailedInterest){
        
        
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                id badge=[response objectForKey:@"badge"];
                if (badge != nil && [badge class] != [NSNull class]){
                    
                    [[BeagleManager SharedInstance]setBadgeCount:[badge integerValue]];
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badge integerValue]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
                    
                }

                
                id interest=[response objectForKey:@"interest"];
                if (interest != nil && [interest class] != [NSNull class]) {
                    
                    
                    if(isRedirected){
                        self.interestActivity=[[BeagleActivityClass alloc]initWithDictionary:interest];
                        [self createInterestInitialCard];
                        
                    }else{
                        BeagleActivityClass*updatedActivity=[[BeagleActivityClass alloc]initWithDictionary:interest];
                        self.interestActivity.postCount=updatedActivity.postCount;
                        self.interestActivity.participantsCount=updatedActivity.participantsCount;
                        self.interestActivity.dos1count=updatedActivity.dos1count;
                        self.interestActivity.activityDesc=updatedActivity.activityDesc;
                        self.interestActivity.endActivityDate=updatedActivity.endActivityDate;
                        self.interestActivity.startActivityDate=updatedActivity.startActivityDate;

                        
                    }
                    NSArray *participants=[interest objectForKey:@"participants"];
                    if (participants != nil && [participants class] != [NSNull class] && [participants count]!=0) {
                        for(id el in participants){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithDictionary:el];
                            [self.interestActivity.participantsArray addObject:userClass];
                        }
                        
                    }
                    NSArray *chats=[interest objectForKey:@"chats"];
                    if (chats != nil && [chats class] != [NSNull class] && [chats count]!=0) {
                        NSMutableArray *chatsArray=[[NSMutableArray alloc]init];
                        imageDownloadsInProgress=[NSMutableDictionary new];
                        for(id el in chats){
                            InterestChatClass *chatClass=[[InterestChatClass alloc]initWithDictionary:el];
                            [chatsArray addObject:chatClass];
                        }
                        if([chatsArray count]!=0){
                            self.chatPostsArray=[NSMutableArray arrayWithArray:chatsArray];
                        }
                    }
                    postsLoadComplete=TRUE;
                    [activityIndicatorView stopAnimating];
                   [self.detailedInterestTableView reloadData];
                    
                    if(toLastPost){
                        
                        [self.detailedInterestTableView beginUpdates];
                        
                        [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: [self.chatPostsArray count] inSection:0]
                                                              atScrollPosition:UITableViewScrollPositionTop
                                                                      animated:YES];
                        
                        [self.detailedInterestTableView endUpdates];
                        
                    }
                    
                }
                
                
                
                
            }else if (status != nil && [status class] != [NSNull class] && [status integerValue]==205){
                NSString *message = NSLocalizedString (@"This activity has been cancelled, let's show you what else is happening around you",
                                                       @"Cancel Activity Type");
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                alert.tag=647;
                [alert show];

            }
        }
        
        
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        scrollViewResize=TRUE;

        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            id message=[response objectForKey:@"message"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                id participantsCount=[response objectForKey:@"participantsCount"];
                if (participantsCount != nil && [participantsCount class] != [NSNull class]){

                id badge=[response objectForKey:@"badge"];
                if (badge != nil && [badge class] != [NSNull class]){
                    
                    [[BeagleManager SharedInstance]setBadgeCount:[badge integerValue]];
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badge integerValue]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
                    
                }
                // If Joined
                UILabel *participantsCountTextLabel=(UILabel*)[self.view viewWithTag:347];
                if([message isEqualToString:@"Joined"]){

                    self.interestActivity.participantsCount=[participantsCount integerValue];
                    self.interestActivity.dos1count=[[response objectForKey:@"dos1count"]integerValue];
                }
                // If Already joined, do nothing
                else if([message isEqualToString:@"Already Joined"]){
                    UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
                    [interestedButton setEnabled:YES];

                    [self.animationBlurView hide];
                    NSString *message = NSLocalizedString (@"You have already joined.",
                                                           @"Already Joined");
                    BeagleAlertWithMessage(message);
                    BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
                    notifObject.activity=self.interestActivity;
                    notifObject.notificationType=GOING_TYPE;

                    NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
                    [notificationDictionary setObject:notifObject forKey:@"notify"];
                    NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    return;

                }
                // If Left update counts
                else {
                    self.interestActivity.participantsCount=[participantsCount integerValue];
                    self.interestActivity.dos1count=[[response objectForKey:@"dos1count"]integerValue];                    
                }
                
                // Updated labels accordingly as well
                if(self.interestActivity.participantsCount>0 && self.interestActivity.dos1count>0){
                    NSString *relationship = @"Friend";
                    UILabel *friendsCountTextLabel=(UILabel*)[self.view viewWithTag:348];
                    if (self.interestActivity.dos1count >1) relationship = @"Friends";

                    participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
                    friendsCountTextLabel.text = [NSString stringWithFormat:@"%ld %@",(long)self.interestActivity.dos1count, relationship];
                    
                }else{
                    participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
                }
                
                // Updating the button and text too
                UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
                UIColor *outlineButtonColor = [[BeagleManager SharedInstance] darkDominantColor];
                
                if(self.interestActivity.isParticipant){
                    self.interestActivity.isParticipant=FALSE;
                    
                    [interestedButton setEnabled:YES];

                    // Normal state
                    [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
                    [interestedButton setTitleColor:outlineButtonColor forState:UIControlStateNormal];
                    [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star-Unfilled"] withColor:outlineButtonColor] forState:UIControlStateNormal];
                    
                    // Pressed state
                    [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                    [interestedButton setTitleColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
                    [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star-Unfilled"] withColor:[outlineButtonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
                    
                    self.contentWrapper.interested=NO;
                    [self.contentWrapper _setInitialFrames];
                    
                    [self.contentWrapper.inputView setHidden:YES];
                    [self.contentWrapper.dummyInputView setHidden:YES];
                    
                    
                    NSMutableArray *testArray=[NSMutableArray new];
                    for(BeagleUserClass *data in self.interestActivity.participantsArray){
                        if(data.beagleUserId!=[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
                            
                            [testArray addObject:data];
                        }
                    }
                    self.interestActivity.participantsArray=testArray;
                    [self.detailedInterestTableView reloadData];

                    
                }
                else{
                    self.interestActivity.isParticipant=TRUE;
                    
                    
                    [self.animationBlurView show];
                    
                    timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                             target: self
                                                           selector:@selector(hideInterestOverlay)
                                                           userInfo: nil repeats:NO];


                    
                }
                
                }
            }
        }

    }
    else if (serverRequest==kServerCallPostComment||serverRequest==kServerCallGetBackgroundChats||serverRequest==kServerInAppChatDetail){
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
        
        [_sendMessage setProgress:0.75 animated:YES];
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                id badge=[response objectForKey:@"badge"];
                if (badge != nil && [badge class] != [NSNull class]){
                    
                    [[BeagleManager SharedInstance]setBadgeCount:[badge integerValue]];
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badge integerValue]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];
                    
                }

                
                NSArray* activity_chats=[response objectForKey:@"activity_chats"];
                if (activity_chats != nil && [activity_chats class] != [NSNull class] && [activity_chats count]!=0) {
                    if(self.chatPostsArray==nil){
                        self.chatPostsArray=[NSMutableArray new];
                    }
                    for(id chatPost in activity_chats){
                        InterestChatClass *chatClass=[[InterestChatClass alloc]initWithDictionary:chatPost];
                        if([self.chatPostsArray count]>0){
                            BOOL isFound=FALSE;
                            for(InterestChatClass *chat in self.chatPostsArray){
                                if(chat.chat_id==chatClass.chat_id){
                                    isFound=TRUE;
                                    break;
                                }
                                else{
                                    isFound=FALSE;
                                }
                            }
                            if(!isFound){
                               [self.chatPostsArray addObject:chatClass];
                            }
                        }
                        else
                            [self.chatPostsArray addObject:chatClass];
                    }
                    
                    
                    [PostSoundEffect playMessageSentSound];
                    
                    [self.detailedInterestTableView reloadData];
                    if(serverRequest==kServerCallPostComment){
                        [self.contentWrapper.inputView.textView setText:nil];
                        [self.contentWrapper.dummyInputView.textView setText:nil];
                        [self.contentWrapper resize];

                    }
                    [self.detailedInterestTableView beginUpdates];
                    
                    [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: [self.chatPostsArray count] inSection:0]
                                                          atScrollPosition:UITableViewScrollPositionTop
                                                                  animated:YES];
                    
                    [self.detailedInterestTableView endUpdates];

                    self.interestActivity.postCount=[self.chatPostsArray count];
                    
                    
                    }
                
                }
        
        }
        
        // Successfully added the post!
        [_sendMessage setProgress:1.0 animated:YES];
        
        
        // Make sure the animation completed
        if(_sendMessage.progress == 1.0f) {
            [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(removeProgressIndicator) userInfo:nil repeats:NO];
            self.contentWrapper.inputView.rightButton.enabled = YES;
            self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
        }

    }
        BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
        notifObject.activity=self.interestActivity;
        if(serverRequest==kServerCallParticipateInterest)
            notifObject.notificationType=GOING_TYPE;
        else if (serverRequest==kServerCallLeaveInterest)
            notifObject.notificationType=LEAVED_ACTIVITY_TYPE;
        else if(serverRequest==kServerCallPostComment||serverRequest==kServerCallGetBackgroundChats||serverRequest==kServerInAppChatDetail)
                notifObject.notificationType=CHAT_TYPE;
        else if(serverRequest==kServerCallGetDetailedInterest){
            notifObject.notificationType=ACTIVITY_UPDATE_TYPE;
        }
        
        NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
        [notificationDictionary setObject:notifObject forKey:@"notify"];
        NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
        [[NSNotificationCenter defaultCenter] postNotification:notification];


}


- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    if(serverRequest==kServerCallGetDetailedInterest)
    {
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
        [interestedButton setEnabled:YES];

        if(serverRequest==kServerCallParticipateInterest){

            [self.animationBlurView hide];

        }
    }
    else if(serverRequest==kServerCallPostComment||serverRequest==kServerCallGetBackgroundChats||serverRequest==kServerInAppChatDetail)
    {
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
        [_sendMessage setHidden:YES];
        [_sendMessage setProgress:0.0];
        self.contentWrapper.inputView.rightButton.enabled = YES;
        self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
    }
    
    NSString *message = NSLocalizedString (@"Well I guess those messages weren't that important. Please try again in a bit.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);

}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    if(serverRequest==kServerCallGetDetailedInterest)
    {
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
        [interestedButton setEnabled:YES];

        if(serverRequest==kServerCallParticipateInterest){

            [self.animationBlurView hide];
            
        }

    }
    else if(serverRequest==kServerCallPostComment||serverRequest==kServerCallGetBackgroundChats||serverRequest==kServerInAppChatDetail)
    {
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
        [_sendMessage setHidden:YES];
        [_sendMessage setProgress:0.0];
        self.contentWrapper.inputView.rightButton.enabled = YES;
        self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}



#pragma mark -
#pragma mark UIAlertView methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    //[alertView resignFirstResponder];
    
    if(alertView.tag==1467){
        if (buttonIndex == 0) {
            BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
            notifObject.activity=self.interestActivity;
            notifObject.notificationType=CANCEL_ACTIVITY_TYPE;
            
            NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
            [notificationDictionary setObject:notifObject forKey:@"notify"];
            NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            if([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Done"]){
                  [self doneButtonClicked:nil];
             }
            [self.navigationController popViewControllerAnimated:YES];
        }
}
    else if(alertView.tag==647){
        if (buttonIndex == 0) {
            BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
            notifObject.activity=self.interestActivity;
            notifObject.notificationType=CANCEL_ACTIVITY_TYPE;

            NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
            [notificationDictionary setObject:notifObject forKey:@"notify"];
            NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
            [[NSNotificationCenter defaultCenter] postNotification:notification];

            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
    else if(alertView.tag==kLeaveInterest){
    if (buttonIndex == 0) {
        
                if(_interestUpdateManager!=nil){
                    _interestUpdateManager.delegate = nil;
                    [_interestUpdateManager releaseServerManager];
                    _interestUpdateManager = nil;
                }
                
                _interestUpdateManager=[[ServerManager alloc]init];
                _interestUpdateManager.delegate=self;
        
                UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
                [interestedButton setEnabled:NO];

                [_interestUpdateManager removeMembership:self.interestActivity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
        }
    else{
        NSLog(@"Clicked Cancel Button");
     }
    }
    
    
}

-(void)dealloc{
    
    self.detailedInterestTableView.delegate = nil;
    self.detailedInterestTableView = nil;
    
    for (NSIndexPath *indexPath in [imageDownloadsInProgress allKeys]) {
        IconDownloader *d = [imageDownloadsInProgress objectForKey:indexPath];
        [d cancelDownload];
    }

    self.imageDownloadsInProgress=nil;
    
    for (ASIHTTPRequest *req in [ASIHTTPRequest.sharedQueue operations]) {
        [req clearDelegatesAndCancel];
        [req setDelegate:nil];
        [req setDidFailSelector:nil];
        [req setDidFinishSelector:nil];
    }
    [ASIHTTPRequest.sharedQueue cancelAllOperations];

}


-(void)hideInterestOverlay{
    [timer invalidate];
    [self.animationBlurView hide];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];

    [self updateMembershipView];
}

- (void)dismissEventFilter{
    [timer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    [self updateMembershipView];
    
}

-(void)updateMembershipView{
    UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
    [interestedButton setEnabled:YES];

    UIColor *buttonColor = [[BeagleManager SharedInstance] mediumDominantColor];
    // Normal state
    [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:buttonColor] forState:UIControlStateNormal];
    [interestedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star"] withColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    // Pressed state
    [interestedButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button"] withColor:[buttonColor colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    [interestedButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
    [interestedButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Star"] withColor:[[UIColor whiteColor] colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    
    NSMutableArray*interestArray=[NSMutableArray new];
    
    if([self.interestActivity.participantsArray count]!=0){
        [interestArray addObject:[[BeagleManager SharedInstance]beaglePlayer]];
        [interestArray addObjectsFromArray:self.interestActivity.participantsArray];
        self.interestActivity.participantsArray=interestArray;
    }else{
        [interestArray addObject:[[BeagleManager SharedInstance]beaglePlayer]];
        self.interestActivity.participantsArray=interestArray;
    }
    self.contentWrapper.interested=YES;
    [self.contentWrapper _setInitialFrames];
    [self.contentWrapper.inputView setHidden:NO];
    [self.contentWrapper.dummyInputView setHidden:NO];
    [self.detailedInterestTableView reloadData];
    

}

- (void)scrollMenu:(BeaglePlayerScrollMenu *)menu didSelectIndex:(NSInteger)selectedIndex{
    BeagleUserClass *player=[self.interestActivity.participantsArray objectAtIndex:selectedIndex];
    if(player.beagleUserId!=[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
    viewController.friendBeagle=player;
    [self.navigationController pushViewController:viewController animated:YES];
    }
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
