//
//  FriendsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "FriendsViewController.h"
#import "BeagleUserClass.h"
#import "FriendsTableViewCell.h"
#import "IconDownloader.h"
#import "BeagleNotificationClass.h"
#import "DetailInterestViewController.h"
@interface FriendsViewController ()<ServerManagerDelegate,UITableViewDataSource,UITableViewDelegate,FriendsTableViewCellDelegate,IconDownloaderDelegate,InAppNotificationViewDelegate>{
    NSInteger inviteIndex;
}
@property(nonatomic,strong)ServerManager*friendsManager;
@property(nonatomic,strong)ServerManager*inviteManager;
@property(nonatomic,strong)NSArray *beagleFriendsArray;
@property(nonatomic,strong)NSArray *facebookFriendsArray;
@property(nonatomic,strong)IBOutlet UITableView*friendsTableView;
@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@end

@implementation FriendsViewController
@synthesize friendsManager=_friendsManager;
@synthesize friendBeagle;
@synthesize inviteFriends;
@synthesize inviteManager=_inviteManager;
@synthesize imageDownloadsInProgress;
@synthesize beagleFriendsArray=_beagleFriendsArray;
@synthesize facebookFriendsArray=_facebookFriendsArray;
@synthesize friendsTableView=_friendsTableView;
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
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

}
-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.friendsTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.friendsTableView.separatorInset = UIEdgeInsetsZero;
    self.friendsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.friendsTableView setBackgroundColor:[BeagleUtilities returnBeagleColor:2]];

    imageDownloadsInProgress=[NSMutableDictionary new];
    self.navigationController.navigationBar.topItem.title = @"";

    if(_friendsManager!=nil){
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
    }
    
    _friendsManager=[[ServerManager alloc]init];
    _friendsManager.delegate=self;
    if(inviteFriends)
        [_friendsManager getDOS1Friends];
     else
       [_friendsManager getMutualFriendsNetwork:self.friendBeagle.beagleUserId];
    
    if(!inviteFriends){
    UIView*navigationProfileView=[[UIView alloc]init];
    
    UIImageView *imageView=[[UIImageView alloc]initWithImage:[BeagleUtilities imageCircularBySize:[UIImage imageWithData:self.friendBeagle.profileData] sqr:70.0f]];
    imageView.frame=CGRectMake(0, 0, 35, 35);
    [navigationProfileView addSubview:imageView];
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentLeft];

    NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                         [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    CGSize friendNameSize=[self.friendBeagle.fullName boundingRectWithSize:CGSizeMake(300, 44)
                                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                                       attributes:attrs
                                                                          context:nil].size;
    
    UILabel *friendNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(40,0,friendNameSize.width, friendNameSize.height)];
    
    friendNameLabel.backgroundColor = [UIColor clearColor];
    friendNameLabel.text = self.friendBeagle.fullName;
    friendNameLabel.textColor = [BeagleUtilities returnBeagleColor:4];
    friendNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    friendNameLabel.textAlignment = NSTextAlignmentLeft;
    [navigationProfileView addSubview:friendNameLabel];
    
    
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f], NSFontAttributeName,
             [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
             style, NSParagraphStyleAttributeName, nil];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect mutualFriendsTextRect = [@"0 Mutual Friends" boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil];
    
    UILabel *mutualFriendsTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(40,friendNameSize.height+1,260,mutualFriendsTextRect.size.height)];
    mutualFriendsTextLabel.backgroundColor = [UIColor clearColor];
    mutualFriendsTextLabel.text = @"0 Mutual Friends";
    mutualFriendsTextLabel.textColor = [BeagleUtilities returnBeagleColor:4];
    mutualFriendsTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
    mutualFriendsTextLabel.textAlignment = NSTextAlignmentLeft;
    [navigationProfileView addSubview:mutualFriendsTextLabel];
    mutualFriendsTextLabel.tag=654;

    navigationProfileView.frame=CGRectMake(0, 4.5, friendNameSize.width+35+19, 35);
    self.navigationItem.titleView=navigationProfileView;
    }else{
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        
        NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                             [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                             [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake(288,999);
        
        CGRect inviteFriendsTextRect = [@"Invite Friends" boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil];
        
        UILabel *inviteFriendsTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,inviteFriendsTextRect.size.width,inviteFriendsTextRect.size.height)];
        inviteFriendsTextLabel.backgroundColor = [UIColor clearColor];
        inviteFriendsTextLabel.text = @"Invite Friends";
        inviteFriendsTextLabel.textColor = [BeagleUtilities returnBeagleColor:4];
        inviteFriendsTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
        inviteFriendsTextLabel.textAlignment = NSTextAlignmentLeft;
        self.navigationItem.titleView=inviteFriendsTextLabel;
        
//        [self.view addGestureRecognizer:self.slidingViewController.panGesture];


    }

    // Do any additional setup after loading the view.
}


- (void)didReceiveBackgroundInNotification:(NSNotification*) note{

    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationObject:note];
    
    if(!notifObject.isOffline){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithFrame:CGRectMake(0,0, 320, 64) appNotification:notifObject];
        notifView.delegate=self;
        UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
        [keyboard addSubview:notifView];
    }
    else if(notifObject.isOffline && notifObject.activityId!=0 && (notifObject.notificationType==WHAT_CHANGE_TYPE||notifObject.notificationType==DATE_CHANGE_TYPE||notifObject.notificationType==GOING_TYPE||notifObject.notificationType==LEAVED_ACTIVITY_TYPE)){
        
        [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        [viewController.interestServerManager getDetailedInterest:notifObject.activityId];
        [self.navigationController pushViewController:viewController animated:YES];        
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHomeAutoRefresh object:self userInfo:nil];

    
}


-(void)postInAppNotification:(NSNotification*)note{
    
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationForInterestPost:note];
    
    if(!notifObject.isOffline){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithFrame:CGRectMake(0, 0, 320, 64) appNotification:notifObject];
        notifView.delegate=self;
        
        UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
        [keyboard addSubview:notifView];
    }else if(notifObject.isOffline && notifObject.activityId!=0 && notifObject.notificationType==CHAT_TYPE){
        
        [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        [viewController.interestServerManager getDetailedInterest:notifObject.activityId];
        [self.navigationController pushViewController:viewController animated:YES];
        
        
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHomeAutoRefresh object:self userInfo:nil];

    
}

-(void)backgroundTapToPush:(BeagleNotificationClass *)notification{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
    viewController.interestServerManager=[[ServerManager alloc]init];
    viewController.interestServerManager.delegate=viewController;
    viewController.isRedirected=TRUE;
    if(notification.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;
    
    [viewController.interestServerManager getDetailedInterest:notification.activityId];
    [self.navigationController pushViewController:viewController animated:YES];    
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.beagleFriendsArray count]>0 && [self.facebookFriendsArray count]>0)
        return 2;
    else if([self.beagleFriendsArray count]>0 || [self.facebookFriendsArray count]>0)
        return 1;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    if([self.beagleFriendsArray count]>0 && [self.facebookFriendsArray count]>0){
        if(section==0)
            return [self.beagleFriendsArray count];
        else{
            return [self.facebookFriendsArray count];
        }
        
    }
    else if([self.beagleFriendsArray count]>0){
            return [self.beagleFriendsArray count];

    }
    else if ([self.facebookFriendsArray count]>0)
        return [self.facebookFriendsArray count];
    else
        return 0;
    
}

#define kSectionHeaderHeight    28.0
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return kSectionHeaderHeight;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *sectionHeaderview=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,kSectionHeaderHeight)];
    sectionHeaderview.backgroundColor=[BeagleUtilities returnBeagleColor:2];
    
    
    CGRect sectionLabelRect=CGRectMake(8,6.5,240,15);
    UILabel *sectionLabel=[[UILabel alloc] initWithFrame:sectionLabelRect];
    sectionLabel.textAlignment=NSTextAlignmentLeft;
    
    sectionLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
    sectionLabel.textColor=[BeagleUtilities returnBeagleColor:4];
    sectionLabel.backgroundColor=[UIColor clearColor];
    [sectionHeaderview addSubview:sectionLabel];

    
    if([self.beagleFriendsArray count]>0 && [self.facebookFriendsArray count]>0){
        if(section==0)
            sectionLabel.text=[NSString stringWithFormat:@"%ld ALREADY ON BEAGLE",(unsigned long)[self.beagleFriendsArray count]];
        else{
            sectionLabel.text=[NSString stringWithFormat:@"%ld POOR SOULS ARE MISSING OUT",(unsigned long)[self.facebookFriendsArray count]];
        }
        
    }
    else if([self.beagleFriendsArray count]>0){
        sectionLabel.text=[NSString stringWithFormat:@"%ld ALREADY ON BEAGLE",(unsigned long)[self.beagleFriendsArray count]];
        
    }
    else if ([self.facebookFriendsArray count]>0)
        sectionLabel.text=[NSString stringWithFormat:@"%ld POOR SOULS ARE MISSING OUT",(unsigned long)[self.facebookFriendsArray count]];

     return sectionHeaderview;
    
}
-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    return 51.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    FriendsTableViewCell *cell = (FriendsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //if (cell == nil) {
        cell =[[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    //}
    
    BeagleUserClass *player=nil;

    if([self.beagleFriendsArray count]>0 && [self.facebookFriendsArray count]>0){
        if(indexPath.section==0)
            player = (BeagleUserClass *)[self.beagleFriendsArray objectAtIndex:indexPath.row];
        else{
            player = (BeagleUserClass *)[self.facebookFriendsArray objectAtIndex:indexPath.row];
        }
        
    }
    else if([self.beagleFriendsArray count]>0){
        player = (BeagleUserClass *)[self.beagleFriendsArray objectAtIndex:indexPath.row];
        
    }
    else if ([self.facebookFriendsArray count]>0)
        player = (BeagleUserClass *)[self.facebookFriendsArray objectAtIndex:indexPath.row];

    cell.delegate=self;
    cell.cellIndexPath=indexPath;
    cell.bgPlayer = player;
    UIImage*checkImge=nil;
    if(player.beagleUserId!=0)
        checkImge= [BeagleUtilities loadImage:player.beagleUserId];
    
    if(checkImge==nil){
        
        if (!player.profileData)
        {
            if (tableView.dragging == NO && tableView.decelerating == NO)
            {
                [self startIconDownload:player forIndexPath:indexPath];
            }
            // if a download is deferred or in progress, return a placeholder image
            cell.photoImage = [UIImage imageNamed:@"picbox.png"];
            
        }
        else
        {
            cell.photoImage = [UIImage imageWithData:player.profileData];
        }
    }else{
        player.profileData=UIImagePNGRepresentation(checkImge);
        cell.photoImage =checkImge;
    }
    

    [cell setNeedsDisplay];
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}
- (void)startIconDownload:(BeagleUserClass*)appRecord forIndexPath:(NSIndexPath *)indexPath{
    IconDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.friendRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [self.imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload:kFriendRecord];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows{
    
    
    if([self.beagleFriendsArray count]>0 || [self.facebookFriendsArray count]>0){
        NSArray *visiblePaths = [self.friendsTableView indexPathsForVisibleRows];
    if([self.beagleFriendsArray count]>0 && [self.facebookFriendsArray count]>0){
        
        for (NSIndexPath *indexPath in visiblePaths)
        {
            BeagleUserClass *appRecord=nil;
                if(indexPath.section==0)
               appRecord = (BeagleUserClass *)[self.beagleFriendsArray objectAtIndex:indexPath.row];
                else{
                    appRecord = (BeagleUserClass *)[self.facebookFriendsArray objectAtIndex:indexPath.row];
                    
                }
            
            
            if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
        }
        
    }
    else if([self.beagleFriendsArray count]>0){
        for (NSIndexPath *indexPath in visiblePaths)
        {
            BeagleUserClass *appRecord=(BeagleUserClass *)[self.beagleFriendsArray objectAtIndex:indexPath.row];
            if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
        }
        
    }
    else if ([self.facebookFriendsArray count]>0){
        {
            for (NSIndexPath *indexPath in visiblePaths)
            {
                BeagleUserClass *appRecord=(BeagleUserClass *)[self.facebookFriendsArray objectAtIndex:indexPath.row];
                if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
            }
            
        }
    
    }
    }
}

- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        FriendsTableViewCell *cell = (FriendsTableViewCell*)[self.friendsTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        cell.photoImage =[UIImage imageWithData:iconDownloader.friendRecord.profileData];
        if(iconDownloader.friendRecord.beagleUserId!=0)
            [BeagleUtilities saveImage:cell.photoImage withFileName:iconDownloader.friendRecord.beagleUserId];
    }
    
    [self.friendsTableView reloadData];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Facebook Invite  calls
-(void)inviteFacebookFriendOnBeagle:(NSIndexPath*)indexPath{
    BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:indexPath.row];
    inviteIndex=indexPath.row;
    
    if(_inviteManager!=nil){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
    }
    
    _inviteManager=[[ServerManager alloc]init];
    _inviteManager.delegate=self;
    [_inviteManager sendingAPostMessageOnFacebook:player.fbuid];

    
}
-(void)userProfileSelected:(NSIndexPath*)indexPath{
    BeagleUserClass *player=[self.beagleFriendsArray objectAtIndex:indexPath.row];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
    viewController.friendBeagle=player;
    [self.navigationController pushViewController:viewController animated:YES];

}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallGetProfileMutualFriends||serverRequest==kServerCallGetDOS1Friends){
        
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id profile=[response objectForKey:@"profile"];
                if (profile != nil && [profile class] != [NSNull class]) {
                    
                    
                    NSArray *friend=[profile objectForKey:@"friend"];
                    if (friend != nil && [friend class] != [NSNull class] && [friend count]!=0) {
                        for(id user in friend){
                            NSNumber * n = [user objectForKey:@"fbuid"];
                            self.friendBeagle.fbuid= [n intValue];
                        }
                        
                    }
                    
                    NSArray *beagle_friends=[profile objectForKey:@"beagle_friends"];
                    if (beagle_friends != nil && [beagle_friends class] != [NSNull class] && [beagle_friends count]!=0) {
                        
                        
                        NSMutableArray *beagleFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in beagle_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [beagleFriendsArray addObject:userClass];
                        }
                        
                        if([beagleFriendsArray count]!=0){
                            self.beagleFriendsArray=[NSArray arrayWithArray:beagleFriendsArray];
                        }
                        
                    }
                    NSArray *facebook_friends=[profile objectForKey:@"facebook_friends"];
                    if (facebook_friends != nil && [facebook_friends class] != [NSNull class] && [facebook_friends count]!=0) {

                        NSMutableArray *facebookFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in facebook_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [facebookFriendsArray addObject:userClass];
                        }
                        
                        if([facebookFriendsArray count]!=0){
                            self.facebookFriendsArray=[NSArray arrayWithArray:facebookFriendsArray];
                        }


                        
                    }
                    
                    
                    
                }
                if(!inviteFriends){
                UILabel* mutualCountLabel=(UILabel*)[[self.navigationController navigationBar]viewWithTag:654];
                mutualCountLabel.text=[NSString stringWithFormat:@"%ld Mutual Friends",(long)[self.beagleFriendsArray count]+[self.facebookFriendsArray count]];
                }
                [_friendsTableView reloadData];
            }
        }
        
    }
    else if (serverRequest==kServerPostAPrivateMessageOnFacebook){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                NSString *message = NSLocalizedString (@"Message sent successfully",
                                                       @"Message sent successfully");
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];

                BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndex];
                player.isInvited=TRUE;
                [self.friendsTableView reloadData];

            }
            else if (status != nil && [status class] != [NSNull class] && [status integerValue]==205){
                // not authorized to send facebook message
                
                NSString *message = NSLocalizedString (@"You are not authorized to send facebook message",
                                                       @"Message Failure");
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];

            }
        }
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetProfileMutualFriends||serverRequest==kServerCallGetDOS1Friends)
    {
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
    }
    else if (serverRequest==kServerPostAPrivateMessageOnFacebook){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;

    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetProfileMutualFriends||serverRequest==kServerCallGetDOS1Friends)
    {
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
    }
    else if (serverRequest==kServerPostAPrivateMessageOnFacebook){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
        
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
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
