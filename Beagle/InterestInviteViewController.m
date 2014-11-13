//
//  InterestInviteViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 23/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "InterestInviteViewController.h"
#import "InviteTableViewCell.h"
#import "IconDownloader.h"
#import "CreateAnimationBlurView.h"
#import "DetailInterestViewController.h"
@interface InterestInviteViewController ()<ServerManagerDelegate,UITableViewDataSource,UITableViewDelegate,InviteTableViewCellDelegate,IconDownloaderDelegate,InAppNotificationViewDelegate,UISearchBarDelegate,CreateAnimationBlurViewDelegate,InAppNotificationViewDelegate>{
    BOOL isSearching;
    NSTimer *timer;
}
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (createButtonClicked:) name:kLocationUpdateReceived object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLocationError) name:kErrorToGetLocation object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];

}
-(void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationUpdateReceived object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kErrorToGetLocation object:nil];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
    self.animationBlurView.delegate=self;
    self.animationBlurView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self.animationBlurView loadCustomAnimationView:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];

    if([self.interestDetail.participantsArray count]==0)
        _selectedFriendsArray=[NSMutableArray new];
    else{
        _selectedFriendsArray=[NSMutableArray arrayWithArray:self.interestDetail.participantsArray];
    }
    _nearbyFriendsArray=[NSMutableArray new];
    _worldwideFriendsArray=[NSMutableArray new];
    self.inviteTableView.frame=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    CGRect newBounds = self.inviteTableView.bounds;
    newBounds.origin.y = newBounds.origin.y + self.nameSearchBar.bounds.size.height;
    self.inviteTableView.bounds = newBounds;
    self.nameSearchBar.showsCancelButton=NO;

    [self.navigationController.navigationBar setTintColor:[[BeagleManager SharedInstance] darkDominantColor]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleDone target:self action:@selector(createButtonClicked:)];
    [self.navigationItem.rightBarButtonItem setTintColor:[BeagleUtilities returnBeagleColor:13]];
    self.navigationItem.rightBarButtonItem.enabled=NO;

    if([self.interestDetail.activityDesc length]!=0 && [self.interestDetail.participantsArray count]>0){
        self.navigationItem.rightBarButtonItem.enabled=YES;

    }

    self.inviteTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.inviteTableView.separatorInset = UIEdgeInsetsZero;
    self.inviteTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.inviteTableView setBackgroundColor:[UIColor whiteColor]];
    
    imageDownloadsInProgress=[NSMutableDictionary new];
    self.navigationController.navigationBar.topItem.title = @"";
    
    ServerManager *client = [ServerManager sharedServerManagerClient];
    client.delegate = self;
    [client getNearbyAndWorldWideFriends];
    
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentLeft];
        
        NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
                             [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                             [BeagleUtilities returnBeagleColor:4],NSForegroundColorAttributeName,
                             style, NSParagraphStyleAttributeName, nil];
        
        CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width-32,999);
        
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
- (void)didReceiveBackgroundInNotification:(NSNotification*) note{
    
    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationObject:note];
    
    if(notifObject.notifType==1){
        InAppNotificationView *notifView=[[InAppNotificationView alloc]initWithNotificationClass:notifObject];
        notifView.delegate=self;
        [notifView show];
    }
    else if(notifObject.notifType==2 && notifObject.activity.activityId!=0 && (notifObject.notificationType==WHAT_CHANGE_TYPE||notifObject.notificationType==DATE_CHANGE_TYPE||notifObject.notificationType==GOING_TYPE||notifObject.notificationType==LEAVED_ACTIVITY_TYPE|| notifObject.notificationType==ACTIVITY_CREATION_TYPE || notifObject.notificationType==JOINED_ACTIVITY_TYPE)){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        ServerManager *client = [ServerManager sharedServerManagerClient];
        client.delegate = viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        [client getDetailedInterest:notifObject.activity.activityId];
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
        ServerManager *client = [ServerManager sharedServerManagerClient];
        client.delegate = viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        [client getDetailedInterest:notifObject.activity.activityId];
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
    ServerManager *client = [ServerManager sharedServerManagerClient];
    client.delegate = viewController;
    viewController.isRedirected=TRUE;
    if(notification.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;
    [client getDetailedInterest:notification.activity.activityId];
    [self.navigationController pushViewController:viewController animated:YES];
    [BeagleUtilities updateBadgeInfoOnTheServer:notification.notificationId];

}

#pragma mark InAppNotificationView Handler
- (void)notificationView:(InAppNotificationView *)inAppNotification didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    NSLog(@"Button Index = %ld", (long)buttonIndex);
//    [BeagleUtilities updateBadgeInfoOnTheServer:inAppNotification.notification.notificationId];
}


-(void)createButtonClicked:(id)sender{
    
    if([self.selectedFriendsArray count]>0){
    NSMutableArray *jsonContentArray=[NSMutableArray new];
    for(BeagleUserClass*data in self.selectedFriendsArray){
        		NSMutableDictionary *dictionary =[[NSMutableDictionary alloc]init];
        			[dictionary setObject:[NSNumber numberWithInteger:data.beagleUserId] forKey:@"id"];
        			[dictionary setObject:data.fbuid forKey:@"fbuid"];
        [jsonContentArray addObject:dictionary];
    }
        NSError* error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonContentArray options:NSJSONWritingPrettyPrinted error:&error];
        interestDetail.requestString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude==0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude==0.0f){
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
        return;
    }

    if([self.interestDetail.city length]==0 && [self.interestDetail.state length]==0){
        
        //reverse geocode
        
        [self reverseGeocode];
        return;
    }

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [self.animationBlurView blurWithColor];
    [self.animationBlurView crossDissolveShow];
    UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
    [keyboard addSubview:self.animationBlurView];
    ServerManager *client = [ServerManager sharedServerManagerClient];
    client.delegate = self;
    [client createActivityOnBeagle:interestDetail];

}

-(void)reverseGeocode{
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    CLLocation *newLocation=[[CLLocation alloc]initWithLatitude:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude longitude:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude];
    
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if(!error) {
            BeagleManager *BG=[BeagleManager SharedInstance];
            BG.placemark=[placemarks objectAtIndex:0];
            self.interestDetail.state=[[BeagleManager SharedInstance]placemark].administrativeArea;
            self.interestDetail.city=[[[BeagleManager SharedInstance]placemark].addressDictionary objectForKey:@"City"];
            [self createButtonClicked:nil];
            
        }
        else{
            NSLog(@"reverseGeocodeLocation: %@", error.description);
            [self showLocationError];
        }
    }];
    
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
    UIView *sectionHeaderview=[[UIView alloc]initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,kSectionHeaderHeight)];
    sectionHeaderview.backgroundColor=[UIColor whiteColor];
    
    
    CGRect sectionLabelRect=CGRectMake(16,16,[UIScreen mainScreen].bounds.size.width-80,15);
    UILabel *sectionLabel=[[UILabel alloc] initWithFrame:sectionLabelRect];
    sectionLabel.textAlignment=NSTextAlignmentLeft;
    
    sectionLabel.font=[UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0f];
    sectionLabel.textColor=[BeagleUtilities returnBeagleColor:12];
    sectionLabel.backgroundColor=[UIColor whiteColor];
    [sectionHeaderview addSubview:sectionLabel];
    
    
    if (isSearching){
        if([self.searchResults count]==1)
            sectionLabel.text=@"SEARCH RESULT";
        else{
            sectionLabel.text=@"SEARCH RESULTS";
        }
    }
    else{
      if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0 && [self.selectedFriendsArray count]==0){
          if(section==0){
              if([self.nearbyFriendsArray count]>1)
                  sectionLabel.text=@"FRIENDS AROUND YOU";
              else{
                  sectionLabel.text=@"FRIEND AROUND YOU";
              }
              
          }
          else if(section==1){
         if([self.worldwideFriendsArray count]>1)
            sectionLabel.text=@"FRIENDS WORLDWIDE";
         else{
            sectionLabel.text=@"FRIEND WORLDWIDE";
         }
             
        }
      }
      else if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
          if([self.nearbyFriendsArray count]>1)
              sectionLabel.text=@"FRIENDS AROUND YOU";
          else{
              sectionLabel.text=@"FRIEND AROUND YOU";
          }
      }
      else if ([self.worldwideFriendsArray count]>0&& [self.nearbyFriendsArray count]==0){
          if([self.worldwideFriendsArray count]>1)
              sectionLabel.text=@"FRIENDS WORLDWIDE";
          else{
              sectionLabel.text=@"FRIEND WORLDWIDE";
          }
          
      }
    else if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0 && [self.selectedFriendsArray count]>0){
        if(section==1){
            if([self.nearbyFriendsArray count]>1)
                sectionLabel.text=@"FRIENDS AROUND YOU";
            else{
                sectionLabel.text=@"FRIEND AROUND YOU";
            }
            
        }
        else if(section==2){
            if([self.worldwideFriendsArray count]>1)
                sectionLabel.text=@"FRIENDS WORLDWIDE";
            else{
                sectionLabel.text=@"FRIEND WORLDWIDE";
            }
            
        }
     }

    }
    return sectionHeaderview;
    
}

-(BOOL)showBottomLineOrNot:(NSIndexPath*)cellIndexPath{
    NSInteger count=0;
    
    
    if(isSearching){
        count=[self.searchResults count];
        if(count==cellIndexPath.row+1){
            return NO;
        }
        return YES;
    }else{
        if([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
            if(cellIndexPath.section==0){
                return YES;
            }
            else if(cellIndexPath.section==1){
                return YES;
            }
            else{
                count = [self.worldwideFriendsArray count];
                if(cellIndexPath.row+1==count){
                    return NO;
                }
                return YES;
            }
            
        }
        else if([self.selectedFriendsArray count]>0 &&[self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
            if(cellIndexPath.section==0)
                return YES;
            else{
                count = [self.nearbyFriendsArray count];
                if(cellIndexPath.row+1==count){
                    return NO;
                }
                return YES;
            }
            
            
        }
        else if ([self.selectedFriendsArray count]>0 && [self.worldwideFriendsArray count]>0&& [self.nearbyFriendsArray count]==0){
            if(cellIndexPath.section==0)
                return YES;
            else{
                count = [self.worldwideFriendsArray count];
                if(cellIndexPath.row+1==count){
                    return NO;
                }
                return YES;
            }
        }
        else if([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0){
            if(cellIndexPath.section==0)
                return YES;
            else{
                count = [self.worldwideFriendsArray count];
                if(cellIndexPath.row+1==count){
                    return NO;
                }
                return YES;
            }
            
        }
        else if([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0){
            count = [self.nearbyFriendsArray count];
            if(cellIndexPath.row+1==count){
                return NO;
            }
            return YES;

            
        }
        else if ([self.selectedFriendsArray count]==0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0){
            count = [self.worldwideFriendsArray count];
            if(cellIndexPath.row+1==count){
                return NO;
            }
            return YES;
        }
        
        else if ([self.selectedFriendsArray count]>0 && [self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]==0){
            count = [self.selectedFriendsArray count];
            if(cellIndexPath.row+1==count){
                return NO;
            }
            return YES;
        }
    }
    return YES;
}
-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    return 66.0f;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    InviteTableViewCell *cell =[[InviteTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    
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
    if([self showBottomLineOrNot:indexPath]){
        UIView* lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(16, 65, [UIScreen mainScreen].bounds.size.width-32, 1)];
        if(player.isInvited)
            lineSeparator.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:0];
        else{
            lineSeparator.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
        }
        [cell addSubview:lineSeparator];
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
    if(isSearching && [self.searchResults count]>0){
        player = (BeagleUserClass *)[self.searchResults objectAtIndex:indexPath.row];
        if(player.distance<=50.0f){
            [self.nearbyFriendsArray removeObjectIdenticalTo:player];
            
        }else{
            [self.worldwideFriendsArray removeObjectIdenticalTo:player];
        }
        
    }else{
    if ([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0 &&[self.selectedFriendsArray count]>0){
        if(indexPath.section==1){
            player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
         [self.nearbyFriendsArray removeObjectAtIndex:indexPath.row];
        }
        else if(indexPath.section==2){
            player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
           [self.worldwideFriendsArray removeObjectAtIndex:indexPath.row];
        }
        
    }
    else if ([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0 &&[self.selectedFriendsArray count]>0){
            if(indexPath.section==1){
                player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
                [self.nearbyFriendsArray removeObjectAtIndex:indexPath.row];
            }
        
        }
        else if ([self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0 &&[self.selectedFriendsArray count]>0){
            if(indexPath.section==1){
                player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
                [self.worldwideFriendsArray removeObjectAtIndex:indexPath.row];
            }
            
        }
        
        if ([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]>0 &&[self.selectedFriendsArray count]==0){
            if(indexPath.section==0){
                player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
                [self.nearbyFriendsArray removeObjectAtIndex:indexPath.row];
            }
            else if(indexPath.section==1){
                player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
                [self.worldwideFriendsArray removeObjectAtIndex:indexPath.row];
            }
            
        }


    else if([self.nearbyFriendsArray count]>0 && [self.worldwideFriendsArray count]==0 && [self.selectedFriendsArray count]==0){
            if(indexPath.section==0){
        player = (BeagleUserClass *)[self.nearbyFriendsArray objectAtIndex:indexPath.row];
       [self.nearbyFriendsArray removeObjectAtIndex:indexPath.row];
            }
    }
    else if ([self.nearbyFriendsArray count]==0 && [self.worldwideFriendsArray count]>0&& [self.selectedFriendsArray count]==0){
                    if(indexPath.section==0){
        player = (BeagleUserClass *)[self.worldwideFriendsArray objectAtIndex:indexPath.row];
    [self.worldwideFriendsArray removeObjectAtIndex:indexPath.row];
                    }
    }
    }
    
    player.isInvited=TRUE;
    [self.selectedFriendsArray addObject:player];
    [self.inviteTableView reloadData];

    if(isSearching){
        [self filterContentForSearchText:self.nameSearchBar.text];
    }
    
    self.interestDetail.participantsArray=self.selectedFriendsArray;
    
    if([self.interestDetail.participantsArray count]>0 && [self.interestDetail.activityDesc length]!=0){
        self.navigationItem.rightBarButtonItem.enabled=YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled=NO;
    }

    if(isSearching){
        self.navigationItem.rightBarButtonItem.enabled=YES;
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
    
    self.interestDetail.participantsArray=self.selectedFriendsArray;
    if([self.interestDetail.participantsArray count]>0 && [self.interestDetail.activityDesc length]!=0){
        self.navigationItem.rightBarButtonItem.enabled=YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled=NO;
    }
    if(isSearching){
        self.navigationItem.rightBarButtonItem.enabled=YES;
    }


}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallgetNearbyAndWorldWideFriends){
        
        
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
                        NSArray *friendsInCityArray=[NSArray arrayWithArray:nearbyFriendsArray];

                        
                        friendsInCityArray = [friendsInCityArray sortedArrayUsingComparator: ^(BeagleUserClass *a, BeagleUserClass *b) {
                            
                            
                            NSNumber *s1 = [NSNumber numberWithFloat:a.distance];//add the string
                            NSNumber *s2 = [NSNumber numberWithFloat:b.distance];
                            
                            return [s1 compare:s2];
                        }];

                        if([friendsInCityArray count]!=0){
                            [self.nearbyFriendsArray addObjectsFromArray:friendsInCityArray];
                        }
                        
                    }
                    NSArray *worldwide_friends=[profile objectForKey:@"worldwide_friends"];
                    if (worldwide_friends != nil && [worldwide_friends class] != [NSNull class] && [worldwide_friends count]!=0) {
                        
                        NSMutableArray *worldwideFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in worldwide_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [worldwideFriendsArray addObject:userClass];
                        }
                        
                        NSArray *friendsSorted=[NSArray arrayWithArray:worldwideFriendsArray];
                        
                        
                        friendsSorted = [friendsSorted sortedArrayUsingComparator: ^(BeagleUserClass *a, BeagleUserClass *b) {
                            
                            
                            NSNumber *s1 = [NSNumber numberWithFloat:a.distance];//add the string
                            NSNumber *s2 = [NSNumber numberWithFloat:b.distance];
                            
                            return [s1 compare:s2];
                        }];
                        
                        if([friendsSorted count]!=0){
                            [self.worldwideFriendsArray addObjectsFromArray:friendsSorted];
                        }
                        
                    }
                    if([self.nearbyFriendsArray count]>0 && [self.selectedFriendsArray count]>0){
                        NSMutableArray *testArray=[NSMutableArray new];
                        for(BeagleUserClass *obj in self.nearbyFriendsArray){
                            BOOL isFound=FALSE;
                            
                            for(BeagleUserClass*user in self.selectedFriendsArray){
                                
                                if(user.beagleUserId==obj.beagleUserId){
                                    isFound=TRUE;
                                    break;
                            }else{
                                isFound=FALSE;
                                
                            }
                          }
                            if(!isFound){
                                [testArray addObject:obj];
                            }
                        }
                    self.nearbyFriendsArray=testArray;
                    }
                    if([self.worldwideFriendsArray count]>0 && [self.selectedFriendsArray count]>0){
                        NSMutableArray *testArray=[NSMutableArray new];
                        for(BeagleUserClass *obj in self.worldwideFriendsArray){
                            BOOL isFound=FALSE;
                            
                            for(BeagleUserClass*user in self.selectedFriendsArray){
                                
                                if(user.beagleUserId==obj.beagleUserId){
                                    isFound=TRUE;
                                    break;
                                }else{
                                    isFound=FALSE;
                                    
                                }
                            }
                            if(!isFound){
                                [testArray addObject:obj];
                            }
                        }
                        self.worldwideFriendsArray=testArray;
                    }
                    
                    
                }
                [_inviteTableView reloadData];
            }
        }
        
    }
    
   else if(serverRequest==kServerCallCreateActivity){
        
       
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                if(serverRequest==kServerCallCreateActivity){
                    BeagleManager *BG=[BeagleManager SharedInstance];
                    BG.activityDeleted=TRUE;
                    id player=[response objectForKey:@"player"];
                    if (player != nil && [status class] != [NSNull class]){
                        
                        self.interestDetail.activityId=[[player objectForKey:@"id"]integerValue];
                        self.interestDetail.organizerName =[NSString stringWithFormat:@"%@ %@",[[[BeagleManager SharedInstance]beaglePlayer]first_name],[[[BeagleManager SharedInstance]beaglePlayer]last_name]];
                        self.interestDetail.locationName=[NSString stringWithFormat:@"%@, %@",self.interestDetail.city,self.interestDetail.state];

                        self.interestDetail.dosRelation = 0;
                        self.interestDetail.dos1count = 0;
                        self.interestDetail.participantsCount = 0;
                        self.interestDetail.isParticipant=1;
                        self.interestDetail.postCount = 0;
                        self.interestDetail.photoUrl=[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl];
                        self.interestDetail.profilePhotoImage=[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]];
                        
                    }

                    
                    BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
                    notifObject.activity=self.interestDetail;
                    if(serverRequest==kServerCallCreateActivity){
                        notifObject.notificationType=SELF_ACTIVITY_CREATION_TYPE;
                    }
                    
                    NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
                    [notificationDictionary setObject:notifObject forKey:@"notify"];
                    NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
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
    
    
        if(serverRequest==kServerCallCreateActivity){
                [self.animationBlurView hide];
        }
    
    NSString *message = NSLocalizedString (@"Where did all your imaginary friends go? Try again in a bit.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
   if(serverRequest==kServerCallCreateActivity){
            [self.animationBlurView hide];
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
-(void)showLocationError{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Where's Waldo?"
                                                    message:@"We are unable to get your current location"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
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
