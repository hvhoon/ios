//
//  FriendsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "FriendsViewController.h"
#import "FriendsTableViewCell.h"
#import "IconDownloader.h"
#import "DetailInterestViewController.h"
@interface FriendsViewController ()<ServerManagerDelegate,UITableViewDataSource,UITableViewDelegate,FriendsTableViewCellDelegate,IconDownloaderDelegate,InAppNotificationViewDelegate>{
    NSIndexPath* inviteIndexPath;
}
@property(nonatomic,strong)ServerManager*friendsManager;
@property(nonatomic,strong)ServerManager*inviteManager;
@property(nonatomic,strong)NSArray *beagleFriendsArray;
@property(nonatomic,strong)NSArray *facebookFriendsArray;
@property(nonatomic,strong)IBOutlet UITableView*friendsTableView;
@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@property (weak, nonatomic) IBOutlet UIButton *profileLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property(strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAnimation;
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
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:NO];

}
-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFacebookSSOLoginAuthentication object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFacebookAuthenticationFailed object:nil];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookAuthComplete:) name:kFacebookSSOLoginAuthentication object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kFacebookAuthenticationFailed object:Nil];

    self.view.backgroundColor = [[BeagleManager SharedInstance] mediumDominantColor];
    
    self.friendsTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.friendsTableView.separatorInset = UIEdgeInsetsZero;
    self.friendsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [self.loadingAnimation setColor:[BeagleUtilities returnBeagleColor:12]];
    [self.loadingAnimation setHidden:NO];
    [self.loadingAnimation setHidesWhenStopped:YES];
    [self.loadingAnimation startAnimating];
     
    [self.friendsTableView setBackgroundColor:[BeagleUtilities returnBeagleColor:2]];
    imageDownloadsInProgress=[NSMutableDictionary new];

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
    
    // Setup class variables
    [_profileLabel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_inviteLabel setTextColor:[UIColor whiteColor]];
    [_profileLabel setHidden:YES];
    [_inviteLabel setHidden:YES];
    
    // If this is a friend (profile screen)
    if(!inviteFriends){
        
        [_profileLabel setHidden:NO];
        [_profileLabel setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"DOS2"] withColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [_profileLabel setTitle:@"Mutual Friends" forState:UIControlStateNormal];
        
        // Setting up the image
        [self imageCircular:[UIImage imageNamed:@"picbox"]];
        
        // Setting the frame
        _profileImageView.layer.cornerRadius = _profileImageView.frame.size.width/2;
        _profileImageView.clipsToBounds = YES;
        _profileImageView.layer.borderWidth = 4.0f;
        _profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:[self.friendBeagle profileImageUrl]];
        [queue addOperation:operation];
        
    
    }
    // If this is YOU! (invite screen)
    else{
        
        BeagleManager *tempBG = [BeagleManager SharedInstance];
        
        [_inviteLabel setHidden:NO];
        // Setting up the image
        [self imageCircular:[UIImage imageNamed:@"picbox"]];
        
        // Setting the frame
        _profileImageView.layer.cornerRadius = _profileImageView.frame.size.width/2;
        _profileImageView.clipsToBounds = YES;
        _profileImageView.layer.borderWidth = 4.0f;
        _profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:[tempBG.beaglePlayer profileImageUrl]];
        [queue addOperation:operation];
        
        NSString *yourCity = [tempBG.placemark.addressDictionary objectForKey:@"City"];
        
        // error checking
        if(yourCity==nil)
            yourCity = @"your city";
        
        [_inviteLabel setText:[NSString stringWithFormat:@"Rediscover %@ with your friends", yourCity]];
    }

    // Do any additional setup after loading the view.
}
- (void)loadProfileImage:(NSString*)url {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    if (image)
        [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:200.0f];
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

#define kSectionHeaderHeight 36.0
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return kSectionHeaderHeight;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *sectionHeaderview=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,kSectionHeaderHeight)];
    sectionHeaderview.backgroundColor=[UIColor whiteColor];
    
    CGRect sectionLabelRect=CGRectMake(16,12,240,15);
    UILabel *sectionLabel=[[UILabel alloc] initWithFrame:sectionLabelRect];
    sectionLabel.textAlignment=NSTextAlignmentLeft;
    
    sectionLabel.font=[UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f];
    sectionLabel.textColor=[BeagleUtilities returnBeagleColor:12];
    sectionLabel.backgroundColor=[UIColor clearColor];
    [sectionHeaderview addSubview:sectionLabel];

    
    if([self.beagleFriendsArray count]>0 && [self.facebookFriendsArray count]>0){
        if(section==0)
            sectionLabel.text=[NSString stringWithFormat:@"%ld FRIENDS ON BEAGLE",(unsigned long)[self.beagleFriendsArray count]];
        else{
            sectionLabel.text=[NSString stringWithFormat:@"INVITE %ld FRIENDS TO JOIN THE FUN",(unsigned long)[self.facebookFriendsArray count]];
        }
        
    }
    else if([self.beagleFriendsArray count]>0){
        sectionLabel.text=[NSString stringWithFormat:@"%ld FRIENDS ON BEAGLE",(unsigned long)[self.beagleFriendsArray count]];
        
    }
    else if ([self.facebookFriendsArray count]>0)
        sectionLabel.text=[NSString stringWithFormat:@"INVITE %ld FRIENDS TO JOIN THE FUN",(unsigned long)[self.facebookFriendsArray count]];

     return sectionHeaderview;
    
}
-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    return 66.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    FriendsTableViewCell *cell = [[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    
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

-(void)facebookAuthComplete:(NSNotification*) note{
    BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndexPath.row];
    FriendsTableViewCell *cell = (FriendsTableViewCell*)[self.friendsTableView cellForRowAtIndexPath:inviteIndexPath];
    UIButton *button=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"222%ld",(long)inviteIndexPath.row]integerValue]];
    UIActivityIndicatorView *spinner=(UIActivityIndicatorView*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)inviteIndexPath.row]integerValue]];
    
    [button setHidden:YES];
    [spinner setHidden:NO];
    [spinner startAnimating];
    
    if(_inviteManager!=nil){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
    }
    
    _inviteManager=[[ServerManager alloc]init];
    _inviteManager.delegate=self;
    [_inviteManager sendingAPostMessageOnFacebook:player.fbuid];

}
-(void)authenticationFailed:(NSNotification*) note{
    
    BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndexPath.row];
    player.isInvited=FALSE;
    [self.friendsTableView reloadData];

}

-(void)inviteFacebookFriendOnBeagle:(NSIndexPath*)indexPath{
    
    inviteIndexPath=indexPath;
    // check if the user has  a valid facebook session
    
    if([(AppDelegate *)[[UIApplication sharedApplication] delegate] checkForFacebookSesssion]){
        // user has a open session
        
        //request for additional permissions
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] requestUserForAdditionalPermissions];
        
    }
    else{
        
        // user session is expired need a new token
        
        //have to check if this scenarios comes up
    }
    
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
    
    // Stop the animation
    [self.loadingAnimation stopAnimating];
    
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
                        
                        
                        
                        
                        NSArray *friendsInCityArray=[NSArray arrayWithArray:beagleFriendsArray];
                        
                        friendsInCityArray = [friendsInCityArray sortedArrayUsingComparator: ^(BeagleUserClass *a, BeagleUserClass *b) {
                            
                            
                            NSNumber *s1 = [NSNumber numberWithFloat:a.distance];//add the string
                            NSNumber *s2 = [NSNumber numberWithFloat:b.distance];
                            
                            return [s1 compare:s2];
                        }];

                        
                        if([friendsInCityArray count]!=0){
                            self.beagleFriendsArray=[NSArray arrayWithArray:friendsInCityArray];
                        }
                        
                    }
                    NSArray *facebook_friends=[profile objectForKey:@"facebook_friends"];
                    if (facebook_friends != nil && [facebook_friends class] != [NSNull class] && [facebook_friends count]!=0) {

                        NSMutableArray *facebookFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in facebook_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [facebookFriendsArray addObject:userClass];
                        }
                        
                        NSArray *friendsSortedAlphabetically=[NSArray arrayWithArray:facebookFriendsArray];
                        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES];
                        friendsSortedAlphabetically=[friendsSortedAlphabetically sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
                        
                        NSMutableArray *sortedArray=[NSMutableArray arrayWithArray:friendsSortedAlphabetically];

                        if([sortedArray count]!=0){
                            self.facebookFriendsArray=[NSArray arrayWithArray:sortedArray];
                        }


                        
                    }
                    
                    
                    
                }
                if(!inviteFriends){
                    [_profileLabel setTitle:[NSString stringWithFormat:@"%ld Mutual Friends",(long)[self.beagleFriendsArray count]+[self.facebookFriendsArray count]] forState:UIControlStateNormal];
                    NSLog(@"%ld Mutual Friends",(long)[self.beagleFriendsArray count]+[self.facebookFriendsArray count]);
                }
                [self.friendsTableView reloadData];
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
                
                NSString *message = NSLocalizedString (@"Great! We've sent your friend an invite through Facebook.",
                                                       @"Message sent successfully!");
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];

                BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndexPath.row];
                player.isInvited=TRUE;
                [self.friendsTableView reloadData];

            }
            else if (status != nil && [status class] != [NSNull class] && [status integerValue]==205){
                // not authorized to send facebook message
                
                NSString *message = NSLocalizedString (@"You are not authorized to send facebook message",
                                                       @"Message Failure");
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Beagle"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];
                
                BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndexPath.row];
                player.isInvited=FALSE;
                [self.friendsTableView reloadData];


            }
        }
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    // Stop the animation
    [self.loadingAnimation stopAnimating];
    
    if(serverRequest==kServerCallGetProfileMutualFriends||serverRequest==kServerCallGetDOS1Friends)
    {
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
        NSString *message = NSLocalizedString (@"Your friends have vanished, was it something I said? Try again in a bit.",
                                               @"NSURLConnection initialization method failed.");
        BeagleAlertWithMessage(message);

    }
    else if (serverRequest==kServerPostAPrivateMessageOnFacebook){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
        
        BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndexPath.row];
        player.isInvited=FALSE;
        [self.friendsTableView reloadData];
        
        NSString *message = NSLocalizedString (@"Error inviting your friend.Try again in a bit.",
                                               @"NSURLConnection initialization method failed.");
        BeagleAlertWithMessage(message);



    }
    
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    // Stop the animation
    [self.loadingAnimation stopAnimating];
    
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
        BeagleUserClass *player=[self.facebookFriendsArray objectAtIndex:inviteIndexPath.row];
        player.isInvited=FALSE;
        [self.friendsTableView reloadData];

        
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}

-(void)dealloc{
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
