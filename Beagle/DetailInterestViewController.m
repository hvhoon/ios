//
//  DetailInterestViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "DetailInterestViewController.h"
#import "BeagleActivityClass.h"
#import "BeaglePlayerScrollMenu.h"
#import "PlayerProfileItem.h"
#import "InterestChatClass.h"
#import "HomeTableViewCell.h"
#import "MessageKeyboardView.h"
#import "IconDownloader.h"
#import "ActivityViewController.h"
static NSString * const CellIdentifier = @"cell";
@interface DetailInterestViewController ()<BeaglePlayerScrollMenuDelegate,ServerManagerDelegate,UIGestureRecognizerDelegate,UITableViewDelegate,UITableViewDataSource,IconDownloaderDelegate>

@property(nonatomic,strong)ServerManager*chatPostManager;
@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@property (strong, nonatomic) UIView *backgroundView1;
@property (strong, nonatomic) UIImageView *profileImageView;
@property (strong, nonatomic) UIImageView *triangle;
@property (strong,nonatomic)BeaglePlayerScrollMenu *scrollMenu;
@property(nonatomic,strong)ServerManager*interestUpdateManager;
@property(nonatomic,strong)NSMutableArray *chatPostsArray;
@property(nonatomic,strong)UITableView *detailedInterestTableView;
@property (nonatomic, strong) MessageKeyboardView *contentWrapper;
@end

@implementation DetailInterestViewController
@synthesize interestActivity,interestServerManager=_interestServerManager,backgroundView1=_backgroundView1;
@synthesize scrollMenu=_scrollMenu;
@synthesize imageDownloadsInProgress;
@synthesize interestUpdateManager=_interestUpdateManager;
@synthesize profileImageView=_profileImageView;
@synthesize chatPostManager=_chatPostManager;
@synthesize chatPostsArray;
@synthesize isRedirectedFromNotif;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [UIApplication sharedApplication].statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    if(BG.activityDeleted){
        BG.activityDeleted=FALSE;
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if(self.interestActivity.dosRelation==0){
        
        NSString* screenTitle = [BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:self.interestActivity.endActivityDate];
        self.navigationItem.title = screenTitle;
        [self.detailedInterestTableView reloadData];
    }
}
-(void)viewDidAppear:(BOOL)animated{
    [self.contentWrapper _registerForNotifications];
    
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.contentWrapper _unregisterForNotifications];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.topItem.title = @"";
    
    _triangle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Triangle"]];
    _triangle.hidden = YES;
    
    if(!isRedirectedFromNotif)
      [self createInterestInitialCard];

}

-(void)createInterestInitialCard{
    if(self.interestActivity.dosRelation==0){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
        
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
    self.contentWrapper.frame = self.view.bounds;
    self.contentWrapper.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.contentWrapper];
    
    [self.contentWrapper.inputView.rightButton addTarget:self action:@selector(postClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if(!self.interestActivity.isParticipant){
        [self.contentWrapper.inputView setHidden:YES];
        [self.contentWrapper.dummyInputView setHidden:YES];
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
    if([[self.contentWrapper.inputView.textView text]length]!=0){
        
    [self.contentWrapper.inputView.textView resignFirstResponder];
    // For dummyInputView.textView
    [self.view endEditing:YES];
    
    if(_chatPostManager!=nil){
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
    }
    
    _chatPostManager=[[ServerManager alloc]init];
    _chatPostManager.delegate=self;
    [_chatPostManager postAComment:self.interestActivity.activityId desc:[self.contentWrapper.inputView.textView text]];
    

    NSLog(@"text1=%@",[self.contentWrapper.inputView.textView text]);
    NSLog(@"text2=%@",[self.contentWrapper.dummyInputView.textView text]);
    [self.contentWrapper.inputView.textView setText:nil];
    [self.contentWrapper textViewDidChange:self.contentWrapper.inputView.textView];
    
    [self.contentWrapper.dummyInputView.textView setText:nil];
    [self.contentWrapper textViewDidChange:self.contentWrapper.dummyInputView.textView];
    
    UIEdgeInsets contentInset = self.detailedInterestTableView.contentInset;
    contentInset.bottom = 0;
    self.detailedInterestTableView.contentInset = contentInset;
    
    UIEdgeInsets scrollIndicatorInsets = self.detailedInterestTableView.scrollIndicatorInsets;
    
    scrollIndicatorInsets.bottom = 0;
    self.detailedInterestTableView.scrollIndicatorInsets = scrollIndicatorInsets;

    [self.detailedInterestTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                          atScrollPosition:UITableViewScrollPositionTop
                                                  animated:YES];
    [self.detailedInterestTableView reloadData];

    }

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
            [_interestUpdateManager removeMembership:self.interestActivity.activityId];
        }
        else{
            [_interestUpdateManager participateMembership:self.interestActivity.activityId];
        }
        
    }
  }

- (void)loadProfileImage:(NSString*)url {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    interestActivity.profilePhotoImage=image;
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:100.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
                
                
                
                
                id interest=[response objectForKey:@"interest"];
                if (interest != nil && [interest class] != [NSNull class]) {
                    
                    
                    if(isRedirectedFromNotif){
                        self.interestActivity=[[BeagleActivityClass alloc]initWithDictionary:interest];
                        [self createInterestInitialCard];

                    }
                    id participants=[interest objectForKey:@"participants"];
                    if (participants != nil && [participants class] != [NSNull class] && [participants count]!=0) {
                        NSMutableArray *participantsArray=[[NSMutableArray alloc]init];
                        for(id el in participants){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithDictionary:el];
                            [participantsArray addObject:userClass];
                        }
                        self.interestActivity.participantsArray=participantsArray;
//                        [self setUpPlayerScroll:participantsArray];

                        
                    }
                     id chats=[interest objectForKey:@"chats"];
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
                    
                }
                
                

                
            }
        }
        
        
    }
    
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            id message=[response objectForKey:@"message"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                UILabel *participantsCountTextLabel=(UILabel*)[self.view viewWithTag:347];
                if([message isEqualToString:@"Joined"]){
                    self.interestActivity.participantsCount++;
                    
                }else{
                    self.interestActivity.participantsCount--;
                    
                }
                if(self.interestActivity.participantsCount>0 && self.interestActivity.dos2Count>0){
                    
                    participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count];
                }else{
                     participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
                }
                UIImageView *starImageView=(UIImageView*)[self.view viewWithTag:345];

                if(self.interestActivity.isParticipant){
                    self.interestActivity.isParticipant=FALSE;
                    starImageView.image=[UIImage imageNamed:@"Star-Unfilled"];
                    [self.contentWrapper.inputView setHidden:YES];
                    [self.contentWrapper.dummyInputView setHidden:YES];
                    NSMutableArray *testArray=[NSMutableArray new];
                    for(BeagleUserClass *data in self.interestActivity.participantsArray){
                        if(data.beagleUserId!=[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
        
                            [testArray addObject:data];
                        }
                    }
                    self.interestActivity.participantsArray=testArray;

                }
                else{
                    self.interestActivity.isParticipant=TRUE;
                    starImageView.image=[UIImage imageNamed:@"Star"];
                        [self.contentWrapper.inputView setHidden:NO];
                        [self.contentWrapper.dummyInputView setHidden:NO];
                        NSMutableArray*interestArray=[NSMutableArray new];
                    
                    if([self.interestActivity.participantsArray count]!=0){
                        [interestArray addObject:[[BeagleManager SharedInstance]beaglePlayer]];
                        [interestArray addObjectsFromArray:self.interestActivity.participantsArray];
                         self.interestActivity.participantsArray=interestArray;
                    }else{
                        [interestArray addObject:[[BeagleManager SharedInstance]beaglePlayer]];
                        self.interestActivity.participantsArray=interestArray;
                    }
                    [self.contentWrapper _setInitialFrames];

                }
                
                

            }
        }
        
    }
    else if (serverRequest==kServerCallPostComment){
        
        
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id activity_chat=[response objectForKey:@"activity_chat"];
                if (activity_chat != nil && [activity_chat class] != [NSNull class]) {
                    if(self.chatPostsArray==nil){
                        self.chatPostsArray=[NSMutableArray new];
                    }
                    
                    InterestChatClass *chatClass=[[InterestChatClass alloc]initWithDictionary:activity_chat];
                    [self.chatPostsArray addObject:chatClass];
                    
                     self.interestActivity.postCount++;

                        }
                
                
                
                
            }
        }
        
        
    }
    [self.detailedInterestTableView reloadData];
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
    }
    else if(serverRequest==kServerCallPostComment)
    {
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
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
    }
    else if(serverRequest==kServerCallPostComment)
    {
        _chatPostManager.delegate = nil;
        [_chatPostManager releaseServerManager];
        _chatPostManager = nil;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
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
        CGFloat cardHeight=0.0;
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
    
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                           [UIColor blackColor],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
        CGSize maximumLabelSize = CGSizeMake(288,999);
    
        CGRect textRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
        
        if(self.interestActivity.participantsCount==0)
            cardHeight=113.0+textRect.size.height;
        else
            cardHeight=218.0+textRect.size.height;
        
        return cardHeight;
    }
    
    else{
        {
            InterestChatClass *chatCell=[self.chatPostsArray objectAtIndex:indexPath.row-1];
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setAlignment:NSTextAlignmentLeft];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIFont systemFontOfSize:15.0f], NSFontAttributeName,
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

        CGFloat fromTheTop = 8.0f;

        static NSString *CellIdentifier = @"MediaTableCell";
        
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsZero;
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
        
        cell.backgroundColor = [UIColor whiteColor];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                               [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];
        
        // Setting up the card (background)
        UIView *_backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, fromTheTop, 320, 400)];
        _backgroundView.backgroundColor=[UIColor whiteColor];
        
        // Profile picture
        _profileImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, fromTheTop, 50, 50)];
        [_backgroundView addSubview:_profileImageView];
        if(interestActivity.profilePhotoImage==nil){
            
            [self imageCircular:[UIImage imageNamed:@"picbox"]];
            
            
            NSOperationQueue *queue = [NSOperationQueue new];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                initWithTarget:self
                                                selector:@selector(loadProfileImage:)
                                                object:interestActivity.photoUrl];
            [queue addOperation:operation];
            
        }
        else{
            _profileImageView.image=[BeagleUtilities imageCircularBySize:interestActivity.profilePhotoImage sqr:100.0f];
        }
        
        
        // Location information
        [style setAlignment:NSTextAlignmentRight];
        UIColor *color=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
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
               [UIColor blackColor],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        CGSize organizerNameSize=[interestActivity.organizerName boundingRectWithSize:CGSizeMake(300, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
        
        UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75,55.5-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height)];
        
        organizerNameLabel.backgroundColor = [UIColor clearColor];
        organizerNameLabel.text = interestActivity.organizerName;
        organizerNameLabel.textColor = [UIColor blackColor];
        organizerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        organizerNameLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:organizerNameLabel];
        
        // Adding the appropriate DOS icon
        if(self.interestActivity.dosRelation==1) {
            UIImageView *dos1RelationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(75+8+organizerNameSize.width, 38.5, 27, 15)];
            dos1RelationImageView.image = [UIImage imageNamed:@"DOS2"];
            [_backgroundView addSubview:dos1RelationImageView];
        }
        else if(self.interestActivity.dosRelation==2){
            UIImageView *dos2RelationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(75+8+organizerNameSize.width, 38.5, 32, 15)];
            dos2RelationImageView.image = [UIImage imageNamed:@"DOS3"];
            [_backgroundView addSubview:dos2RelationImageView];
        }
        
        // Adding the height of the profile picture
        fromTheTop = fromTheTop+50.0f;
        
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
        [_backgroundView addSubview:activityDescLabel];
        
        fromTheTop = fromTheTop+commentTextRect.size.height;
        fromTheTop = fromTheTop+16.0f; // buffer after the description
        
        // Number of participants
        
        // If there is more than 1 participant
        if(self.interestActivity.participantsCount > 0) {
            attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                   [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                   [UIColor blackColor],NSForegroundColorAttributeName,
                   style, NSParagraphStyleAttributeName, nil];
            CGSize participantsCountTextSize;
            UILabel *participantsCountTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,fromTheTop,
                                                                                            participantsCountTextSize.width, participantsCountTextSize.height)];
            
            participantsCountTextLabel.backgroundColor = [UIColor clearColor];
            participantsCountTextLabel.textColor = [UIColor blackColor];
            participantsCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
            participantsCountTextLabel.textAlignment = NSTextAlignmentLeft;
            participantsCountTextLabel.tag=347;
            
            // Are any of your friends participants?
            if (self.interestActivity.dos2Count>0) {
                participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                
                participantsCountTextLabel.frame=CGRectMake(16, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height);
                
                participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count];
                
                [_backgroundView addSubview:participantsCountTextLabel];
            }
            else {
                participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
                
                participantsCountTextLabel.frame=CGRectMake(16, fromTheTop, participantsCountTextSize.width, participantsCountTextSize.height);
                
                participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
                
                [_backgroundView addSubview:participantsCountTextLabel];
            }
            
            fromTheTop = fromTheTop + participantsCountTextSize.height;
            fromTheTop = fromTheTop + 16.0f; // Added buffer at the end of the participant count
            
            
            // Setup the participants panel
            [style setAlignment:NSTextAlignmentLeft];
            attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
            if(self.interestActivity.ownerid==[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
            //owner
                if(self.interestActivity.participantsCount>0){
                    if(_scrollMenu==nil)
                        _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, fromTheTop, 268, 55)];
                    [_backgroundView addSubview:_scrollMenu];
                    [self setUpPlayerScroll:self.interestActivity.participantsArray];
                }
            }
            else {
            //not a owner but a participant
                if(self.interestActivity.participantsCount>0){
                    if(_scrollMenu==nil)
                        _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, fromTheTop, 268, 55)];
                    [_backgroundView addSubview:_scrollMenu];
                    [self setUpPlayerScroll:self.interestActivity.participantsArray];
                }
            }
            fromTheTop = fromTheTop + 55.0f;
            fromTheTop = fromTheTop + 16.0f;
        }
    
        // Adding the star image
        UIImageView *starImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, fromTheTop, 19, 18)];
        starImageView.tag=345;
        [_backgroundView addSubview:starImageView];
        
        if(self.interestActivity.isParticipant)
            starImageView.image=[UIImage imageNamed:@"Star"];
        else
            starImageView.image=[UIImage imageNamed:@"Star-Unfilled"];
        
        // Adding the interested text
        
        NSString *interestedText = nil;
        
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue" size:15.0f], NSFontAttributeName,
               [BeagleUtilities returnBeagleColor:1],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        // If it's the organizer
        if (self.interestActivity.dosRelation==0) {
            interestedText = @"Created by you";
            attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                   [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f], NSFontAttributeName, [BeagleUtilities returnBeagleColor:1], NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
        }
        // If you are the first one to express interest
        else if(self.interestActivity.dosRelation > 0 && self.interestActivity.participantsCount == 0) {
            interestedText = @"Be the first to join";
        }
        // You are not the organizer and have already expressed interest
        else if(self.interestActivity.dosRelation > 0 && self.interestActivity.isParticipant)
        {
            interestedText = @"Count me in";
            attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                   [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f], NSFontAttributeName, [BeagleUtilities returnBeagleColor:1], NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
        }
        // You are not the organizer and have not expressed interest
        else
            interestedText = @"Are you in?";
        
        CGSize interestedSize = [interestedText boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
        
        UILabel *interestedLabel = [[UILabel alloc] initWithFrame:CGRectMake(16+19+5, fromTheTop, interestedSize.width, interestedSize.height)];
        interestedLabel.tag=346;
        
        //interestedLabel.text = interestedText;
        interestedLabel.attributedText = [[NSAttributedString alloc] initWithString:interestedText attributes:attrs];
        
        [_backgroundView addSubview:interestedLabel];
    
        interestedLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestures:)];
        [interestedLabel addGestureRecognizer:tapGesture];
        
        fromTheTop = fromTheTop + 3.0f; // buffer
        
        // Adding the comments icon
        UIImageView *commentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(304-21, fromTheTop, 21, 18)];
        [_backgroundView addSubview:commentImageView];
        
        // Are there comments already?
        if(self.interestActivity.postCount>0) {
            commentImageView.image=[UIImage imageNamed:@"Comment-Blue"];
            
            [style setAlignment:NSTextAlignmentLeft];
            
            attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                     [BeagleUtilities returnBeagleColor:1], NSForegroundColorAttributeName,
                     style, NSParagraphStyleAttributeName, nil];
            
            CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)self.interestActivity.postCount]  boundingRectWithSize:CGSizeMake(288, 999) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
            
            UILabel *postCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(301-21-postCountTextSize.width, fromTheTop-1, postCountTextSize.width, postCountTextSize.height)];
            
            postCountLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",(long)self.interestActivity.postCount] attributes:attrs];
            
            _triangle.frame = CGRectMake(304-19, fromTheTop+21, 17, 9);
            [_backgroundView addSubview:_triangle];
            [_backgroundView addSubview:postCountLabel];
            
            fromTheTop = fromTheTop + 9.0f;
        }
        // If no comments have been added yet
        else
            commentImageView.image=[UIImage imageNamed:@"Add-Comment"];
        
        fromTheTop = fromTheTop + 21.0f;
        
        _backgroundView.frame=CGRectMake(0, 0, 320, fromTheTop);
        [cell.contentView addSubview:_backgroundView];
        
        return cell;
    }
    
    // For the COMMENTS part of the card
    else {
        
        CGFloat cellTop = 0.0f;
        
        if(indexPath.row==1)
            cellTop = 16.0f;
        else
            cellTop = 8.0f;
        
        [_triangle setHidden:NO];
        
        static NSString *CellIdentifier = @"MediaTableCell2";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell  =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor=[BeagleUtilities returnBeagleColor:5];
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
