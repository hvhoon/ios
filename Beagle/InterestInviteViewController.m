//
//  InterestInviteViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 23/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "InterestInviteViewController.h"
#import "BeagleUserClass.h"
#import "InviteTableViewCell.h"
#import "IconDownloader.h"
#import "BeagleActivityClass.h"
#import "JSON.h"
#import "CreateAnimationBlurView.h"
@interface InterestInviteViewController ()<ServerManagerDelegate,UITableViewDataSource,UITableViewDelegate,InviteTableViewCellDelegate,IconDownloaderDelegate,InAppNotificationViewDelegate,UISearchBarDelegate,CreateAnimationBlurViewDelegate>{
    BOOL isSearching;
    NSTimer *timer;
}
@property(nonatomic,strong)ServerManager*inviteManager;
@property(nonatomic,strong)NSMutableArray *nearbyFriendsArray;
@property(nonatomic,strong)NSMutableArray *worldwideFriendsArray;
@property(nonatomic,strong)NSMutableArray *searchResults;
@property(nonatomic,strong)NSMutableArray *selectedFriendsArray;
@property(nonatomic,strong)IBOutlet UITableView*inviteTableView;
@property(nonatomic,strong)NSMutableDictionary*imageDownloadsInProgress;
@property(nonatomic,strong)IBOutlet UISearchBar *nameSearchBar;
@property(nonatomic,strong)CreateAnimationBlurView *animationBlurView;
@end

@implementation InterestInviteViewController
@synthesize inviteManager=_inviteManager;
@synthesize imageDownloadsInProgress;
@synthesize nearbyFriendsArray=_nearbyFriendsArray;
@synthesize worldwideFriendsArray=_worldwideFriendsArray;
@synthesize inviteTableView=_inviteTableView;
@synthesize searchResults;
@synthesize nameSearchBar;
@synthesize interestDetail;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
    self.animationBlurView.delegate=self;

    [self.animationBlurView loadCustomAnimationView:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];

    _nearbyFriendsArray=[NSMutableArray new];
    _selectedFriendsArray=[NSMutableArray new];
    _worldwideFriendsArray=[NSMutableArray new];
    CGRect newBounds = self.inviteTableView.bounds;
    newBounds.origin.y = newBounds.origin.y + self.nameSearchBar.bounds.size.height;
    self.inviteTableView.bounds = newBounds;
    self.nameSearchBar.showsCancelButton=NO;
    
    [self.navigationController.navigationBar setTintColor:[[BeagleManager SharedInstance] darkDominantColor]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleDone target:self action:@selector(createButtonClicked:)];
    [self.navigationItem.rightBarButtonItem setTintColor:[BeagleUtilities returnBeagleColor:13]];
    self.navigationItem.rightBarButtonItem.enabled=YES;

    self.inviteTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.inviteTableView.separatorInset = UIEdgeInsetsZero;
    self.inviteTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.inviteTableView setBackgroundColor:[UIColor whiteColor]];
    
    imageDownloadsInProgress=[NSMutableDictionary new];
    self.navigationController.navigationBar.topItem.title = @"";
    
    if(_inviteManager!=nil){
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
    }
    
    _inviteManager=[[ServerManager alloc]init];
    _inviteManager.delegate=self;
    [_inviteManager getNearbyAndWorldWideFriends];
    
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        
        NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                             [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                             [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake(288,999);
        
        CGRect inviteFriendsTextRect = [@"Selected" boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                    attributes:attrs
                                                                       context:nil];
        
        UILabel *inviteFriendsTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,inviteFriendsTextRect.size.width,inviteFriendsTextRect.size.height)];
        inviteFriendsTextLabel.backgroundColor = [UIColor clearColor];
        inviteFriendsTextLabel.text = @"Selected";
        inviteFriendsTextLabel.textColor = [BeagleUtilities returnBeagleColor:4];
        inviteFriendsTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
        inviteFriendsTextLabel.textAlignment = NSTextAlignmentLeft;
        self.navigationItem.titleView=inviteFriendsTextLabel;
        
    // Do any additional setup after loading the view.
}

-(void)createButtonClicked:(id)sender{
    
    if(self.inviteManager!=nil){
        self.inviteManager.delegate = nil;
        [self.inviteManager releaseServerManager];
        self.inviteManager = nil;
    }
    
    self.inviteManager=[[ServerManager alloc]init];
    self.inviteManager.delegate=self;
    if([self.selectedFriendsArray count]>0){
    NSMutableArray *jsonContentArray=[NSMutableArray new];
    for(BeagleUserClass*data in self.selectedFriendsArray){
        		NSMutableDictionary *dictionary =[[NSMutableDictionary alloc]init];
        			[dictionary setObject:[NSNumber numberWithInteger:data.beagleUserId] forKey:@"id"];
        			[dictionary setObject:[NSNumber numberWithInteger:data.fbuid] forKey:@"fbuid"];
        [jsonContentArray addObject:dictionary];
    }
      interestDetail.requestString =[jsonContentArray JSONRepresentation];
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [self.animationBlurView blurWithColor];
    [self.animationBlurView crossDissolveShow];
    UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
    [keyboard addSubview:self.animationBlurView];

    [self.inviteManager createActivityOnBeagle:interestDetail];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if(isSearching){
        return 1;
    }
    else{
        if([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0) {
        return 3;
        }
    if(([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0)||([self.selectedFriendsArray count]>0 && [self.worldwideFriendsArray count]>0)||([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0))
        return 2;
    else if([self.selectedFriendsArray count]>0||[self.nearbyFriendsArray count]>0 || [self.worldwideFriendsArray count]>0)
        return 1;
    else
        return 0;
    }
    return 0;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    if (isSearching) {
        return [searchResults count];
        
    } else{
        
        if([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
            if (section==0) {
                return [self.selectedFriendsArray count];
            }
            else if(section==1)
                return [self.nearbyFriendsArray count];
            else{
                return [self.worldwideFriendsArray count];
            }
            
        }
        else if ([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
            if (section==0) {
                return [self.selectedFriendsArray count];
            }
            else if(section==1)
                return [self.nearbyFriendsArray count];
            
        }
        
        else if ([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0){
            if (section==0) {
                return [self.selectedFriendsArray count];
            }
            else if(section==1)
                return [self.worldwideFriendsArray count];
            
        }

        
        
       else if([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
        if(section==0)
            return [self.nearbyFriendsArray count];
        else{
            return [self.worldwideFriendsArray count];
        }
        
       }
    else if([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
        return [self.nearbyFriendsArray count];
        
    }
    else if ([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0)
        return [self.worldwideFriendsArray count];
        
    else if ([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]==0)
        return [self.selectedFriendsArray count];
    else
        return 0;
    }
    return 0;
}

#define kSectionHeaderHeight    31.0
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (!isSearching){
    if([self.selectedFriendsArray count]>0 && section==0){
         return 0.0f;
    }
    }
    return kSectionHeaderHeight;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
  if (!isSearching){
    if([self.selectedFriendsArray count]>0 && section==0){
        return [[UIView alloc]initWithFrame:CGRectZero];
    }
    }
    UIView *sectionHeaderview=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,kSectionHeaderHeight)];
    sectionHeaderview.backgroundColor=[UIColor whiteColor];
    
    
    CGRect sectionLabelRect=CGRectMake(16,16,240,15);
    UILabel *sectionLabel=[[UILabel alloc] initWithFrame:sectionLabelRect];
    sectionLabel.textAlignment=NSTextAlignmentLeft;
    
    sectionLabel.font=[UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f];
    sectionLabel.textColor=[BeagleUtilities returnBeagleColor:12];
    sectionLabel.backgroundColor=[UIColor whiteColor];
    [sectionHeaderview addSubview:sectionLabel];
    
    
    if (isSearching){
        sectionLabel.text=@"SEARCH RESULTS";
    
    }
    
    else{
      if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
         if(section==1)
            sectionLabel.text=@"FRIENDS AROUND YOU";
        else
            sectionLabel.text=@"FRIENDS WORLDWIDE";
      }
    else if([self.nearbyFriendsArray count]>0)
            sectionLabel.text=@"FRIENDS AROUND YOU";

    else if ([self.worldwideFriendsArray count]>0)
            sectionLabel.text=@"FRIENDS WORLDWIDE";
    }
    return sectionHeaderview;
    
}
-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    return 66.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    InviteTableViewCell *cell = (InviteTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //if (cell == nil) {
    cell =[[InviteTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    //}
    
    BeagleUserClass *player=nil;

    
    if (isSearching){
        player=[self.searchResults objectAtIndex:indexPath.row];
    }else{
    
    if([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
        if(indexPath.section==0){
            player = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
        }
        else if(indexPath.section==1)
            player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
        else{
            player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
        }
        
    }
    else if([self.selectedFriendsArray count]>0 &&[self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
        if(indexPath.section==0)
            player = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
        else
            player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
        
        
    }
    else if ([self.selectedFriendsArray count]>0 && [self.worldwideFriendsArray count]>0&& [self.nearbyFriendsArray count]==0){
        if(indexPath.section==0)
            player = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
        else
            player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
    }
    else if([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
        if(indexPath.section==0)
            player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
        else{
            player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
        }
        
    }
    else if([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
        player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
        
    }
    else if ([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0)
        player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
        
    
    else if ([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]==0){
        player = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
    }
    }
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
    
    if (!isSearching){
        
    if([self.nearbyFriendsArray count]>0 || [self.worldwideFriendsArray count]>0 || [self.selectedFriendsArray count]>0){
        NSArray *visiblePaths = [self.inviteTableView indexPathsForVisibleRows];
        if([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
            
            for (NSIndexPath *indexPath in visiblePaths)
            {
                BeagleUserClass *appRecord=nil;
                if(indexPath.section==0){
                    appRecord = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
                    
                }
                else if(indexPath.section==1)
                    appRecord = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
                else{
                    appRecord = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
                    
                }
                
                
                if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
            }
            
        }
        else if([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 &&[self.worldwideFriendsArray count]==0){
            for (NSIndexPath *indexPath in visiblePaths)
            {
                BeagleUserClass *appRecord=nil;
                if(indexPath.section==0){
                    appRecord = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
                    
                }else
                   appRecord=(BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
                if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
            }
            
        }
        else if ([self.selectedFriendsArray count]>0 && [self.worldwideFriendsArray count]>0&&[self.nearbyFriendsArray count]==0){
            {
                for (NSIndexPath *indexPath in visiblePaths)
                {
                    BeagleUserClass *appRecord=nil;
                    if(indexPath.section==0){
                        appRecord = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
                        
                    }else
                       appRecord=(BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
                    if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
                    {
                        [self startIconDownload:appRecord forIndexPath:indexPath];
                    }
                }
                
            }
            
        }
        
        
        else if ([self.selectedFriendsArray count]>0 && [self.worldwideFriendsArray count]==0&&[self.nearbyFriendsArray count]==0){
            
                for (NSIndexPath *indexPath in visiblePaths)
                {
                    BeagleUserClass *appRecord = (BeagleUserClass *)[self.selectedFriendsArray objectAtIndex:indexPath.row];
                        
                    if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
                    {
                        [self startIconDownload:appRecord forIndexPath:indexPath];
                    }
                }
                
            
            
        }
        
        else if ([self.selectedFriendsArray count]==0 && [self.worldwideFriendsArray count]>0&&[self.nearbyFriendsArray count]==0){
            
            for (NSIndexPath *indexPath in visiblePaths)
            {
                BeagleUserClass *appRecord = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
                
                if (!appRecord.profileData) // avoid the app icon download if the app already has an icon
                {
                    [self startIconDownload:appRecord forIndexPath:indexPath];
                }
            }
            
            
            
        }
        
        
        else if ([self.selectedFriendsArray count]==0 && [self.worldwideFriendsArray count]==0&&[self.nearbyFriendsArray count]>0){
            
            for (NSIndexPath *indexPath in visiblePaths)
            {
                BeagleUserClass *appRecord = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
                
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
        InviteTableViewCell *cell = (InviteTableViewCell*)[self.inviteTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        cell.photoImage =[UIImage imageWithData:iconDownloader.friendRecord.profileData];
        if(iconDownloader.friendRecord.beagleUserId!=0)
            [BeagleUtilities saveImage:cell.photoImage withFileName:iconDownloader.friendRecord.beagleUserId];
    }
    
    [self.inviteTableView reloadData];
}


#pragma mark -
#pragma mark UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    
    if (![searchBar isFirstResponder]) {
        // User tapped the 'clear' button.
    }
    [self filterContentForSearchText:searchBar.text];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
    searchBar.showsCancelButton=NO;
    isSearching=TRUE;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonClicked:)];
    self.navigationItem.hidesBackButton = YES;

    return YES;
}
-(void)doneButtonClicked:(id)sender{
    isSearching=FALSE;
    [self.inviteTableView reloadData];
    [self.nameSearchBar resignFirstResponder];
    CGRect newBounds = self.inviteTableView.bounds;
    newBounds.origin.y = newBounds.origin.y + self.nameSearchBar.bounds.size.height;
    self.inviteTableView.bounds = newBounds;
    self.nameSearchBar.text = @"";
    self.nameSearchBar.showsCancelButton=NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleDone target:self action:@selector(createButtonClicked:)];
    self.navigationItem.hidesBackButton = NO;

}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
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

#pragma mark -  Invite/Uninvite  calls
-(void)inviteFriendOnBeagle:(NSIndexPath*)indexPath{
    BeagleUserClass *player=nil;
    if ([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
        if(indexPath.section==0){
            player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
         [self.nearbyFriendsArray removeObjectAtIndex:indexPath.row];
        }
        else{
            player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
           [self.worldwideFriendsArray removeObjectAtIndex:indexPath.row];
        }
        
    }
    else if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){

        player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
       [self.nearbyFriendsArray removeObjectAtIndex:indexPath.row];
    }
    else if ([self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0){
        player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
    [self.worldwideFriendsArray removeObjectAtIndex:indexPath.row];
    }
    player.isInvited=TRUE;
    [self.selectedFriendsArray addObject:player];
    [self.inviteTableView reloadData];
    if(isSearching){
        [self filterContentForSearchText:self.nameSearchBar.text];
    }

}


-(void)unInviteFriendOnBeagle:(NSIndexPath*)indexPath{
    if([self.selectedFriendsArray count]>0){
        BeagleUserClass *player=[self.selectedFriendsArray objectAtIndex:indexPath.row];
        player.isInvited=FALSE;
        [self.selectedFriendsArray removeObjectAtIndex:indexPath.row];
        if(player.distance<=50.0f){
             [self.nearbyFriendsArray addObject:player];
        }
        else{
             [self.worldwideFriendsArray addObject:player];
        }
        [self.inviteTableView reloadData];
    }
    
    if(isSearching){
        [self filterContentForSearchText:self.nameSearchBar.text];
    }
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallgetNearbyAndWorldWideFriends){
        
            _inviteManager.delegate = nil;
            [_inviteManager releaseServerManager];
            _inviteManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id profile=[response objectForKey:@"profile"];
                if (profile != nil && [profile class] != [NSNull class]) {
                    
                    
                    NSArray *nearby_friends=[profile objectForKey:@"nearby_friends"];
                    if (nearby_friends != nil && [nearby_friends class] != [NSNull class] && [nearby_friends count]!=0) {
                        
                        
                        NSMutableArray *nearbyFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in nearby_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [nearbyFriendsArray addObject:userClass];
                        }
                        
                        if([nearbyFriendsArray count]!=0){
                            [self.nearbyFriendsArray addObjectsFromArray:nearbyFriendsArray];
                        }
                        
                    }
                    NSArray *worldwide_friends=[profile objectForKey:@"worldwide_friends"];
                    if (worldwide_friends != nil && [worldwide_friends class] != [NSNull class] && [worldwide_friends count]!=0) {
                        
                        NSMutableArray *worldwideFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in worldwideFriendsArray){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [worldwideFriendsArray addObject:userClass];
                        }
                        
                        if([worldwideFriendsArray count]!=0){
                            [self.worldwideFriendsArray addObjectsFromArray:worldwideFriendsArray];
                        }
                        
                        
                        
                    }
                    
                    
                    
                }
                [_inviteTableView reloadData];
            }
        }
        
    }
    
   else if(serverRequest==kServerCallCreateActivity){
        
        self.inviteManager.delegate = nil;
        [self.inviteManager releaseServerManager];
        self.inviteManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                if(serverRequest==kServerCallCreateActivity){
                    BeagleManager *BG=[BeagleManager SharedInstance];
                    BG.activityDeleted=TRUE;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHomeAutoRefresh object:self userInfo:nil];
                    
                    [self.animationBlurView show];
                    
                    timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                                  target: self
                                                                selector:@selector(hideCreateOverlay)
                                                                userInfo: nil repeats:NO];
                    


                }
                
            }
        }
        
    }}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallgetNearbyAndWorldWideFriends||serverRequest==kServerCallCreateActivity)
    {
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
        if(serverRequest==kServerCallCreateActivity){
                [self.animationBlurView hide];
        }
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallgetNearbyAndWorldWideFriends||serverRequest==kServerCallCreateActivity)
    {
        _inviteManager.delegate = nil;
        [_inviteManager releaseServerManager];
        _inviteManager = nil;
        if(serverRequest==kServerCallCreateActivity){
            [self.animationBlurView hide];
        }

    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}

- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"SELF.fullName contains[cd] %@",
                                    searchText];
    
    NSMutableArray *testArray=[NSMutableArray new];
    
    
    NSMutableSet* firstArraySet = [[NSMutableSet alloc] init];
    NSMutableSet* secondArraySet = [[NSMutableSet alloc] init];
    

    

    
    if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
        [testArray addObjectsFromArray:self.nearbyFriendsArray];
        [testArray addObjectsFromArray:self.worldwideFriendsArray];
    NSArray *resultsArray = [testArray filteredArrayUsingPredicate:resultPredicate];
    self.searchResults=[NSMutableArray arrayWithArray:resultsArray];
    }
    else if([self.nearbyFriendsArray count]>0){
    [testArray addObjectsFromArray:self.nearbyFriendsArray];
    NSArray *resultsArray = [testArray filteredArrayUsingPredicate:resultPredicate];
    self.searchResults=[NSMutableArray arrayWithArray:resultsArray];
    }
    else if ([self.worldwideFriendsArray count]>0){
    [testArray addObjectsFromArray:self.worldwideFriendsArray];
    NSArray *resultsArray = [testArray filteredArrayUsingPredicate:resultPredicate];
    self.searchResults=[NSMutableArray arrayWithArray:resultsArray];
    }
    [firstArraySet addObjectsFromArray:self.searchResults];
    [secondArraySet addObjectsFromArray:self.selectedFriendsArray];
    [firstArraySet minusSet: secondArraySet];
    self.searchResults=[NSMutableArray arrayWithArray:[firstArraySet allObjects]];
    [self.inviteTableView reloadData];
}


-(void)hideCreateOverlay{
    [timer invalidate];
    [self.animationBlurView hide];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    [self.navigationController popViewControllerAnimated:YES];

    
}
- (void)dismissEventFilter{
    [timer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
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
