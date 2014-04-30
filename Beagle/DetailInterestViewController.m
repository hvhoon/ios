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
static NSString * const CellIdentifier = @"cell";
@interface DetailInterestViewController ()<BeaglePlayerScrollMenuDelegate,ServerManagerDelegate,UIGestureRecognizerDelegate,UITableViewDelegate,UITableViewDataSource,IconDownloaderDelegate>

@property(nonatomic,strong)ServerManager*chatPostManager;
@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@property (strong, nonatomic) UIView *backgroundView1;
@property (strong, nonatomic) UIImageView *profileImageView;
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
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];

    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                           [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];
    
    CGSize dateTextSize = [[BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:self.interestActivity.endActivityDate] boundingRectWithSize:CGSizeMake(300, 999)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil].size;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, dateTextSize.width, dateTextSize.height)];
    
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = [BeagleUtilities activityTime:self.interestActivity.startActivityDate endate:self.interestActivity.endActivityDate];
    titleLabel.textColor = [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
    
    self.detailedInterestTableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStylePlain];
    self.detailedInterestTableView.dataSource = self;
    self.detailedInterestTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.detailedInterestTableView.delegate = self;
    self.detailedInterestTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.detailedInterestTableView setBackgroundColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0]];

//    [self.detailedInterestTableView registerClass:[UITableViewCell class]
//                           forCellReuseIdentifier:CellIdentifier];

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
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:52.0f];
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
    
    if(indexPath.row==0){
    CGFloat variance=0.0;
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentLeft];
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                           [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect textRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attrs
                                                      context:nil];
        
        if(self.interestActivity.participantsCount==0){
            variance=72+textRect.size.height+16+17;
            
            if(self.interestActivity.ownerid!=[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
                variance=variance+30;
            }
            
        }else{
            variance=72+textRect.size.height+16+18+16+55;
        }

        return variance+52.0f;
    }else{
        {
            InterestChatClass *chatCell=[self.chatPostsArray objectAtIndex:indexPath.row-1];
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setAlignment:NSTextAlignmentLeft];
            
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIFont fontWithName:@"HelveticaNeue" size:14.0f], NSFontAttributeName,
                                   [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                                   style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
            
            
            CGSize maximumLabelSize = CGSizeMake(288,999);
            
            CGRect textRect = [chatCell.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                            attributes:attrs
                                                                               context:nil];
            
            return 67.0f+textRect.size.height;
        }
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.row==0){

        static NSString *CellIdentifier = @"MediaTableCell";
        
        
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//        if (cell == nil) {
            cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
//        }

//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
//                                                            forIndexPath:indexPath];
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
        
        cell.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                               [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];

    

        UIView *_backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, 8, 320, 400)];
        _backgroundView.backgroundColor=[UIColor whiteColor];
        
        _profileImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, 8, 52, 52)];
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
            _profileImageView.image=[BeagleUtilities imageCircularBySize:interestActivity.profilePhotoImage sqr:52.0];
        }
        
        
        
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
        
        UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(304-locationTextSize.width,8, locationTextSize.width, locationTextSize.height)];
        
        locationLabel.backgroundColor = [UIColor clearColor];
        locationLabel.text = interestActivity.locationName;
        locationLabel.textColor = color;
        locationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        locationLabel.textAlignment = NSTextAlignmentRight;
        [_backgroundView addSubview:locationLabel];
        
        [style setAlignment:NSTextAlignmentLeft];
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
               [UIColor blackColor],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        CGSize organizerNameSize=[interestActivity.organizerName boundingRectWithSize:CGSizeMake(300, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
        
        UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(76,52-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height)];
        
        organizerNameLabel.backgroundColor = [UIColor clearColor];
        organizerNameLabel.text = interestActivity.organizerName;
        organizerNameLabel.textColor = [UIColor blackColor];
        organizerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        organizerNameLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:organizerNameLabel];
        
        
        UIImageView *dosRelationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(76+10+organizerNameSize.width,52-15, 27, 15)];
        if(self.interestActivity.dosRelation==1)
            dosRelationImageView.image = [UIImage imageNamed:@"DOS2"];
        else if(self.interestActivity.dosRelation==2){
            dosRelationImageView.image = [UIImage imageNamed:@"DOS3"];
        }
        else{
            dosRelationImageView.image = nil;
        }
        [_backgroundView addSubview:dosRelationImageView];
        
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                 [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
        
        CGSize maximumLabelSize = CGSizeMake(288,999);
        
        CGRect commentTextRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                               attributes:attrs
                                                                                  context:nil];
        
        
        
        UILabel *activityDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72,commentTextRect.size.width,commentTextRect.size.height)];
        activityDescLabel.numberOfLines=0;
        activityDescLabel.lineBreakMode=NSLineBreakByWordWrapping;
        activityDescLabel.backgroundColor = [UIColor clearColor];
        activityDescLabel.text = interestActivity.activityDesc;
        activityDescLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
        activityDescLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        activityDescLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:activityDescLabel];
        
        
        
        
        
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
               [UIColor blackColor],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        CGSize participantsCountTextSize;
        UILabel *participantsCountTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72+commentTextRect.size.height+16,
                                                                                        participantsCountTextSize.width, participantsCountTextSize.height)];
        
        participantsCountTextLabel.backgroundColor = [UIColor clearColor];
        participantsCountTextLabel.textColor = [UIColor blackColor];
        participantsCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        participantsCountTextLabel.textAlignment = NSTextAlignmentLeft;
        participantsCountTextLabel.tag=347;

        if(self.interestActivity.participantsCount==0){
            
            
            participantsCountTextSize = [@"No participants" boundingRectWithSize:CGSizeMake(300, 999)
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                                          attributes:attrs
                                                                             context:nil].size;
            
            
            participantsCountTextLabel.frame=CGRectMake(16,72+commentTextRect.size.height+16,
                                                        participantsCountTextSize.width, participantsCountTextSize.height);

            
            participantsCountTextLabel.backgroundColor = [UIColor clearColor];
            participantsCountTextLabel.text = @"No participants";
            participantsCountTextLabel.textColor = [UIColor blackColor];
            participantsCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
            participantsCountTextLabel.textAlignment = NSTextAlignmentLeft;
            [_backgroundView addSubview:participantsCountTextLabel];
            
   
        }
        else if(self.interestActivity.participantsCount>0 && self.interestActivity.dos2Count>0){
        
            
            participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                                                                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                                                                                     attributes:attrs
                                                                                                                                                                                                        context:nil].size;
            
            participantsCountTextLabel.frame=CGRectMake(16,72+commentTextRect.size.height+16,
                                                        participantsCountTextSize.width, participantsCountTextSize.height);
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count];
            
            
            [_backgroundView addSubview:participantsCountTextLabel];

            
            
        }else if(self.interestActivity.participantsCount>0){
            
            participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                                attributes:attrs
                                                                                                                                                   context:nil].size;
            participantsCountTextLabel.frame=CGRectMake(16,72+commentTextRect.size.height+16,
                                                        participantsCountTextSize.width, participantsCountTextSize.height);
            participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
            [_backgroundView addSubview:participantsCountTextLabel];

        }
        
        [style setAlignment:NSTextAlignmentLeft];
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGFloat variance=0.0f;
        variance=72+commentTextRect.size.height+16+participantsCountTextSize.height;

        if(self.interestActivity.ownerid==[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
            //owner
            if(self.interestActivity.participantsCount>0){
                if(_scrollMenu==nil)
                _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, 72+commentTextRect.size.height+16+participantsCountTextSize.height+16, 268, 55)];
                [_backgroundView addSubview:_scrollMenu];
                [self setUpPlayerScroll:self.interestActivity.participantsArray];
                variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+55;
            }
        }
        else {
            //not a owner but a participant
            if(self.interestActivity.participantsCount>0){
                if(_scrollMenu==nil)
                _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, 72+commentTextRect.size.height+16+participantsCountTextSize.height+16, 268, 55)];
                [_backgroundView addSubview:_scrollMenu];
                [self setUpPlayerScroll:self.interestActivity.participantsArray];
                variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+55;
                
                
            }
            else{
                CGSize noParticipantsTextSize = [@"Be the first one to express interest!" boundingRectWithSize:CGSizeMake(300, 999)
                                                                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                    attributes:attrs
                                                                                                       context:nil].size;
                
                UILabel *noParticipantsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72+commentTextRect.size.height+16+participantsCountTextSize.height+16, noParticipantsTextSize.width, noParticipantsTextSize.height)];
                
                noParticipantsLabel.backgroundColor = [UIColor clearColor];
                noParticipantsLabel.text = @"Be the first one to express interest!";
                noParticipantsLabel.textColor = [UIColor blackColor];
                noParticipantsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
                noParticipantsLabel.textAlignment = NSTextAlignmentLeft;
                [_backgroundView addSubview:noParticipantsLabel];
                variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+noParticipantsTextSize.height;
                
                
            }
        }
        
        
        UIImageView *starImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, variance+16, 16, 15)];
        starImageView.tag=345;
        [_backgroundView addSubview:starImageView];
        
        if(self.interestActivity.isParticipant){
            
            starImageView.image=[UIImage imageNamed:@"Star"];
            
        }
        
        else{
            
            starImageView.image=[UIImage imageNamed:@"Star-Unfilled"];
            
        }
        
        attrs=[NSDictionary dictionaryWithObjectsAndKeys:
               [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f], NSFontAttributeName,
               [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
               style, NSParagraphStyleAttributeName, nil];
        
        
        
        
        CGSize interestedSize = [@"I'm Interested"  boundingRectWithSize:CGSizeMake(288, 999)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:attrs
                                                                 context:nil].size;
        
        UILabel *interestedLabel = [[UILabel alloc] initWithFrame:CGRectMake(42,variance+16, interestedSize.width, interestedSize.height)];
        interestedLabel.tag=346;
        interestedLabel.backgroundColor = [UIColor clearColor];
        interestedLabel.text = @"I'm Interested";
        interestedLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
        interestedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
        interestedLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:interestedLabel];
        
        interestedLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestures:)];
        [interestedLabel addGestureRecognizer:tapGesture];
        
        
        
        UIImageView *commentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(306-21, variance+16, 21, 18)];
        [_backgroundView addSubview:commentImageView];
        
        if(self.interestActivity.postCount>0)
            commentImageView.image=[UIImage imageNamed:@"Comment"];
        else{
            commentImageView.image=[UIImage imageNamed:@"Add-Comment"];
        }
        
        [style setAlignment:NSTextAlignmentLeft];
        
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                 [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)self.interestActivity.postCount]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                        attributes:attrs
                                                                                                                           context:nil].size;
        
        UILabel *postCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(300-21- postCountTextSize.width,variance+16-2, postCountTextSize.width, postCountTextSize.height)];
        
        postCountLabel.backgroundColor = [UIColor clearColor];
        postCountLabel.text = [NSString stringWithFormat:@"%ld",(long)self.interestActivity.postCount];
        postCountLabel.textColor = [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
        postCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        postCountLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:postCountLabel];
        
        
        _backgroundView.frame=CGRectMake(0, 8, 320, variance+16+18+16);
        [cell.contentView addSubview:_backgroundView];
        
    
    return cell;

    
    }else{
        
        static NSString *CellIdentifier = @"MediaTableCell2";
        
        
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//        if (cell == nil) {
            cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
//        }

//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
//                                                                forIndexPath:indexPath];
        
        cell.backgroundColor=[UIColor colorWithRed:230.0/255.0 green:240.0/255.0 blue:255.0/255.0 alpha:1.0];
        
        InterestChatClass *chatCell=[self.chatPostsArray objectAtIndex:indexPath.row-1];
        UIImageView *cellImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, 8, 35, 35)];
        
        if (!chatCell.playerImage)
        {
            if (tableView.dragging == NO && tableView.decelerating == NO)
            {
                [self startIconDownload:chatCell forIndexPath:indexPath];
            }
            // if a download is deferred or in progress, return a placeholder image
            
            cellImageView.image = [BeagleUtilities imageCircularBySize:[UIImage imageNamed:@"picbox.png"] sqr:35.0f];
            
        }
        else
        {
            cellImageView.image = chatCell.playerImage;
        }
        cellImageView.tag=[[NSString stringWithFormat:@"111%li",(long)indexPath.row]integerValue];
        [cell.contentView addSubview:cellImageView];
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        UIColor *color=[UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f], NSFontAttributeName,
                               color,NSForegroundColorAttributeName,
                               style, NSParagraphStyleAttributeName, nil];

        CGSize organizerNameSize=[chatCell.player_name boundingRectWithSize:CGSizeMake(300, 999)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil].size;

        UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(61,16, organizerNameSize.width, organizerNameSize.height)];
        
        organizerNameLabel.backgroundColor = [UIColor clearColor];
        organizerNameLabel.text = chatCell.player_name;
        organizerNameLabel.textColor = [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0];
        organizerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f];
        organizerNameLabel.textAlignment = NSTextAlignmentLeft;
        [cell.contentView addSubview:organizerNameLabel];
        
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f], NSFontAttributeName,
                 color,NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];

        
        
        NSString *timestamp=[BeagleUtilities calculateChatTimestamp:chatCell.timestamp];
        
        CGSize dateTextSize = [timestamp boundingRectWithSize:CGSizeMake(300,999)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:attrs
                                                           context:nil].size;

        
        UILabel *timeStampLabel = [[UILabel alloc] initWithFrame:CGRectMake(61,16+organizerNameSize.height+3, dateTextSize.width, dateTextSize.height)];
        
        timeStampLabel.backgroundColor = [UIColor clearColor];
        timeStampLabel.text = timestamp;
        timeStampLabel.textColor = color;
        timeStampLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
        timeStampLabel.textAlignment = NSTextAlignmentLeft;
        [cell.contentView  addSubview:timeStampLabel];
        
        attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue" size:14.0f], NSFontAttributeName,
                 [UIColor blackColor],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
        
        CGSize maximumLabelSize = CGSizeMake(288,999);
        
        CGRect commentTextRect = [chatCell.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                          attributes:attrs
                                                                             context:nil];
        
        
            
            
            
            UILabel *chatDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,51,commentTextRect.size.width,commentTextRect.size.height)];
            chatDescLabel.numberOfLines=0;
            chatDescLabel.lineBreakMode=NSLineBreakByWordWrapping;
            chatDescLabel.backgroundColor = [UIColor clearColor];
            chatDescLabel.text = chatCell.text;
            chatDescLabel.textColor = [UIColor blackColor];
            chatDescLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
            chatDescLabel.textAlignment = NSTextAlignmentLeft;
            [cell.contentView addSubview:chatDescLabel];

        if(indexPath.row!=[self.chatPostsArray count]){
        UIView *seperatorLineView=[[UIView alloc]initWithFrame:CGRectMake(16,51+commentTextRect.size.height+7,288,1)];
            seperatorLineView.alpha=0.5;
        [seperatorLineView setBackgroundColor:[UIColor grayColor]];
                    [cell.contentView addSubview:seperatorLineView];
        }
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
        UITableViewCell *cell = (UITableViewCell*)[self.detailedInterestTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        UIImageView *cellImageView=(UIImageView*)[cell viewWithTag:[[NSString stringWithFormat:@"111%ld",indexPath.row]integerValue]];
        iconDownloader.chatRecord.playerImage= [BeagleUtilities imageCircularBySize:iconDownloader.chatRecord.playerImage sqr:35.0f];
        // Display the newly loaded image
        cellImageView.image = iconDownloader.chatRecord.playerImage ;
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
