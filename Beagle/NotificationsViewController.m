//
//  NotificationsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "NotificationsViewController.h"
#import "IconDownloader.h"
#import "AttributedTableViewCell.h"
#import "TTTAttributedLabel.h"
#import "DetailInterestViewController.h"
#import "FriendsViewController.h"
#import "Reachability.h"
#define checkingIfTheSpinnerIsStillAnimating 15.0f
@interface NotificationsViewController ()<ServerManagerDelegate,UITableViewDataSource,UITableViewDelegate,IconDownloaderDelegate,TTTAttributedLabelDelegate,ServerManagerDelegate>{
    NSInteger interestIndex;
    NSTimer *timer;
}
@property(nonatomic,strong)ServerManager*notificationsManager;
@property(nonatomic,strong)NSArray *listArray;
@property(nonatomic,weak)IBOutlet UIActivityIndicatorView*notificationSpinnerView;
@property(nonatomic,weak)IBOutlet UIImageView*notification_BlankImageView;
@property(nonatomic,strong)UITableView*notificationTableView;
@property(nonatomic,strong)NSMutableDictionary *imageDownloadsInProgress;
@property(nonatomic,weak)IBOutlet UIView*unreadUpdateView;
@property(nonatomic,strong)ServerManager*interestUpdateManager;
@property(nonatomic,weak)IBOutlet UILabel*unreadCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpacingForBlankImage;
@property (nonatomic, unsafe_unretained) CGFloat peekLeftAmount;
@property(nonatomic, weak) NSTimer *timer;
@end

@implementation NotificationsViewController
@synthesize peekLeftAmount;
@synthesize notificationsManager=_notificationsManager;
@synthesize listArray=_listArray;
@synthesize imageDownloadsInProgress;
@synthesize interestUpdateManager=_interestUpdateManager;
@synthesize notificationTableView=_notificationTableView;
@synthesize timer=_timer;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUpdateNotificationStack object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ECSlidingViewTopDidAnchorRight" object:self userInfo:nil];

    [[BeagleManager SharedInstance]setBadgeCount:0];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUserNotifications) name:kUpdateNotificationStack object:Nil];
    
    if([[Reachability reachabilityForInternetConnection]currentReachabilityStatus]!=0){
        _timer = [NSTimer scheduledTimerWithTimeInterval:checkingIfTheSpinnerIsStillAnimating
                                                  target: self
                                                selector:@selector(stopNotificationSpinnerView)
                                                userInfo: nil repeats:NO];

        [_notificationSpinnerView startAnimating];
        [self getUserNotifications];
        
    }else{
        [_notificationSpinnerView stopAnimating];
        _notificationTableView.hidden=YES;
        _notification_BlankImageView.hidden=NO;
        _unreadUpdateView.hidden=YES;

    }
}

-(void)getUserNotifications{
    self.imageDownloadsInProgress=[[NSMutableDictionary alloc]init];
       if(_notificationsManager!=nil){
                _notificationsManager.delegate = nil;
                _notificationsManager = nil;
      }
    _notificationsManager=[[ServerManager alloc]init];
    _notificationsManager.delegate=self;
    [_notificationsManager getNotifications];



}

- (void)didReceiveBackgroundInNotification:(NSNotification*) note{
    [self getUserNotifications];
}

-(void)postInAppNotification:(NSNotification*)note{
        [self getUserNotifications];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.peekLeftAmount = 50.0f;
    _notificationTableView=[[UITableView alloc]initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width-self.peekLeftAmount, self.view.frame.size.height-64)];
    _notificationTableView.delegate=self;
    _notificationTableView.dataSource=self;
    [self.view addSubview:_notificationTableView];
    [self.slidingViewController setAnchorLeftPeekAmount:self.peekLeftAmount];
    self.slidingViewController.underRightWidthLayout = ECVariableRevealWidth;
    _notificationTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    _notificationTableView.backgroundColor=[UIColor clearColor];
    _topSpacingForBlankImage.constant = ([UIScreen mainScreen].bounds.size.height/2)-42;
    UIView *seperatorLineView=[[UIView alloc]initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width-self.peekLeftAmount, 0.5)];
    [seperatorLineView setBackgroundColor:[BeagleUtilities returnBeagleColor:10]];
    [self.view addSubview:seperatorLineView];
    _unreadUpdateView.layer.cornerRadius = 2.0f;
    _unreadUpdateView.layer.masksToBounds = YES;
    _unreadUpdateView.hidden=YES;
    _notification_BlankImageView.hidden=YES;
    
	// Do any additional setup after loading the view.
    
}

-(void)stopNotificationSpinnerView{
    
    if([_notificationSpinnerView isAnimating]){
        [_notificationSpinnerView stopAnimating];
    }
    [_timer invalidate];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    return [self.listArray count];
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    CGFloat height=0.0f;
    
    BeagleNotificationClass *notif=[self.listArray objectAtIndex:indexPath.row];
    switch (notif.notificationType) {
        default:
        {
            notif.rowHeight = [AttributedTableViewCell heightForNotificationText:notif.notificationString];
            notif.rowHeight += [AttributedTableViewCell heightForTimeStampText:[BeagleUtilities calculateChatTimestamp:notif.timeOfNotification]];
            notif.rowHeight += 26.5; // all other buffers between object;

            height=notif.rowHeight;
            
        }
            break;
            
        case ACTIVITY_CREATION_TYPE:
        {
            notif.rowHeight = [AttributedTableViewCell heightForNotificationText:notif.notificationString];
            notif.rowHeight += [AttributedTableViewCell heightForTimeStampText:[BeagleUtilities calculateChatTimestamp:notif.timeOfNotification]];
            notif.rowHeight += [AttributedTableViewCell heightForNewInterestText:notif.activity.activityDesc];
            notif.rowHeight += 25; // this is the 'Are you in' button;
            notif.rowHeight += 42.5; // all other buffers between object;
            height=notif.rowHeight;
        }
            break;
            
         case JOINED_ACTIVITY_TYPE:
        {
            notif.rowHeight = [AttributedTableViewCell heightForNotificationText:notif.notificationString];
            notif.rowHeight += [AttributedTableViewCell heightForTimeStampText:[BeagleUtilities calculateChatTimestamp:notif.timeOfNotification]];
            notif.rowHeight += 25; // this is the 'Are you in' button;
            notif.rowHeight += 42.5; // all other buffers between object;
            height=notif.rowHeight;
        }
            break;
    }
    
    return height;
}
#if 1
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    float fromTheTop = 0.0f; // height from the top of the cell
    fromTheTop += 12.5;
    
    UIImageView *cellImageView=[[UIImageView alloc]initWithFrame:CGRectMake(fromTheTop, 12, 35, 35)];
    BeagleNotificationClass *play = (BeagleNotificationClass *)[self.listArray objectAtIndex:indexPath.row];

    //AttributedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //if (cell == nil)
    AttributedTableViewCell *cell = [[AttributedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    cell.isANewNotification=!play.isRead;
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.notificationType=play.notificationType;
    cell.backgroundColor=[UIColor clearColor];
    cell.summaryText =play.notificationString;
    cell.summaryLabel.delegate = self;
    cell.summaryLabel.userInteractionEnabled = YES;
    cell.summaryLabel.backgroundColor=[UIColor clearColor];
    cell.TimeText =[BeagleUtilities calculateChatTimestamp:play.timeOfNotification];
    
    cell.lbltime.userInteractionEnabled = YES;
    cell.lbltime.backgroundColor=[UIColor clearColor];
    
    UIImage*checkImage= [BeagleUtilities loadImage:play.referredId];
    if(checkImage==nil|| play.referredId==0 || play.activityType==2){
    if (!play.profileImage)
    {
        if (tableView.dragging == NO && tableView.decelerating == NO)
        {
            [self startIconDownload:play forIndexPath:indexPath];
        }
        // if a download is deferred or in progress, return a placeholder image
        cellImageView.image = [BeagleUtilities imageCircularBySize:[UIImage imageNamed:@"picbox.png"] sqr:70.0f];
        
    }
    else
    {
        cellImageView.image = [BeagleUtilities imageCircularBySize:play.profileImage sqr:70.0f];

    }
    }else{
        play.profileImage=checkImage;
        cellImageView.image = [BeagleUtilities imageCircularBySize:checkImage sqr:70.0f];
    }
    cellImageView.tag=[[NSString stringWithFormat:@"555%li",(long)indexPath.row]integerValue];
    [cell.contentView addSubview:cellImageView];
    

    fromTheTop += [AttributedTableViewCell heightForNotificationText:play.notificationString];
    fromTheTop += 2; // adding buffer below the notification text
    
    fromTheTop += [AttributedTableViewCell heightForTimeStampText:[BeagleUtilities calculateChatTimestamp:play.timeOfNotification]];
    
    if(play.notificationType==ACTIVITY_CREATION_TYPE||play.notificationType==JOINED_ACTIVITY_TYPE){
        
        if(play.notificationType!=JOINED_ACTIVITY_TYPE){
        fromTheTop += 8; // adding buffer above the interest text
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        style.lineBreakMode=NSLineBreakByWordWrapping;
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f], NSFontAttributeName,
                 [BeagleUtilities returnBeagleColor:2],NSForegroundColorAttributeName,
                 style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width-self.peekLeftAmount-32,999);
        
        CGRect whatTextRect = [play.activity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
        
        UILabel *whatLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, fromTheTop, whatTextRect.size.width, whatTextRect.size.height)];
        whatLabel.attributedText = [[NSAttributedString alloc] initWithString:play.activity.activityDesc attributes:attrs];
        whatLabel.numberOfLines=0;
        whatLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:whatLabel];
        
        fromTheTop += whatTextRect.size.height;
        }
        fromTheTop += 8; // buffer below interest text

        UIButton *interestButton=[UIButton buttonWithType:UIButtonTypeCustom];
        interestButton.frame=CGRectMake(16, fromTheTop, 102, 25);
        [interestButton setBackgroundImage:[UIImage imageNamed:@"Action"] forState:UIControlStateNormal];
        interestButton.tag=[[NSString stringWithFormat:@"%ld",(long)indexPath.row]integerValue];
        [interestButton addTarget:self action:@selector(interestButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:interestButton];
        
        fromTheTop += interestButton.frame.size.height;
    }
    
    
    fromTheTop += 12; // buffer below the items on top
    
    // Add line seperator
    if(indexPath.row!=[self.listArray count]) {
        
        UIView *seperatorLineView=[[UIView alloc]initWithFrame:CGRectMake(0, fromTheTop, [UIScreen mainScreen].bounds.size.width-self.peekLeftAmount, 0.5)];
        seperatorLineView.alpha=1.0;
        [seperatorLineView setBackgroundColor:[BeagleUtilities returnBeagleColor:10]];
        [cell.contentView addSubview:seperatorLineView];
    }

    //[cell setNeedsDisplay];

    return cell;
}
#else
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    float fromTheTop = 0.0f; // height from the top of the cell
    fromTheTop += 12.5;
    
    UIImageView *cellImageView=[[UIImageView alloc]initWithFrame:CGRectMake(fromTheTop, 12, 35, 35)];
    BeagleNotificationClass *play = (BeagleNotificationClass *)[self.listArray objectAtIndex:indexPath.row];
    fromTheTop += [AttributedTableViewCell heightForNotificationText:play.notificationString];
    fromTheTop += 2; // adding buffer below the notification text
    
    fromTheTop += [AttributedTableViewCell heightForTimeStampText:[BeagleUtilities calculateChatTimestamp:play.timeOfNotification]];

    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentLeft];
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f], NSFontAttributeName,
                           [BeagleUtilities returnBeagleColor:2],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width-self.peekLeftAmount-32,999);
    
    CGRect whatTextRect = [play.activity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];

    AttributedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[AttributedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if(play.notificationType==ACTIVITY_CREATION_TYPE||play.notificationType==JOINED_ACTIVITY_TYPE){
            
            if(play.notificationType!=JOINED_ACTIVITY_TYPE){
                fromTheTop += 8; // adding buffer above the interest text

                
                UILabel *whatLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, fromTheTop, whatTextRect.size.width, whatTextRect.size.height)];
                whatLabel.attributedText = [[NSAttributedString alloc] initWithString:play.activity.activityDesc attributes:attrs];
                whatLabel.numberOfLines=0;
                whatLabel.tag=[[NSString stringWithFormat:@"111%ld",(long)indexPath.row]integerValue];
                whatLabel.backgroundColor = [UIColor clearColor];
                [cell.contentView addSubview:whatLabel];
                
                fromTheTop += whatTextRect.size.height;
            }
            fromTheTop += 8; // buffer below interest text
            
            UIButton *interestButton=[UIButton buttonWithType:UIButtonTypeCustom];
            interestButton.frame=CGRectMake(16, fromTheTop, 102, 25);
            [interestButton setBackgroundImage:[UIImage imageNamed:@"Action"] forState:UIControlStateNormal];
            interestButton.tag=[[NSString stringWithFormat:@"222%ld",(long)indexPath.row]integerValue];
            [interestButton addTarget:self action:@selector(interestButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:interestButton];
            
            fromTheTop += interestButton.frame.size.height;
        }
        fromTheTop += 12; // buffer below the items on top
        
        // Add line seperator
        if(indexPath.row!=[self.listArray count]) {
            
            UIView *seperatorLineView=[[UIView alloc]initWithFrame:CGRectMake(0, fromTheTop, [UIScreen mainScreen].bounds.size.width-self.peekLeftAmount, 0.5)];
            seperatorLineView.alpha=1.0;
            seperatorLineView.tag=[[NSString stringWithFormat:@"333%ld",(long)indexPath.row]integerValue];
            [seperatorLineView setBackgroundColor:[BeagleUtilities returnBeagleColor:10]];
            [cell.contentView addSubview:seperatorLineView];
        }
        
        
        
    }else{
        
        
        if(play.notificationType==ACTIVITY_CREATION_TYPE||play.notificationType==JOINED_ACTIVITY_TYPE){
            
            if(play.notificationType!=JOINED_ACTIVITY_TYPE){
                fromTheTop += 8; // adding buffer above the interest text

                UILabel *whatLabel=(UILabel*)[cell viewWithTag:[[NSString stringWithFormat:@"111%ld",(long)indexPath.row]integerValue]];
                whatLabel.text=play.activity.activityDesc;
                [cell.contentView addSubview:whatLabel];
                
                fromTheTop += whatTextRect.size.height;
            }
            fromTheTop += 8; // buffer below interest text
            UIButton *interestButton=(UIButton*)[cell viewWithTag:[[NSString stringWithFormat:@"222%ld",(long)indexPath.row]integerValue]];
            [cell.contentView addSubview:interestButton];
            
            fromTheTop += interestButton.frame.size.height;
            
            
        }
        cell.summaryLabel=(TTTAttributedLabel*)[cell viewWithTag:567];
        cell.lbltime=(UILabel*)[cell viewWithTag:568];
        fromTheTop += 12; // buffer below the items on top
        // Add line seperator
        if(indexPath.row!=[self.listArray count]) {
            
            UIView *seperatorLineView=(UIView*)[cell viewWithTag:[[NSString stringWithFormat:@"333%ld",(long)indexPath.row]integerValue]];
            [cell.contentView addSubview:seperatorLineView];
        }
        
        
    }
    
    
    
    
    UIImage*checkImage= [BeagleUtilities loadImage:play.referredId];
    if(checkImage==nil|| play.referredId==0 || play.activityType==2){
        if (!play.profileImage)
        {
            if (tableView.dragging == NO && tableView.decelerating == NO)
            {
                [self startIconDownload:play forIndexPath:indexPath];
            }
            // if a download is deferred or in progress, return a placeholder image
            cellImageView.image = [BeagleUtilities imageCircularBySize:[UIImage imageNamed:@"picbox.png"] sqr:70.0f];
            
        }
        else
        {
            cellImageView.image = [BeagleUtilities imageCircularBySize:play.profileImage sqr:70.0f];
            
        }
    }else{
        play.profileImage=checkImage;
        cellImageView.image = [BeagleUtilities imageCircularBySize:checkImage sqr:70.0f];
    }
    cellImageView.tag=[[NSString stringWithFormat:@"555%li",(long)indexPath.row]integerValue];
    [cell.contentView addSubview:cellImageView];
    cell.summaryText =play.notificationString;
    cell.summaryLabel.delegate = self;
    cell.summaryLabel.userInteractionEnabled = YES;
    cell.summaryLabel.backgroundColor=[UIColor clearColor];
    
    cell.isANewNotification=!play.isRead;
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.notificationType=play.notificationType;
    cell.backgroundColor=[UIColor clearColor];
    cell.TimeText =[BeagleUtilities calculateChatTimestamp:play.timeOfNotification];
    
    cell.lbltime.userInteractionEnabled = YES;
    cell.lbltime.backgroundColor=[UIColor clearColor];
    
    
   // [cell setNeedsDisplay];
    
    return cell;
}
#endif
-(void)interestButtonClicked:(id)sender{
    UIButton *button=(UIButton*)sender;
    BeagleNotificationClass *play = (BeagleNotificationClass *)[self.listArray objectAtIndex:button.tag];
    interestIndex=button.tag;
    
       if(_interestUpdateManager!=nil){
                _interestUpdateManager.delegate = nil;
                _interestUpdateManager = nil;
            }
    
        _interestUpdateManager=[[ServerManager alloc]init];
        _interestUpdateManager.delegate=self;

    [_interestUpdateManager participateMembership:play.activity.activityId playerid:[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BeagleNotificationClass *play = (BeagleNotificationClass *)[self.listArray objectAtIndex:indexPath.row];
    if(play.activity.activityId!=0){

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
    viewController.isRedirected=TRUE;
        
    if(play.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
    [viewController.interestServerManager getDetailedInterest:play.activity.activityId];
    [self.navigationController pushViewController:viewController animated:YES];

    }
    else if (play.notificationType==PLAYER_JOINED_BEAGLE){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FriendsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"profileScreen"];
        BeagleUserClass *player=[[BeagleUserClass alloc]initWithNotificationObject:play];
        viewController.friendBeagle=player;
        [self.navigationController pushViewController:viewController animated:YES];

    }
}
- (void)startIconDownload:(BeagleNotificationClass*)appRecord forIndexPath:(NSIndexPath *)indexPath{
    IconDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.notificationRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [self.imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload:kNotificationRecord];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows{
    if ([self.listArray count] > 0)
    {
        NSArray *visiblePaths = [self.notificationTableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            BeagleNotificationClass *appRecord = (BeagleNotificationClass *)[self.listArray objectAtIndex:indexPath.row];
            
            
            if (!appRecord.profileImage) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
        }
    }
    
    
}

- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        
        AttributedTableViewCell *cell = (AttributedTableViewCell*)[_notificationTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        BeagleNotificationClass *play = (BeagleNotificationClass *)[self.listArray objectAtIndex:indexPath.row];

        UIImageView *cellImageView=(UIImageView*)[cell viewWithTag:[[NSString stringWithFormat:@"555%ld",(long)indexPath.row]integerValue]];
        // Display the newly loaded image
        play.profileImage=iconDownloader.notificationRecord.profileImage;
        cellImageView.image =[BeagleUtilities imageCircularBySize:iconDownloader.notificationRecord.profileImage sqr:70.0f] ;
        if(play.referredId!=0)
            [BeagleUtilities saveImage:iconDownloader.notificationRecord.profileImage withFileName:play.referredId];

    }
    
    [self.notificationTableView reloadData];
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
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    
    if(serverRequest==kServerCallGetNotifications){
        
        
        [_notificationSpinnerView stopAnimating];
        [_timer invalidate];
        _notificationsManager.delegate = nil;
        _notificationsManager = nil;

        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                id badge=[response objectForKey:@"badge"];
                if (badge != nil && [badge class] != [NSNull class]) {
//                    [[[BeagleManager SharedInstance] beaglePlayer]setBadge:[badge integerValue]];
                    NSLog(@"check for badge count in Notification screen=%@",badge);
                }
                
                
                
                NSArray *notifications=[response objectForKey:@"notifications"];
                if (notifications != nil && [notifications class] != [NSNull class] && [notifications count] !=0) {
                    
                    
                    NSMutableArray *notificationsArray=[[NSMutableArray alloc]init];
                    for(id el in notifications){
                        BeagleNotificationClass *actclass=[[BeagleNotificationClass alloc]initWithDictionary:el];
                            if(actclass.activityType!=2)
                                [notificationsArray addObject:actclass];
                    }

                    if([notificationsArray count]!=0){
                        int newCount=0;
                        for(BeagleNotificationClass *obj in notificationsArray){
                            if(!obj.isRead){
                                newCount++;
                            }
                        }
                        if(newCount!=0){
                            _unreadUpdateView.hidden=NO;
                            _unreadCountLabel.text=[NSString stringWithFormat:@"%ld NEW",(long)newCount];
                            
                        }
                        else{
                           _unreadUpdateView.hidden=YES;
                        }
                        _notification_BlankImageView.hidden=YES;
                        _notificationTableView.hidden=NO;
                        _listArray=[NSArray arrayWithArray:notificationsArray];
                        [_notificationTableView reloadData];
                        
                        [[BeagleManager SharedInstance]setBadgeCount:newCount];
                        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[BeagleManager SharedInstance]badgeCount]];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kBeagleBadgeCount object:self userInfo:nil];

                        
                    }
                    
                    
                }
                else{
                    //No notifications
                    [_notificationSpinnerView stopAnimating];
                    _notificationTableView.hidden=YES;
                    _notification_BlankImageView.hidden=NO;
                    _unreadUpdateView.hidden=YES;
                }
            }
        }
        
    }
    else if(serverRequest==kServerCallParticipateInterest){
        
        _interestUpdateManager.delegate = nil;
        _interestUpdateManager = nil;
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            id message=[response objectForKey:@"message"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                if([message isEqualToString:@"Joined"]){
                    [self tableView:_notificationTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:interestIndex inSection:0]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"HomeViewRefresh" object:self userInfo:nil];

                    
                }else if([message isEqualToString:@"Already Joined"]){
                    
                    NSString *message = NSLocalizedString (@"You have already joined.",
                                                           @"Already Joined");
                    BeagleAlertWithMessage(message);
                    return;
                    
                }
            }
        }
        
    }

}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetNotifications)
    {
        _notificationsManager.delegate = nil;
        _notificationsManager = nil;
        [_notificationSpinnerView stopAnimating];
        [_timer invalidate];
        _notificationTableView.hidden=YES;
        _notification_BlankImageView.hidden=NO;
        _unreadUpdateView.hidden=YES;

    }
    else if(serverRequest==kServerCallParticipateInterest){
               _interestUpdateManager.delegate = nil;
                _interestUpdateManager = nil;
    }

    NSString *message = NSLocalizedString (@"Unfortunately we can't show you how popular you are right now. Please try again.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetNotifications)
    {
        _notificationsManager.delegate = nil;
        _notificationsManager = nil;

        [_timer invalidate];
        [_notificationSpinnerView stopAnimating];
        _notificationTableView.hidden=YES;
        _notification_BlankImageView.hidden=NO;
        _unreadUpdateView.hidden=YES;

    }
    
    else if(serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        _interestUpdateManager = nil;
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
}

@end
