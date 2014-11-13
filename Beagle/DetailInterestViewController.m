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
#import "BeagleLabel.h"
#import "LinkViewController.h"
#if kPostInterface || 1
    #import "MessageInputView.h"
    #import "DismissiveTextView.h"
    #import "NSString+MessagesView.h"
    #import "UIButton+MessagesView.h"
    #define OSVersionIsAtLeastiOS7  (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
    #define INPUT_HEIGHT 44.0f
#endif

#define DISABLED_ALPHA 0.5f
#define kLeaveInterest 12

static NSString * const CellIdentifier = @"cell";
@interface DetailInterestViewController ()<BeaglePlayerScrollMenuDelegate,ServerManagerDelegate,UIGestureRecognizerDelegate,UITableViewDelegate,UITableViewDataSource,IconDownloaderDelegate,InAppNotificationViewDelegate,UIAlertViewDelegate,MessageKeyboardViewDelegate,UIGestureRecognizerDelegate,CreateAnimationBlurViewDelegate,UITextViewDelegate,DismissiveTextViewDelegate,MessageInputViewDelegate>{
    BOOL scrollViewResize;
    UIActivityIndicatorView *activityIndicatorView;
    BOOL postsLoadComplete;
    NSTimer *timer;
    UIImageView *_partcipantScrollArrowImageView;
    BOOL isKeyboardVisible;
    UILabel *placeholderLabel;
    BOOL isEditState;
}

@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@property (strong, nonatomic) UIImageView *profileImageView;
@property (strong,nonatomic)BeaglePlayerScrollMenu *scrollMenu;
@property(nonatomic,strong)NSMutableArray *chatPostsArray;
@property(nonatomic,strong)UITableView *detailedInterestTableView;
@property (nonatomic, strong) UIProgressView* sendMessage;
@property(nonatomic,strong)CreateAnimationBlurView *animationBlurView;
#if kPostInterface
@property (strong, nonatomic) MessageInputView *inputToolBarView;
@property (assign, nonatomic) CGFloat previousTextViewContentHeight;
@property (assign, nonatomic, readonly) UIEdgeInsets originalTableViewContentInset;

- (void)setup;

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender;

#pragma mark - view controller
- (void)finishSend;
- (void)scrollToBottomAnimated:(BOOL)animated;

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification;
- (void)handleWillHideKeyboard:(NSNotification *)notification;
- (void)keyboardWillShowHide:(NSNotification *)notification;
#else
@property (nonatomic, strong) MessageKeyboardView *contentWrapper;

#endif
@end

@implementation DetailInterestViewController
@synthesize interestActivity;
@synthesize scrollMenu=_scrollMenu;
@synthesize imageDownloadsInProgress;
@synthesize profileImageView=_profileImageView;
@synthesize chatPostsArray;
@synthesize isRedirected,toLastPost,inappNotification;
#if kPostInterface
@synthesize inputToolBarView;
#endif
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (getPostsUpdateInBackground) name:kUpdatePostsOnInterest object:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar setTintColor:[[BeagleManager SharedInstance] darkDominantColor]];

    BeagleManager *BG=[BeagleManager SharedInstance];
    if(BG.activityDeleted){
        BG.activityDeleted=FALSE;
        [self.navigationController popViewControllerAnimated:NO];
        return;
    }
    
    // Setup the progress indicator
    _sendMessage = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 1)];
    [_sendMessage setProgressTintColor:[BeagleUtilities returnBeagleColor:13]];
    [self.view addSubview:_sendMessage];
    [_sendMessage setHidden:YES];
    
    scrollViewResize=TRUE;
    NSString* screenTitle = [BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:self.interestActivity.endActivityDate];
    self.navigationItem.title = screenTitle;
    [self.detailedInterestTableView reloadData];
    
    
    
#if kPostInterface
    
   // [self scrollToBottomAnimated:NO];
	    _originalTableViewContentInset = self.detailedInterestTableView.contentInset;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillHideKeyboard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
#endif

    
}
-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
#if !kPostInterface
    [self.contentWrapper _registerForNotifications];
#endif
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUpdatePostsOnInterest object:nil];
    
#if kPostInterface
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
#else
    
    
    [self.contentWrapper _unregisterForNotifications];

    
#endif
    
    
}
-(void)getPostsUpdateInBackground{
    
    ServerManager *client = [ServerManager sharedServerManagerClient];
    client.delegate = self;

    if([self.chatPostsArray count]!=0){
        [client getMoreBackgroundPostsForAnInterest:[self.chatPostsArray lastObject] activId:self.interestActivity.activityId];
        
    }else{
        [client getNewBackgroundPostsForAnInterest:self.interestActivity.activityId];
    }

}

- (void)didReceiveBackgroundInNotification:(NSNotification*) note{
    
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
        ServerManager *client = [ServerManager sharedServerManagerClient];
        client.delegate = self;
        [client getPostDetail:notifObject.postChatId];
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
    ServerManager *client = [ServerManager sharedServerManagerClient];
    client.delegate = viewController;

    viewController.isRedirected=TRUE;
    if(notification.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;

    [client getDetailedInterest:notification.activity.activityId];
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
    
#if !kPostInterface

    [self.contentWrapper.inputView.textView resignFirstResponder];
    [self.view endEditing:YES];
    [self.contentWrapper.inputView.textView setText:nil];
    [self.contentWrapper.dummyInputView.textView setText:nil];
    [self.navigationController popViewControllerAnimated:YES];
#endif

}
-(void)cancelButtonClicked:(id)sender{
    
#if !kPostInterface
    [self.contentWrapper.inputView.textView resignFirstResponder];
    [self.view endEditing:YES];
    [self.contentWrapper.inputView.textView setText:nil];
    [self.contentWrapper.dummyInputView.textView setText:nil];
    [self dismissViewControllerAnimated:YES completion:Nil];
#endif
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
    
    self.navigationItem.backBarButtonItem.title=@"";
    
    

}
-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // Navigation back button was pressed
        if(isKeyboardVisible){
            [self.inputToolBarView.textView resignFirstResponder];
        }
   }
    [super viewWillDisappear:animated];
}
-(void)resizeDetailTableView{
    
    if(self.interestActivity.isParticipant)
        [placeholderLabel setText:@"Join the conversation"];
    else{
        [placeholderLabel setText:[NSString stringWithFormat:@"Leave %@ a message",[[self.interestActivity.organizerName componentsSeparatedByString:@" "] objectAtIndex:0]]];
    }

    if(isKeyboardVisible){
        [self doneButtonClicked:nil];
    }

}

#pragma mark - Initialization
- (void)setup{
    
    CGRect tableFrame=CGRectMake(0.0f, 64.0f, self.view.frame.size.width, self.view.frame.size.height - INPUT_HEIGHT-64.0f);
    self.detailedInterestTableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    self.detailedInterestTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.detailedInterestTableView.separatorInset = UIEdgeInsetsZero;
    self.detailedInterestTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.detailedInterestTableView setBackgroundColor:[BeagleUtilities returnBeagleColor:2]];
    self.detailedInterestTableView.dataSource = self;
    self.detailedInterestTableView.delegate = self;
    [self.view addSubview:self.detailedInterestTableView];
    

    
    CGRect inputFrame = CGRectMake(0.0f, self.view.frame.size.height - INPUT_HEIGHT, self.view.frame.size.width, INPUT_HEIGHT);
    self.inputToolBarView = [[MessageInputView alloc] initWithFrame:inputFrame delegate:self];
    //self.inputToolBarView.textView.dismissivePanGestureRecognizer = self.detailedInterestTableView.panGestureRecognizer;
    self.inputToolBarView.textView.keyboardDelegate = self;
    
    placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, self.inputToolBarView.textView.frame.size.width - 20.0, 34.0)];
      if(self.interestActivity.isParticipant)
    [placeholderLabel setText:@"Join the conversation"];
      else{
          [placeholderLabel setText:[NSString stringWithFormat:@"Leave %@ a message",[[self.interestActivity.organizerName componentsSeparatedByString:@" "] objectAtIndex:0]]];
      }
    // placeholderLabel is instance variable retained by view controller
    [placeholderLabel setBackgroundColor:[UIColor whiteColor]];
    placeholderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
    placeholderLabel.textColor=[BeagleUtilities returnBeagleColor:3];
    
    // textView is UITextView object you want add placeholder text to
    [self.inputToolBarView.textView addSubview:placeholderLabel];

    
    UIButton *sendButton = [UIButton defaultPostButton];
//    sendButton.enabled = NO;
    sendButton.frame = CGRectMake(self.inputToolBarView.frame.size.width - 65.0f, 8.0f, 59.0f, 26.0f);
    [sendButton addTarget:self
                   action:@selector(sendPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.inputToolBarView setSendButton:sendButton];
    [self.view addSubview:self.inputToolBarView];
    
}

-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    
    if(isKeyboardVisible){
        [self.inputToolBarView.textView resignFirstResponder];
    }
}


-(void)createInterestInitialCard{
    
    self.interestActivity.participantsArray=[[NSMutableArray alloc]init];
    if(self.interestActivity.dosRelation==0){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
    }else{
        
        self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
        self.animationBlurView.delegate=self;
        self.animationBlurView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
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
    
#if kPostInterface
    
    [self setup];
    
#else
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
    
    
#endif
    

}


#pragma mark -
#pragma mark Show/Hide Delegate Method

- (void)show{
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonClicked:)];
    self.navigationItem.hidesBackButton = YES;
}
-(void)hide{
#if 1
    if(self.interestActivity.dosRelation==0){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
    }else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flag" style:UIBarButtonItemStylePlain target:self action:@selector(flagButtonClicked:)];
    }

    self.navigationItem.hidesBackButton = NO;
#endif
}

-(void)doneButtonClicked:(id)sender{
    
#if kPostInterface
    [self.inputToolBarView.textView resignFirstResponder];
    [self.detailedInterestTableView reloadData];
    [self.view endEditing:YES];

#else
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
    
    
#endif
    
}
-(void)flagButtonClicked:(id)sender{
    
    if(isKeyboardVisible){
        [self.inputToolBarView.textView resignFirstResponder];
    }
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
    
#if kPostInterface
    if(isKeyboardVisible){
        [self.inputToolBarView.textView resignFirstResponder];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    isEditState=true;
#else
    [self.contentWrapper _unregisterForNotifications];
#endif
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    viewController.bg_activity=self.interestActivity;
    viewController.editState=TRUE;
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
    
    [self.navigationController presentViewController:activityNavigationController animated:YES completion:nil];

}

-(void)postClicked:(id)sender{

#if !kPostInterface
    if([BeagleUtilities checkIfTheTextIsBlank:[self.contentWrapper.inputView.textView text]]){
        
        [Appsee addEvent:@"Post Chat"];
        
        // Gray out 'Post' button
        self.contentWrapper.inputView.rightButton.enabled = NO;
        self.contentWrapper.inputView.rightButton.tintColor = [[BeagleUtilities returnBeagleColor:13] colorWithAlphaComponent:DISABLED_ALPHA];
        
        // Show progress indicator
        [_sendMessage setProgress:0.0f];
        [_sendMessage setHidden:NO];
        [_sendMessage setProgress:0.25f animated:YES];
        
        ServerManager *client = [ServerManager sharedServerManagerClient];
        client.delegate = self;
        [client postAComment:self.interestActivity.activityId desc:[self.contentWrapper.inputView.textView text]];
        
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
#endif
}

-(void)removeProgressIndicator {
    [_sendMessage setHidden:YES];
    [_sendMessage setProgress:0.0f];
}

-(void)handleTapGestures:(UITapGestureRecognizer*)sender{
    
    if(self.interestActivity.dosRelation!=0){
        if (self.interestActivity.isParticipant) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you no longer want to do this?"
                                                            message:nil
                                                           delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No",nil];
            alert.tag=kLeaveInterest;
            [alert show];

//            [_interestUpdateManager removeMembership:self.interestActivity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
        }
        else{
            ServerManager *client = [ServerManager sharedServerManagerClient];
            client.delegate = self;

            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
            
            [self.animationBlurView blurWithColor];
            [self.animationBlurView crossDissolveShow];
            UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
            [keyboard addSubview:self.animationBlurView];
            
            UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
            [interestedButton setEnabled:NO];
            [client participateMembership:self.interestActivity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
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
        style.lineBreakMode=NSLineBreakByWordWrapping;
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                           [UIColor blackColor],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];
    
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString : self.interestActivity.activityDesc  attributes : attrs];
        CGFloat height=[BeagleUtilities heightForAttributedStringWithEmojis:attributedString forWidth:[UIScreen mainScreen].bounds.size.width-32];

        if(self.interestActivity.participantsCount==0)
            cardHeight=136+(int)height+kHeightClip;
        else
            cardHeight=241+(int)height+kHeightClip;
        
        return cardHeight;
    }
    
    else{
        {
            InterestChatClass *chatCell=[self.chatPostsArray objectAtIndex:indexPath.row-1];
            if([chatCell.text length]!=0 && [chatCell.text isKindOfClass:[NSString class]]){
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setAlignment:NSTextAlignmentLeft];
            style.lineBreakMode=NSLineBreakByWordWrapping;
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f], NSFontAttributeName,
                                   [UIColor blackColor],NSForegroundColorAttributeName,
                                   style, NSParagraphStyleAttributeName, nil];
            
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString : chatCell.text
                                                                                   attributes :attrs];
            
            CGFloat height=[BeagleUtilities heightForAttributedStringWithEmojis:attributedString forWidth:[UIScreen mainScreen].bounds.size.width-75];


            
            if(indexPath.row==1)
                return 45.0f+8.0f+height+kPostTextClip;
            
            return 45.0f+height+kPostTextClip;
           }
        }
    }
    return 0.0f;
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
        
        // Setting up the card (background)
        UIView *_backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, fromTheTop, [UIScreen mainScreen].bounds.size.width, 400)];
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
        NSDictionary*attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                 color,NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize locationTextSize = [interestActivity.locationName boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-20, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
        
        UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-locationTextSize.width-16, fromTheTop, locationTextSize.width, locationTextSize.height)];
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
        
        CGSize organizerNameSize=[interestActivity.organizerName boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-20, 999)
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
        style.lineBreakMode=NSLineBreakByWordWrapping;
        // Activity description
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width-32,999);
        
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString : self.interestActivity.activityDesc  attributes : attrs];
        CGFloat height=[BeagleUtilities heightForAttributedStringWithEmojis:attributedString forWidth:[UIScreen mainScreen].bounds.size.width-32];

        CGRect commentTextRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                               attributes:attrs
                                                                                  context:nil];
        
        
        BeagleLabel *beagleLabel = [[BeagleLabel alloc] initWithFrame:CGRectMake(16, fromTheTop, commentTextRect.size.width,height+kHeightClip) type:1];
        [beagleLabel setText:self.interestActivity.activityDesc];
        beagleLabel.textAlignment = NSTextAlignmentLeft;
        beagleLabel.numberOfLines = 0;
        beagleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        [_backgroundView addSubview:beagleLabel];
        
        [beagleLabel setDetectionBlock:^(BeagleHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
                if(hotWord==BeagleLink)
                  [self redirectToWebPage:string];
            
            
            
        }];

#if 0
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
#endif
        fromTheTop = fromTheTop+height+kHeightClip;
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
        
                _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, fromTheTop, [UIScreen mainScreen].bounds.size.width-56, 53)];
                scrollViewResize=FALSE;
                _scrollMenu.tag=786;
                _partcipantScrollArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-56)+16+7, fromTheTop+13.5, 16, 21)];
                _partcipantScrollArrowImageView.image = [UIImage imageNamed:@"Right-Scroll"];
               [_backgroundView addSubview:_scrollMenu];
               [self setUpPlayerScroll:self.interestActivity.participantsArray];

            [_backgroundView addSubview:_partcipantScrollArrowImageView];
            
            // When to show the next arrow and when not to!
            if([self.interestActivity.participantsArray count]*66 > [UIScreen mainScreen].bounds.size.width-41){
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
        
        // Adding a a label for public and invite only interests
        [style setAlignment:NSTextAlignmentRight];
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:6],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        // Indicate if the activity is Invite only
        if([self.interestActivity.visibility isEqualToString:@"custom"]) {
            
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
        else if([self.interestActivity.visibility isEqualToString:@"public"] && self.interestActivity.activityType != 2) {
            
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
            // Do not add any icon
        }

    
        // Space left after the button
        fromTheTop += 33+20;

        // Add the view to the cell
        _backgroundView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, fromTheTop);
        [cell.contentView addSubview:_backgroundView];
        
        if(!postsLoadComplete){
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

        [activityIndicatorView setColor:[BeagleUtilities returnBeagleColor:12]];
        activityIndicatorView.hidesWhenStopped=YES;
             if(self.interestActivity.isParticipant)
                 activityIndicatorView.frame=CGRectMake((self.view.frame.size.width-37)/2,64+fromTheTop-25+(self.view.frame.size.height-(64+47+fromTheTop))/2, 37, 37);
             else{
                 activityIndicatorView.frame=CGRectMake((self.view.frame.size.width-37)/2,64+fromTheTop-25+(self.view.frame.size.height-(64+fromTheTop))/2, 37, 37);
                 
             }
#if kPostInterface
       [self.view insertSubview:activityIndicatorView aboveSubview:self.detailedInterestTableView];
#else
             [self.view insertSubview:activityIndicatorView aboveSubview:self.contentWrapper];
#endif
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
        color=[[BeagleManager SharedInstance] mediumDominantColor];
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
        style.lineBreakMode=NSLineBreakByWordWrapping;
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width-75,999);
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString : chatCell.text attributes : attrs];
        CGRect commentTextRect = [attributedString boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];

        
        
        CGFloat height=[BeagleUtilities heightForAttributedStringWithEmojis:attributedString forWidth:[UIScreen mainScreen].bounds.size.width-75];
        BeagleLabel *beagleLabel = [[BeagleLabel alloc] initWithFrame:CGRectMake(59, cellTop, commentTextRect.size.width, height+kPostTextClip) type:2];
        [beagleLabel setTextColor:[UIColor blackColor]];
        [beagleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
        [beagleLabel setAttributes:attrs];
        [beagleLabel setText:chatCell.text];
        beagleLabel.textAlignment = NSTextAlignmentLeft;
        beagleLabel.numberOfLines = 0;
        beagleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [cell.contentView addSubview:beagleLabel];
        
        [beagleLabel setDetectionBlock:^(BeagleHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
                    if(hotWord==BeagleLink)
                        [self redirectToWebPage:string];
            
            
            
        }];

        
#if 0
        UILabel *chatDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(59, cellTop, commentTextRect.size.width, commentTextRect.size.height)];
        chatDescLabel.attributedText = [[NSAttributedString alloc] initWithString:chatCell.text attributes:attrs];
        chatDescLabel.numberOfLines = 0;
        [cell.contentView addSubview:chatDescLabel];
#endif
        
//        cellTop = cellTop + height+kPostTextClip;
//        cellTop = cellTop + 16.0f;
        
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
    
    if(isKeyboardVisible){
        [self.inputToolBarView.textView resignFirstResponder];
        return;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
    BeagleUserClass *player=[[BeagleUserClass alloc]initWithActivityObject:self.interestActivity];
    viewController.friendBeagle=player;
    [self.navigationController pushViewController:viewController animated:YES];

}

#pragma mark -
#pragma mark redirectToWebPage method

-(void)redirectToWebPage:(NSString*)webLink{
    
    NSLog(@"webLink=%@",webLink);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LinkViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"webLinkScreen"];
    viewController.linkString=webLink;
    [self.navigationController pushViewController:viewController animated:YES];

#if kPostInterface
    if(isKeyboardVisible){
        [self doneButtonClicked:nil];
    }
#else
    if([self.contentWrapper iskeyboardVisible]){
        [self doneButtonClicked:nil];
    }
    
#endif
    
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    if(serverRequest==kServerCallGetDetailedInterest){
        
        
        
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
                        NSMutableArray *postArray=[[NSMutableArray alloc]init];
                        imageDownloadsInProgress=[NSMutableDictionary new];
                        for(id el in chats){
                            InterestChatClass *chatClass=[[InterestChatClass alloc]initWithDictionary:el];
                            [postArray addObject:chatClass];
                        }
                    
                    NSArray *chatArray=[NSArray arrayWithArray:postArray];
                    if([chatArray count]!=0){
                        chatArray = [chatArray sortedArrayUsingComparator: ^(InterestChatClass *a, InterestChatClass *b) {
                            
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                            
                            NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                            [dateFormatter setTimeZone:utcTimeZone];
                            
                            NSDate *s1 = [dateFormatter dateFromString:a.timestamp];//add the string
                            NSDate *s2 = [dateFormatter dateFromString:b.timestamp];
                            
                            return [s1 compare:s2];
                        }];

                    }
                        if([chatArray count]!=0){
                            self.chatPostsArray=[NSMutableArray arrayWithArray:chatArray];
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
#if kPostInterface
                    
                    [self resizeDetailTableView];
#else
                    self.contentWrapper.interested=NO;
                    [self.contentWrapper _setInitialFrames];
                    
                    [self.contentWrapper.inputView setHidden:YES];
                    [self.contentWrapper.dummyInputView setHidden:YES];
                    
#endif
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
            #if kPostInterface

                    [self finishSend];
            #else
                    [self.contentWrapper.inputView.textView setText:nil];
                    [self.contentWrapper.dummyInputView.textView setText:nil];
                    [self.contentWrapper resize];
            #endif
                    }
#if 1
                    NSInteger rows=[self.detailedInterestTableView numberOfRowsInSection:0];

                        if(rows>0){
                    [self.detailedInterestTableView beginUpdates];
                        
                    
                    [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows-1 inSection:0]
                                                          atScrollPosition:UITableViewScrollPositionBottom
                                                                  animated:YES];
                    
                    [self.detailedInterestTableView endUpdates];

                    }
#endif
                    self.interestActivity.postCount=[self.chatPostsArray count];
                    
                    
                    }
                
                }
        
        }
        
        // Successfully added the post!
        [_sendMessage setProgress:1.0 animated:YES];
        
        
        // Make sure the animation completed
        if(_sendMessage.progress == 1.0f) {
            [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(removeProgressIndicator) userInfo:nil repeats:NO];
 #if !kPostInterface
            self.contentWrapper.inputView.rightButton.enabled = YES;
            self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
 #endif
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
    if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
        [interestedButton setEnabled:YES];

        if(serverRequest==kServerCallParticipateInterest){

            [self.animationBlurView hide];

        }
    }
    else if(serverRequest==kServerCallPostComment||serverRequest==kServerCallGetBackgroundChats||serverRequest==kServerInAppChatDetail)
    {
        [_sendMessage setHidden:YES];
        [_sendMessage setProgress:0.0];
    #if kPostInterface
        self.inputToolBarView.sendButton.enabled=YES;
    #else
        self.contentWrapper.inputView.rightButton.enabled = YES;
        self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
   #endif
    }
    
    NSString *message = NSLocalizedString (@"Well I guess those messages weren't that important. Please try again in a bit.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);

}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
        [interestedButton setEnabled:YES];

        if(serverRequest==kServerCallParticipateInterest){

            [self.animationBlurView hide];
            
        }

    }
    else if(serverRequest==kServerCallPostComment||serverRequest==kServerCallGetBackgroundChats||serverRequest==kServerInAppChatDetail)
    {
        [_sendMessage setHidden:YES];
        [_sendMessage setProgress:0.0];
        
    #if kPostInterface
        self.inputToolBarView.sendButton.enabled=YES;
    #else
        self.contentWrapper.inputView.rightButton.enabled = YES;
        self.contentWrapper.inputView.rightButton.tintColor = [BeagleUtilities returnBeagleColor:13];
    #endif
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
        
        ServerManager *client = [ServerManager sharedServerManagerClient];
        client.delegate = self;
        UIButton *interestedButton=(UIButton*)[self.view viewWithTag:345];
        [interestedButton setEnabled:NO];

        [client removeMembership:self.interestActivity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
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
    
#if kPostInterface
        self.detailedInterestTableView = nil;
        self.inputToolBarView = nil;
#endif
}




#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender
{
    if(isKeyboardVisible||[self.inputToolBarView.textView hasText])
    [self sendPressed:sender
                      withText:[self.inputToolBarView.textView.text trimWhitespace]];
}

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    
        if([BeagleUtilities checkIfTheTextIsBlank:text]){
            
            // Gray out 'Post' button

            self.inputToolBarView.sendButton.enabled=NO;
            // Show progress indicator
            [_sendMessage setProgress:0.0f];
            [_sendMessage setHidden:NO];
            [_sendMessage setProgress:0.25f animated:YES];
            
            ServerManager *client = [ServerManager sharedServerManagerClient];
            client.delegate = self;
            [client postAComment:self.interestActivity.activityId desc:text];
            
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

- (void)finishSend
{
    [self.inputToolBarView.textView setText:nil];
    [self textViewDidChange:self.inputToolBarView.textView];
    [self.detailedInterestTableView reloadData];
    [self scrollToBottomAnimated:YES];
    self.inputToolBarView.sendButton.enabled=YES;
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
#if kPostInterface
    [self resizeDetailTableView];
    
#else
    self.contentWrapper.interested=YES;
    [self.contentWrapper _setInitialFrames];
    [self.contentWrapper.inputView setHidden:NO];
    [self.contentWrapper.dummyInputView setHidden:NO];
#endif
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

- (void)scrollToBottomAnimated:(BOOL)animated
{
#if 1
    if(isKeyboardVisible){
    CGPoint contentOffset = self.detailedInterestTableView.contentOffset;
    
    CGFloat contentHeight = self.detailedInterestTableView.contentSize.height;
    CGFloat scrollViewHeight = self.detailedInterestTableView.bounds.size.height;
    
    UIEdgeInsets contentInset = self.detailedInterestTableView.contentInset;
    CGFloat bottomInset = contentInset.bottom;
    CGFloat topInset = contentInset.top;
    
    CGFloat contentOffsetY;
    contentOffsetY = contentHeight - (scrollViewHeight - bottomInset);
    contentOffsetY = MAX(contentOffsetY, -topInset);

    contentOffset.y = contentOffsetY;
    self.detailedInterestTableView.contentOffset = contentOffset;
    }
    if(isEditState){
        isEditState=false;
        [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: 0 inSection:0]
                                              atScrollPosition:UITableViewScrollPositionTop
                                                      animated:NO];
    }

#if 0
    if([self.chatPostsArray count]>0){
        [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: [self.chatPostsArray count] inSection:0]
                                              atScrollPosition:UITableViewScrollPositionTop
                                                      animated:YES];
    }
    else{
        [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: 0 inSection:0]
                                              atScrollPosition:UITableViewScrollPositionTop
                                                      animated:YES];
        
    }
#endif
#endif
}


- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath
              atScrollPosition:(UITableViewScrollPosition)position
                      animated:(BOOL)animated
{
    [self.detailedInterestTableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:position
                                  animated:animated];
}


#pragma mark - Text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
    
    if(!self.previousTextViewContentHeight)
        self.previousTextViewContentHeight = textView.contentSize.height;
    
    [self scrollToBottomAnimated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    
    if([textView hasText]||isKeyboardVisible) {
        placeholderLabel.hidden = YES;
    }
    else{
        placeholderLabel.hidden = NO;
    }

    CGFloat maxHeight = [MessageInputView maxHeight];
    CGSize size = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, maxHeight)];
    CGFloat textViewContentHeight = size.height;
    
    // End of textView.contentSize replacement code
    
    BOOL isShrinking = textViewContentHeight < self.previousTextViewContentHeight;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;
    
    if(!isShrinking && self.previousTextViewContentHeight == maxHeight) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }
    
    //if(changeInHeight != 0.0f) {
        //        if(!isShrinking)
        //            [self.inputToolBarView adjustTextViewHeightBy:changeInHeight];
        
        [UIView animateWithDuration:0.25f
                         animations:^{
                             UIEdgeInsets insets = UIEdgeInsetsMake(0.0f,
                                                                    0.0f,
                                                                    self.detailedInterestTableView.contentInset.bottom + changeInHeight,
                                                                    0.0f);
                             
                             self.detailedInterestTableView.contentInset = insets;
                             self.detailedInterestTableView.scrollIndicatorInsets = insets;
                             [self scrollToBottomAnimated:NO];
                             
                             if(isShrinking) {
                                 // if shrinking the view, animate text view frame BEFORE input view frame
                                 [self.inputToolBarView adjustTextViewHeightBy:changeInHeight];
                             }
                             
                             CGRect inputViewFrame = self.inputToolBarView.frame;
                             self.inputToolBarView.frame = CGRectMake(0.0f,
                                                                      inputViewFrame.origin.y - changeInHeight,
                                                                      inputViewFrame.size.width,
                                                                      inputViewFrame.size.height + changeInHeight);
                             
                             if(!isShrinking) {
                                 [self.inputToolBarView adjustTextViewHeightBy:changeInHeight];
                             }
                         }
                         completion:^(BOOL finished) {
                             //[self scrollToBottomAnimated:YES];
                         }];
        
        
        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    //}
    
//    self.inputToolBarView.sendButton.enabled = ([textView.text trimWhitespace].length > 0);
}

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification
{
    isKeyboardVisible=true;
    if([self.inputToolBarView.textView hasText]||isKeyboardVisible) {
        placeholderLabel.hidden = YES;
    }
    else{
        placeholderLabel.hidden = NO;
    }

//    [self show];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    // make your gesture recognizer priority
    singleTap.numberOfTapsRequired = 1;
    [self.detailedInterestTableView addGestureRecognizer:singleTap];

        //self.navigationItem.hidesBackButton = YES;
    [self keyboardWillShowHide:notification];
}

- (void)handleWillHideKeyboard:(NSNotification *)notification
{
    isKeyboardVisible=false;
    if([self.inputToolBarView.textView hasText]||isKeyboardVisible) {
        placeholderLabel.hidden = YES;
    }
    else{
        placeholderLabel.hidden = NO;
    }

//    [self hide];
    
    for (UIGestureRecognizer *recognizer in self.detailedInterestTableView.gestureRecognizers) {
        
        if([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            [self.detailedInterestTableView removeGestureRecognizer:recognizer];
        }
    }
        //self.navigationItem.hidesBackButton = NO;
    [self keyboardWillShowHide:notification];
}

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve
{
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            return UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;
            break;
    }
    
    return kNilOptions;
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:[self animationOptionsForCurve:curve]
                     animations:^{
                         CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;
                         
                         CGRect inputViewFrame = self.inputToolBarView.frame;
                         CGFloat inputViewFrameY = keyboardY - inputViewFrame.size.height;
                         
                         // for ipad modal form presentations
//                         CGFloat messageViewFrameBottom = self.view.frame.size.height - INPUT_HEIGHT;
//                         if(inputViewFrameY > messageViewFrameBottom)
//                             inputViewFrameY = messageViewFrameBottom;
                         
                         self.inputToolBarView.frame = CGRectMake(inputViewFrame.origin.x,
                                                                  inputViewFrameY,
                                                                  inputViewFrame.size.width,
                                                                  inputViewFrame.size.height);
                         
                         UIEdgeInsets insets = self.originalTableViewContentInset;
//                         insets.bottom = self.view.frame.size.height - self.inputToolBarView.frame.origin.y - inputViewFrame.size.height;
                         
                         insets.bottom = self.view.frame.size.height - INPUT_HEIGHT-self.inputToolBarView.frame.origin.y;
                         
                         self.detailedInterestTableView.contentInset = insets;
                         self.detailedInterestTableView.scrollIndicatorInsets = insets;
                          [self scrollToBottomAnimated:YES];
                     }
                     completion:^(BOOL finished) {
                         
                         //[self scrollToBottomAnimated:YES];
                     }];
}

#pragma mark - Dismissive text view delegate
- (void)keyboardDidScrollToPoint:(CGPoint)pt
{
    CGRect inputViewFrame = self.inputToolBarView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:pt fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.inputToolBarView.frame = inputViewFrame;
}

- (void)keyboardWillBeDismissed
{
    CGRect inputViewFrame = self.inputToolBarView.frame;
    inputViewFrame.origin.y = self.view.bounds.size.height - inputViewFrame.size.height;
    self.inputToolBarView.frame = inputViewFrame;
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
