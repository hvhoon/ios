//
//  NotificationsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "NotificationsViewController.h"
#import "BeagleNotificationClass.h"
#import "IconDownloader.h"
#import "AttributedTableViewCell.h"
#import "TTTAttributedLabel.h"
@interface NotificationsViewController ()<ServerManagerDelegate,UITableViewDataSource,UITableViewDelegate,IconDownloaderDelegate,TTTAttributedLabelDelegate>
@property(nonatomic,strong)ServerManager*notificationsManager;
@property(nonatomic,strong)NSArray *listArray;
@property(nonatomic,weak)IBOutlet UIImageView*notification_BlankImageView;
@property(nonatomic,strong)UITableView*notificationTableView;
@property(nonatomic,strong)NSMutableDictionary *imageDownloadsInProgress;
@property(nonatomic,weak)IBOutlet UIView*unreadUpdateView;
@property(nonatomic,weak)IBOutlet UILabel*unreadCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpacingForBlankImage;
@property (nonatomic, unsafe_unretained) CGFloat peekLeftAmount;
@end

@implementation NotificationsViewController
@synthesize peekLeftAmount;
@synthesize notificationsManager=_notificationsManager;
@synthesize listArray=_listArray;
@synthesize imageDownloadsInProgress;
@synthesize notificationTableView=_notificationTableView;
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
    if(_notificationsManager!=nil){
        _notificationsManager.delegate = nil;
        [_notificationsManager releaseServerManager];
        _notificationsManager = nil;
    }
    _notificationsManager=[[ServerManager alloc]init];
    _notificationsManager.delegate=self;
    [_notificationsManager getNotifications];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.peekLeftAmount = 50.0f;
    _notificationTableView=[[UITableView alloc]initWithFrame:CGRectMake(0, 64, 270, self.view.frame.size.height-64)];
    _notificationTableView.delegate=self;
    _notificationTableView.dataSource=self;
    [self.view addSubview:_notificationTableView];
    [self.slidingViewController setAnchorLeftPeekAmount:self.peekLeftAmount];
    self.slidingViewController.underRightWidthLayout = ECVariableRevealWidth;
    _notificationTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    _notificationTableView.backgroundColor=[UIColor clearColor];
    _topSpacingForBlankImage.constant =
    [UIScreen mainScreen].bounds.size.height > 480.0f ? 242 : 198;
    UIView *seperatorLineView=[[UIView alloc]initWithFrame:CGRectMake(0, 63.5, 270, 0.5)];
    seperatorLineView.alpha=0.5;
    [seperatorLineView setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:seperatorLineView];
    _unreadUpdateView.hidden=YES;
	// Do any additional setup after loading the view.
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
    switch ([notif.notificationType integerValue]) {
        case 6:
        case 12:
        {
            notif.rowHeight=[AttributedTableViewCell heightForCellWithText:notif.notificationString]+50.0f;
            height=notif.rowHeight;
            
        }
            break;
            
        default:
        {
            notif.rowHeight=[AttributedTableViewCell heightForCellWithText:notif.notificationString]+20.0f;
            height=notif.rowHeight;
        }
            break;
    }
    
    return height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    CGFloat fromTheTop=0.0f;
    
    
    
    CGFloat rowheight=0.0f;
    BeagleNotificationClass *play = (BeagleNotificationClass *)[self.listArray objectAtIndex:indexPath.row];

    if(play.notificationString != nil && [play.notificationString class] != [NSNull class]){
        rowheight=play.rowHeight;
        
    }
    else
        rowheight=60.0f;
    
    AttributedTableViewCell *cell = (AttributedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //if (cell == nil) {
    cell = [[AttributedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    //}
    
    
    cell.notificationType=play.notificationType;
    cell.backgroundColor=[UIColor clearColor];
    
    cell.summaryText =play.notificationString;
    cell.summaryLabel.delegate = self;
    cell.summaryLabel.userInteractionEnabled = YES;
    cell.summaryLabel.backgroundColor=[UIColor clearColor];
    cell.TimeText =[BeagleUtilities calculateChatTimestamp:play.timeOfNotification];
    
    cell.lbltime.userInteractionEnabled = YES;
    cell.lbltime.backgroundColor=[UIColor clearColor];

    fromTheTop=8.0f;
    UIImageView *cellImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, fromTheTop, 35, 35)];
    
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
    cellImageView.tag=[[NSString stringWithFormat:@"111%li",(long)indexPath.row]integerValue];
    [cell.contentView addSubview:cellImageView];
    
    // Add line seperator
    if(indexPath.row!=[self.listArray count]) {
        
        UIView *seperatorLineView=[[UIView alloc]initWithFrame:CGRectMake(16, fromTheTop+65.0f, 288, 0.5)];
        seperatorLineView.alpha=0.15;
        [seperatorLineView setBackgroundColor:[UIColor grayColor]];
        [cell.contentView addSubview:seperatorLineView];
    }

    [cell setNeedsDisplay];

    return cell;
}
- (void)startIconDownload:(BeagleNotificationClass*)appRecord forIndexPath:(NSIndexPath *)indexPath{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.notificationRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
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
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        
        AttributedTableViewCell *cell = (AttributedTableViewCell*)[_notificationTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];

        UIImageView *cellImageView=(UIImageView*)[cell viewWithTag:[[NSString stringWithFormat:@"111%ld",(long)indexPath.row]integerValue]];
        // Display the newly loaded image
        cellImageView.image = [BeagleUtilities imageCircularBySize:iconDownloader.notificationRecord.profileImage sqr:70.0f] ;

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
        
        _notificationsManager.delegate = nil;
        [_notificationsManager releaseServerManager];
        _notificationsManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                id badge=[response objectForKey:@"badge"];
                if (badge != nil && [badge class] != [NSNull class]) {
                    [[[BeagleManager SharedInstance] beaglePlayer]setBadge:[badge integerValue]];
                    
                }
                
                
                
                NSArray *notifications=[response objectForKey:@"notifications"];
                if (notifications != nil && [notifications class] != [NSNull class] && [notifications count] !=0) {
                    
                    
                    NSMutableArray *notificationsArray=[[NSMutableArray alloc]init];
                    for(id el in notifications){
                        BeagleNotificationClass *actclass=[[BeagleNotificationClass alloc]initWithDictionary:el];
                        [notificationsArray addObject:actclass];
                    }

                    if([notificationsArray count]!=0){
                        _notification_BlankImageView.hidden=YES;
                        _notificationTableView.hidden=NO;
                        _listArray=[NSArray arrayWithArray:notificationsArray];
                        [_notificationTableView reloadData];
                    }
                    
                    
                }
                else{
                    //No notifications
                    _notificationTableView.hidden=YES;
                    _notification_BlankImageView.hidden=NO;
                    _unreadUpdateView.hidden=YES;
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
        [_notificationsManager releaseServerManager];
        _notificationsManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetNotifications)
    {
        _notificationsManager.delegate = nil;
        [_notificationsManager releaseServerManager];
        _notificationsManager = nil;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}
@end
