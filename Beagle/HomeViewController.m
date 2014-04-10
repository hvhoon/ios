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
#import "ASIHTTPRequest.h"
#import "ActivityViewController.h"
#import "UIView+HidingView.h"
#import "BlankHomePageView.h"
#import "HomeTableViewCell.h"
#import "BeagleActivityClass.h"
#import "ServerManager.h"
#import "IconDownloader.h"
@interface HomeViewController ()<UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate,HomeTableViewCellDelegate,ServerManagerDelegate,IconDownloaderDelegate>{
    UIView *topNavigationView;
    UIView*bottomNavigationView;
    BOOL footerActivated;
    ServerManager *homeActivityManager;
    NSMutableDictionary *imageDownloadsInProgress;
    NSInteger count;
    UIRefreshControl *refreshControl;
    BOOL isPushAuto;
}
@property(nonatomic, weak) NSTimer *timer;
@property(nonatomic,strong)  NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, strong) NSArray *tableData;
@property(nonatomic, weak) IBOutlet UITableView*tableView;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;
@property (strong,nonatomic) UIRefreshControl *refreshControl;
@property(strong,nonatomic)ServerManager *homeActivityManager;
@end

@implementation HomeViewController
@synthesize homeActivityManager=_homeActivityManager;
@synthesize imageDownloadsInProgress;
@synthesize currentLocation;
@synthesize _locationManager = locationManager;
@synthesize refreshControl;

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
- (void)startStandardUpdates {
    
	if (nil == locationManager) {
		locationManager = [[CLLocationManager alloc] init];
	}
    
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
	// Set a movement threshold for new events.
	locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
    
	[locationManager startUpdatingLocation];
    
	CLLocation *currentLoc = locationManager.location;
	if (currentLoc) {
		self.currentLocation = currentLoc;
	}
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	switch (status) {
		case kCLAuthorizationStatusAuthorized:
			NSLog(@"kCLAuthorizationStatusAuthorized");
			[locationManager startUpdatingLocation];
			break;
		case kCLAuthorizationStatusDenied:
			NSLog(@"kCLAuthorizationStatusDenied");
        {{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Mobbin can’t access your current location.\n\nTo view nearby checkins at your current location, turn on access for Mobbin to your location in the Settings app under Location Services." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alertView show];
            // Disable the post button.
        }}
			break;
		case kCLAuthorizationStatusNotDetermined:
			NSLog(@"kCLAuthorizationStatusNotDetermined");
			break;
		case kCLAuthorizationStatusRestricted:
			NSLog(@"kCLAuthorizationStatusRestricted");
			break;
	}
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.currentLocation=newLocation;
}
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Error: %@", [error description]);
    
	if (error.code == kCLErrorDenied) {
		[locationManager stopUpdatingLocation];
	} else if (error.code == kCLErrorLocationUnknown) {
		// todo: retry?
		// set a timer for five seconds to cycle location, and if it fails again, bail and tell the user.
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
		                                                message:[error description]
		                                               delegate:nil
		                                      cancelButtonTitle:nil
		                                      otherButtonTitles:@"Ok", nil];
		[alert show];
	}
}
- (void)setCurrentLocation:(CLLocation *)aCurrentLocation {
	currentLocation = aCurrentLocation;
    BeagleManager *BG=[BeagleManager SharedInstance];
    BG.currentLocation=currentLocation;
    [locationManager stopUpdatingLocation];
    locationManager.delegate=nil;
    
	dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [self LocationAcquired];
	});
}
#define REFRESH_HEADER_HEIGHT 50.0f

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
     BeagleManager *BG=[BeagleManager SharedInstance];
    if(BG.activtyCreated){
        isPushAuto=TRUE;
        BG.activtyCreated=FALSE;
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
       
        [self refresh:self.refreshControl];
        
    }
    else{
        [self startStandardUpdates];
    }

    }
}


#define kTimerIntervalInSeconds 10
- (void)viewDidLoad
{
    [super viewDidLoad];
    


    if (![self.slidingViewController.underLeftViewController isKindOfClass:[SettingsViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsScreen"];
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[NotificationsViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationsScreen"];
    }
      [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    

    
    UIImage *stockBottomImage1=[BeagleUtilities imageByCropping:[UIImage imageNamed:@"defaultLocation"] toRect:CGRectMake(0, 0, 320, 64) withOrientation:UIImageOrientationDownMirrored];
    topNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 64)];
    
    topNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage1];
    [self.view addSubview:topNavigationView];
    
    
    UIImage *stockBottomImage2=[BeagleUtilities imageByCropping:[UIImage imageNamed:@"defaultLocation"] toRect:CGRectMake(0, 64, 320, 103) withOrientation:UIImageOrientationDownMirrored];
    bottomNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 64, 320, 147)];
    
    bottomNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage2];
    [self.view addSubview:bottomNavigationView];

    
    [self addCityName:@"New York"];
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


    
    self.tableView.backgroundColor=[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    UIView *filterView=[[UIView alloc]initWithFrame:CGRectMake(0, 103, 320, 44)];
    [filterView addSubview:[self renderFilterHeaderView]];
    [bottomNavigationView addSubview:filterView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
        
        [self.refreshControl beginRefreshing];
        
        
    }
    else{
        [self startStandardUpdates];
    }
    isPushAuto=TRUE;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (updateActivityEvents) name:@"AutoRefreshEvents" object:nil];

   
}
-(void)updateActivityEvents{
    isPushAuto=TRUE;
    [self refresh:self.refreshControl];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AutoRefreshEvents" object:nil];
}


-(void)addCityName:(NSString*)name{
    
    UILabel *textLabel=(UILabel*)[self.view viewWithTag:1234];
    if(textLabel!=nil){
        [textLabel removeFromSuperview];
    }
    CGSize size = CGSizeMake(180,999);
    
    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    
    CGRect textRect = [name
                       boundingRectWithSize:size
                       options:NSStringDrawingUsesLineFragmentOrigin
                       attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0],NSForegroundColorAttributeName:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.95],NSParagraphStyleAttributeName: paragraphStyle, }
                       context:nil];
    
    
    UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(16,22, textRect.size.width, textRect.size.height)];
    fromLabel.text = name;
    fromLabel.tag=1234;
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

}
- (void)refresh:(UIRefreshControl *)refreshControl {
    [self.refreshControl beginRefreshing];
    
    if(isPushAuto)
       [self.tableView setContentOffset:CGPointMake(0, -REFRESH_HEADER_HEIGHT) animated:YES];
    //self.tableView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
    if(_homeActivityManager!=nil){
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
    }
    
    _homeActivityManager=[[ServerManager alloc]init];
    _homeActivityManager.delegate=self;
    [_homeActivityManager getActivities];

    

}

-(void)LocationAcquired{
    [self refresh:self.refreshControl];
    
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    CLLocation *newLocation=[[CLLocation alloc]initWithLatitude:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude longitude:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude];
    
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if(!error) {
            BeagleManager *BG=[BeagleManager SharedInstance];
                BG.placemark=[placemarks objectAtIndex:0];
                [self addCityName:[BG.placemark.addressDictionary objectForKey:@"City"]];

                [self retrieveLocationAndUpdateBackgroundPhoto];
            }
                else{
                    NSLog(@"reverseGeocodeLocation: %@", error.description);
                }
            }];

    
    
    
}
-(void)createANewActivity:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ActivityViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"activityScreen"];
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];

    [self.navigationController presentViewController:activityNavigationController animated:YES completion:nil];
    
}
- (void) retrieveLocationAndUpdateBackgroundPhoto {
    
    
                   BeagleManager *BG=[BeagleManager SharedInstance];

    
#if 0
                    NSString *urlString=[NSString stringWithFormat:@"http://api.wunderground.com/api/5706a66cb7258dd4/conditions/q/%@/%@.json",BG.placemark.administrativeArea,[BG.placemark.addressDictionary objectForKey:@"City"]];
                    
#else
                    NSString *urlString=[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f",BG.placemark.location.coordinate.latitude,BG.placemark.location.coordinate.longitude];
                    
#endif
                    
                    
    
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
                        BG.weatherCondition=weather;
                        
                        

                            //Flickr
                            [[BGFlickrManager sharedManager] randomPhotoRequest:^(FlickrRequestInfo * flickrRequestInfo, NSError * error) {
                                
                                if(!error) {
                                    [self.timer invalidate];
                                    
                                    [self crossDissolvePhotos:flickrRequestInfo.photo withTitle:flickrRequestInfo.userInfo];
                                } else {
                                    
                                    //Error : Stock photos
                                    [self crossDissolvePhotos:[UIImage imageNamed:@"defaultLocation"] withTitle:@""];
                                    count++;
                                    NSLog(@"Flickr: %@", error.description);
                                    if(count!=3)
                                        [self retrieveLocationAndUpdateBackgroundPhoto];
                                }
                            }];

                }];
                    [request setFailedBlock:^{
                        NSError *error = [request error];
                        NSLog(@"error=%@",[error description]);
                    }];
                    [request startAsynchronous];

}


- (void) crossDissolvePhotos:(UIImage *) photo withTitle:(NSString *) title {
    [UIView transitionWithView:self.view duration:1.0f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        
        UIImage *stockBottomImage1=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 0, 320, 64) withOrientation:UIImageOrientationDownMirrored];
        
        topNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage1];
        
        
        UIImage *stockBottomImage2=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 64, 320, 103) withOrientation:UIImageOrientationDownMirrored];
        bottomNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage2];
        
    } completion:NULL];
}

-(UIView*)renderFilterHeaderView{
    UIView *headerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    headerView.backgroundColor=[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
    
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

    return 174.0f+textRect.size.height;
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
    
//    if(!footerActivated)
//        [bottomNavigationView scrollViewWillBeginDragging:scrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//        if(!footerActivated)
//    [bottomNavigationView scrollViewDidScroll:scrollView];
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

    
}

-(void)searchIconClicked:(id)sender{
    
    //[self showSearchBarAndAnimateWithListViewInMiddle];
}
-(void)showSearchBarAndAnimateWithListViewInMiddle{
    
    if (!footerActivated) {
		[UIView beginAnimations:@"expandFooter" context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 64;
        
        
		[bottomNavigationView setHidden:YES];
        [self.tableView setFrame:tableViewFrame];
        
        self.tableView.tableHeaderView=nil;
        
        UISearchBar *headerView = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        headerView.hidden = NO;
        headerView.delegate=self;
        self.tableView.tableHeaderView = headerView;
        headerView.showsCancelButton=YES;
        [headerView becomeFirstResponder];

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
        tableViewFrame.origin.y = 211;
        
        [self.tableView setFrame:tableViewFrame];
		[UIView commitAnimations];
		footerActivated = NO;
	}
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    if(serverRequest==kServerCallGetActivities){
        
        
        _homeActivityManager.delegate = nil;
        [_homeActivityManager releaseServerManager];
        _homeActivityManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id activities=[response objectForKey:@"activities"];
                if (activities != nil && [activities class] != [NSNull class]) {
                    
                    
                    id crtbyu=[activities objectForKey:@"beagle_crtbyu"];
                    if (crtbyu != nil && [crtbyu class] != [NSNull class]) {
                        NSMutableArray *activitiesArray=[[NSMutableArray alloc]init];
                        for(id el in crtbyu){
                            BeagleActivityClass *actclass=[[BeagleActivityClass alloc]initWithDictionary:el];
                             [activitiesArray addObject:actclass];
                        }
                        self.tableData=[NSArray arrayWithArray:activitiesArray];

                    }
                    
                    
                    
                }
                
                
                

                
            }
        }
        if(isPushAuto){
            isPushAuto=FALSE;
        }
        [self.refreshControl endRefreshing];
        //self.tableView.contentInset = UIEdgeInsetsZero;
        
        if([self.tableData count]!=0){
            self.imageDownloadsInProgress = [NSMutableDictionary dictionary];

            [self.tableView setHidden:NO];
            
            BlankHomePageView *blankHomePageView=(BlankHomePageView*)[self.view  viewWithTag:1245];
            [blankHomePageView setHidden:YES];
            if([self.tableData count]>3){
                footerActivated=NO;
            }
            [self.tableView reloadData];
        }
        else{
            [self.tableView setHidden:YES];

            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"BlankHomePageView" owner:self options:nil];
            BlankHomePageView *blankHomePageView=[nib objectAtIndex:0];
            blankHomePageView.frame=CGRectMake(0, 167, 320, 401);
            blankHomePageView.userInteractionEnabled=YES;
            blankHomePageView.tag=1245;
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
    if(isPushAuto){
        isPushAuto=FALSE;
    }
    [self.refreshControl endRefreshing];
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
    if(isPushAuto){
        isPushAuto=FALSE;
    }
    [self.refreshControl endRefreshing];
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
