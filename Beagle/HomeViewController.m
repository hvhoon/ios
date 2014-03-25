//
//  HomeViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "HomeViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "Constants.h"
#import "BGFlickrManager.h"
#import "BGLocationManager.h"
#import "ASIHTTPRequest.h"
#import "ActivityViewController.h"
#import "UIView+HidingView.h"
#import "BlankHomePageView.h"
#import "HomeTableViewCell.h"
#import "BeagleActivityClass.h"
#import "ServerManager.h"
#import "IconDownloader.h"
@interface HomeViewController ()<UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate,HomeTableViewCellDelegate,ServerManagerDelegate,IconDownloaderDelegate>{
    UIView*bottomNavigationView;
    BOOL footerActivated;
    ServerManager *homeActivityManager;
    NSMutableDictionary *imageDownloadsInProgress;
}
@property(nonatomic,strong)  NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, strong) NSArray *tableData;
@property(nonatomic, weak) UIImageView *backgroundPhoto;
@property(nonatomic, weak) IBOutlet UITableView*tableView;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;
@property(strong,nonatomic)ServerManager *homeActivityManager;
@end

@implementation HomeViewController
@synthesize homeActivityManager=_homeActivityManager;
@synthesize imageDownloadsInProgress;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)revealUnderRight:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];

    if (![self.slidingViewController.underLeftViewController isKindOfClass:[SettingsViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsScreen"];
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[NotificationsViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationsScreen"];
    }
      [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
   // [self retrieveLocationAndUpdateBackgroundPhoto];
    
     UIImage *stockBottomImage1=[BeagleUtilities imageByCropping:[UIImage imageNamed:@"defaultLocation"] toRect:CGRectMake(0, 0, 320, 64) withOrientation:UIImageOrientationDownMirrored];
    UIView *topNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 64)];
    
    topNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage1];
    [self.view addSubview:topNavigationView];
    
    
    UIImage *stockBottomImage2=[BeagleUtilities imageByCropping:[UIImage imageNamed:@"defaultLocation"] toRect:CGRectMake(0, 64, 320, 103) withOrientation:UIImageOrientationDownMirrored];
    bottomNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 64, 320, 103)];
    
    bottomNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage2];
    [self.view addSubview:bottomNavigationView];

    
    CGSize size = CGSizeMake(180,999);
    
    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentLeft;
    

    CGRect textRect = [@"New York"
                       boundingRectWithSize:size
                       options:NSStringDrawingUsesLineFragmentOrigin
                       attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0],NSForegroundColorAttributeName:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.95],NSParagraphStyleAttributeName: paragraphStyle, }
                       context:nil];
    
    
    UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(16,22, textRect.size.width, textRect.size.height)];
    fromLabel.text = @"New York";
    fromLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0];
    fromLabel.numberOfLines = 1;
    fromLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    fromLabel.adjustsFontSizeToFitWidth = YES;
    fromLabel.adjustsFontSizeToFitWidth = YES;
    fromLabel.clipsToBounds = YES;
    fromLabel.backgroundColor = [UIColor clearColor];
    fromLabel.textColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.95];
    fromLabel.textAlignment = NSTextAlignmentLeft;
    [topNavigationView addSubview:fromLabel];
    
    UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [eventButton addTarget:self action:@selector(createANewActivity:)forControlEvents:UIControlEventTouchUpInside];
    [eventButton setTitle:@"+" forState:UIControlStateNormal];
    [eventButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    eventButton.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:60.0f];
    [eventButton.titleLabel setTextAlignment:NSTextAlignmentRight];
    eventButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

    eventButton.frame = CGRectMake(244.0, 4.0, 60.0, 60.0);
    [topNavigationView addSubview:eventButton];
    
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton addTarget:self action:@selector(revealMenu:)forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setBackgroundImage:[UIImage imageNamed:@"Settings"] forState:UIControlStateNormal];
    settingsButton.frame = CGRectMake(16.0, 78.0, 20.0, 13.0);
    [bottomNavigationView addSubview:settingsButton];
    
    UIButton *notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [notificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
    [notificationsButton setBackgroundImage:[UIImage imageNamed:@"Bell-(No-Notications)"] forState:UIControlStateNormal];
    notificationsButton.frame = CGRectMake(287.0, 72.0, 17.0, 19.0);
    [bottomNavigationView addSubview:notificationsButton];


    self.tableView.tableHeaderView=[self renderTableHeaderView];
    footerActivated=YES;
    

#if 1
    if(_homeActivityManager!=nil){
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
    }
    [(AppDelegate*)[[UIApplication sharedApplication] delegate]showProgressIndicator:3];
    
    _homeActivityManager=[[ServerManager alloc]init];
    _homeActivityManager.delegate=self;
    [_homeActivityManager getActivities];
#endif
	// Do any additional setup after loading the view.
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}
- (void)refresh:(UIRefreshControl *)refreshControl {
    
    if(_homeActivityManager!=nil){
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
    }
    [(AppDelegate*)[[UIApplication sharedApplication] delegate]showProgressIndicator:3];
    
    _homeActivityManager=[[ServerManager alloc]init];
    _homeActivityManager.delegate=self;
    [_homeActivityManager getActivities];
    [refreshControl endRefreshing];

}
-(void)createANewActivity:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];

    [self.navigationController presentViewController:activityNavigationController animated:YES completion:nil];
    
}
- (void) retrieveLocationAndUpdateBackgroundPhoto {
    
    //Location
    [[BGLocationManager sharedManager] locationRequest:^(CLLocation * location, NSError * error) {
        
        
        if(!error) {
            
            
            CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
            CLLocation *newLocation=[[CLLocation alloc]initWithLatitude:[[NSNumber numberWithDouble:[BGLocationManager sharedManager].locationBestEffort.coordinate.latitude] doubleValue] longitude:[[NSNumber numberWithDouble:[BGLocationManager sharedManager].locationBestEffort.coordinate.longitude] doubleValue]];
             [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                
                if(!error) {
                for (CLPlacemark * placemark in placemarks) {
                    
#if 0
                    NSString *urlString=[NSString stringWithFormat:@"http://api.wunderground.com/api/5706a66cb7258dd4/conditions/q/%@/%@.json",placemark.administrativeArea,[placemark.addressDictionary objectForKey:@"City"]];
                    
#else
                    NSString *urlString=[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f",placemark.location.coordinate.latitude,placemark.location.coordinate.longitude];
                    
#endif
                    
                    
                    [BGLocationManager sharedManager].placemark=placemark;
                    
                    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
                    NSURL *url = [NSURL URLWithString:urlString];
                    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                    [request setCompletionBlock:^{
                        // Use when fetching text data
                        NSError* error;
                        NSString *weather=nil;
                        NSString *jsonString = [request responseString];
                        NSDictionary* weatherDictionary = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
#if 0
                        NSDictionary *current_observation=[weatherDictionary objectForKey:@"current_observation"];
                        NSString *weather=[current_observation objectForKey:@"weather"];
                        
#else
                        NSDictionary *current_observation=[weatherDictionary objectForKey:@"weather"];
                        for(id mainWeather in current_observation){
                            weather=[mainWeather objectForKey:@"main"];
                        }

#endif
                            NSLog(@"weather=%@",weather);
                        [BGLocationManager sharedManager].weatherCondition=weather;
                        
                        

                            //Flickr
                            [[BGFlickrManager sharedManager] randomPhotoRequest:^(FlickrRequestInfo * flickrRequestInfo, NSError * error) {
                                
                                if(!error) {
                                    NSLog(@"Url=%@",flickrRequestInfo.userPhotoWebPageURL);
                                    
                                    [self crossDissolvePhotos:flickrRequestInfo.photo withTitle:flickrRequestInfo.userInfo];
                                } else {
                                    
                                    //Error : Stock photos
                                    [self crossDissolvePhotos:[UIImage imageNamed:@"defaultLocation"] withTitle:@""];
                                    
                                    NSLog(@"Flickr: %@", error.description);
                                }
                            }];

                            
                        



                        
                    }];
                    [request setFailedBlock:^{
                        NSError *error = [request error];
                        NSLog(@"error=%@",[error description]);
                    }];
                    [request startAsynchronous];

                        
                    }
                
                }
                else{
                     NSLog(@"reverseGeocodeLocation: %@", error.description);
                }
            }];
        } else {
            
            //Error : Stock photos
                [self crossDissolvePhotos:[UIImage imageNamed:@"defaultLocation"] withTitle:@""];
            
            
            NSLog(@"Location: %@", error.description);
        }
    }];
}

- (void) crossDissolvePhotos:(UIImage *) photo withTitle:(NSString *) title {
    [UIView transitionWithView:self.backgroundPhoto duration:1.0f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.backgroundPhoto.image =photo;
        
    } completion:NULL];
}

-(UIView*)renderTableHeaderView{
    UIView *headerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    headerView.backgroundColor=[UIColor lightGrayColor];
    
    CGSize size = CGSizeMake(220,999);
    
    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    
    CGRect textRect = [@"Happening Around You"
                       boundingRectWithSize:size
                       options:NSStringDrawingUsesLineFragmentOrigin
                       attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0],NSForegroundColorAttributeName:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],NSParagraphStyleAttributeName: paragraphStyle, }
                       context:nil];

    UILabel *activityFilterLabel = [[UILabel alloc]initWithFrame:CGRectMake(16,15, textRect.size.width, textRect.size.height)];
    activityFilterLabel.text = @"Happening Around You";
    activityFilterLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0];
    activityFilterLabel.numberOfLines = 1;
    activityFilterLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    activityFilterLabel.adjustsFontSizeToFitWidth = YES;
    activityFilterLabel.adjustsFontSizeToFitWidth = YES;
    activityFilterLabel.clipsToBounds = YES;
    activityFilterLabel.backgroundColor = [UIColor clearColor];
    activityFilterLabel.textAlignment = NSTextAlignmentLeft;
    [headerView addSubview:activityFilterLabel];
    
    UIImageView *filterImageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Filter"]];
    filterImageView.frame=CGRectMake(16+textRect.size.width+10,20, 15, 8);
    [headerView addSubview:filterImageView];
    
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [searchButton addTarget:self action:@selector(searchIconClicked:)forControlEvents:UIControlEventTouchUpInside];
    [searchButton setBackgroundImage:[UIImage imageNamed:@"Search"] forState:UIControlStateNormal];
    searchButton.frame = CGRectMake(285.0, 12.0, 19.0, 19.0);
    [headerView addSubview:searchButton];

    return headerView;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
        return [self.tableData count];
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentLeft];

    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
                           [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect textRect = [play.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:attrs
                                                        context:nil];
    NSLog(@"height=%f",textRect.size.height);

    return 170.0f+textRect.size.height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    HomeTableViewCell *cell = (HomeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell =[[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    
    cell.delegate=self;
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
    cell.bg_activity = play;
    
    if (!play.profilePhotoImage)
    {
        if (tableView.dragging == NO && tableView.decelerating == NO)
        {
            [self startIconDownload:play forIndexPath:indexPath];
        }
        // if a download is deferred or in progress, return a placeholder image
        cell.photoImage = [UIImage imageNamed:@"picbox.png"];
        
    }
    else
    {
        cell.photoImage = play.profilePhotoImage;
    }

    [cell setNeedsDisplay];
    return cell;
}
- (void)startIconDownload:(BeagleActivityClass*)appRecord forIndexPath:(NSIndexPath *)indexPath{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload:kParticipantInActivity];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows{
    if ([self.tableData count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            BeagleActivityClass *appRecord = (BeagleActivityClass *)[self.tableData objectAtIndex:indexPath.row];
            
            
            if (!appRecord.profilePhotoImage) // avoid the app icon download if the app already has an icon
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
        HomeTableViewCell *cell = (HomeTableViewCell*)[self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        // Display the newly loaded image
        cell.photoImage = iconDownloader.appRecord.profilePhotoImage ;
    }
    
    [self.tableView reloadData];
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
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    if(!footerActivated)
        [bottomNavigationView scrollViewWillBeginDragging:scrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
        if(!footerActivated)
    [bottomNavigationView scrollViewDidScroll:scrollView];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self hideSearchBarAndAnimateWithListViewInMiddle];
    self.tableView.tableHeaderView=nil;
    self.tableView.tableHeaderView=[self renderTableHeaderView];

    
}

-(void)searchIconClicked:(id)sender{
    
    [self showSearchBarAndAnimateWithListViewInMiddle];
}
-(void)showSearchBarAndAnimateWithListViewInMiddle{
    
    if (!footerActivated) {
		[UIView beginAnimations:@"expandFooter" context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 64;
        tableViewFrame.size.height-=64;
        
        
		[bottomNavigationView setHidden:YES];
        [self.tableView setFrame:tableViewFrame];
		//[self.tableView setFrame:CGRectMake(0, 64, 320, 568-64)];
        
        self.tableView.tableHeaderView=nil;
        
        UISearchBar *headerView = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        headerView.hidden = NO;
        headerView.delegate=self;
        self.tableView.tableHeaderView = headerView;
        headerView.showsCancelButton=YES;
        [headerView becomeFirstResponder];
        [self.tableView addSubview:headerView];

		[UIView commitAnimations];
		footerActivated = YES;
	}

}

-(void)hideSearchBarAndAnimateWithListViewInMiddle{
    
    if (footerActivated) {
		[UIView beginAnimations:@"collapseFooter" context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[bottomNavigationView setHidden:NO];
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 167;
        tableViewFrame.size.height-=167;
        
        [self.tableView setFrame:tableViewFrame];

//        [self.tableView setFrame:CGRectMake(0, 167, 320, 568-167)];
        [self.tableView setFrame:tableViewFrame];
		[UIView commitAnimations];
		footerActivated = NO;
	}
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
        [(AppDelegate*)[[UIApplication sharedApplication] delegate]hideProgressView];
    if(serverRequest==kServerCallGetActivities){
        
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id activities=[response objectForKey:@"activities"];
                if (activities != nil && [activities class] != [NSNull class]) {
                    
                    
                    id my_activities=[activities objectForKey:@"my_activities"];
                    if (my_activities != nil && [my_activities class] != [NSNull class]) {
                        NSMutableArray *activitiesArray=[[NSMutableArray alloc]init];
                        for(id el in my_activities){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                             [activitiesArray addObject:actclass];
                        }
                        self.tableData=[NSArray arrayWithArray:activitiesArray];

                    }
                    
                    
                    
                }
                
                
                

                
            }
        }
        
        if([self.tableData count]!=0){
            if([self.tableData count]>3){
                footerActivated=false;
            }
            //[self tableViewHeight];
            [self.tableView reloadData];
        }
        else{
            [self.tableView setHidden:YES];

            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BlankHomePageView" owner:self options:nil];
            BlankHomePageView *blankHomePageView=[nib objectAtIndex:0];
            blankHomePageView.frame=CGRectMake(0, 167, 320, 401);
            blankHomePageView.userInteractionEnabled=YES;
            [self.view addSubview:blankHomePageView];

        }
    }
}

- (NSInteger)tableViewHeight
{
	[self.tableView layoutIfNeeded];
	NSInteger tableheight;
	tableheight=[self.tableView contentSize].height;
    [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:tableheight] forKey:@"height"];
	return tableheight;
}
- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
        [(AppDelegate*)[[UIApplication sharedApplication] delegate]hideProgressView];
    
    if(serverRequest==kServerCallGetActivities)
    {
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
        [(AppDelegate*)[[UIApplication sharedApplication] delegate]hideProgressView];
    if(serverRequest==kServerCallGetActivities)
    {
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}

@end
