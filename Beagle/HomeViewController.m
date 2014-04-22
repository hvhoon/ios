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
#import "IconDownloader.h"
#import "DetailInterestViewController.h"
#define REFRESH_HEADER_HEIGHT 50.0f
#define stockCroppingCheck 0
#define kTimerIntervalInSeconds 10

@interface HomeViewController ()<UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate,HomeTableViewCellDelegate,ServerManagerDelegate,IconDownloaderDelegate,BlankHomePageViewDelegate>{
    UIView *topNavigationView;
    UIView*bottomNavigationView;
    BOOL footerActivated;
    ServerManager *homeActivityManager;
    NSMutableDictionary *imageDownloadsInProgress;
    NSInteger count;
    UIRefreshControl *refreshControl;
    BOOL isPushAuto;
    NSInteger interestIndex;
}
@property(nonatomic, weak) NSTimer *timer;
@property(nonatomic,strong)  NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, strong) NSArray *tableData;
@property(nonatomic, weak) IBOutlet UITableView*tableView;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;
@property (strong,nonatomic) UIRefreshControl *refreshControl;
@property(strong,nonatomic)ServerManager *homeActivityManager;
@property(strong,nonatomic)ServerManager *interestUpdateManager;
@end

@implementation HomeViewController
@synthesize homeActivityManager=_homeActivityManager;
@synthesize imageDownloadsInProgress;
@synthesize currentLocation;
@synthesize _locationManager = locationManager;
@synthesize refreshControl;
@synthesize interestUpdateManager=_interestUpdateManager;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)updateViewConstraints {
    [super updateViewConstraints];
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"FacebookLogin"]){
        [[BeagleManager SharedInstance]getUserObjectInAutoSignInMode];
    }else{
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"FacebookLogin"];
        [[NSUserDefaults standardUserDefaults]synchronize];

    }


    if (![self.slidingViewController.underLeftViewController isKindOfClass:[SettingsViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsScreen"];
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[NotificationsViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationsScreen"];
    }
      [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
#if stockCroppingCheck
    
    UIImage *stockBottomImage1=[BeagleUtilities imageByCropping:[UIImage imageNamed:@"defaultLocation"] toRect:CGRectMake(0, 0, 320, 64) withOrientation:UIImageOrientationDownMirrored];
    topNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 64)];
    topNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage1];
    [self.view addSubview:topNavigationView];
    
    // Adding a gradient to the top navigation bar so that the image is more visible
    UIImageView *topGradient=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient"]];
    [topNavigationView addSubview:topGradient];
    
    UIImage *stockBottomImage2=[BeagleUtilities imageByCropping:[UIImage imageNamed:@"defaultLocation"] toRect:CGRectMake(0, 64, 320, 103) withOrientation:UIImageOrientationDownMirrored];
    bottomNavigationView=[[UIView alloc]initWithFrame:CGRectMake(0, 64, 320, 147)];
    
    bottomNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage2];
    [self.view addSubview:bottomNavigationView];

#else
    UIImageView *stockImageView= [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 320, 167)];
    stockImageView.image=[UIImage imageNamed:@"defaultLocation"];
    stockImageView.tag=3456;
    [self.view addSubview:stockImageView];
    
    UIImageView *topGradient=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient"]];
    topGradient.frame = CGRectMake(0, 0, 320, 64);
    [self.view addSubview:topGradient];
    
#endif

    [self addCityName:@"New York"];
    UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [eventButton addTarget:self action:@selector(createANewActivity:)forControlEvents:UIControlEventTouchUpInside];
    [eventButton setTitle:@"+" forState:UIControlStateNormal];
    [eventButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    eventButton.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:60.0f];
    [eventButton.titleLabel setTextAlignment:NSTextAlignmentRight];
    eventButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

    eventButton.frame = CGRectMake(244.0, 4.0, 60.0, 60.0);
    
#if stockCroppingCheck
    [topNavigationView addSubview:eventButton];
#else
    [self.view addSubview:eventButton];
#endif
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton addTarget:self action:@selector(revealMenu:)forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setBackgroundImage:[UIImage imageNamed:@"Settings"] forState:UIControlStateNormal];

    
#if stockCroppingCheck
    settingsButton.frame = CGRectMake(16.0, 78.0, 20.0, 13.0);
    [bottomNavigationView addSubview:eventButton];
#else
    settingsButton.frame = CGRectMake(16.0, 142.0, 20.0, 13.0);
    [self.view addSubview:settingsButton];
#endif

    
    UIButton *notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [notificationsButton addTarget:self action:@selector(revealUnderRight:)forControlEvents:UIControlEventTouchUpInside];
    [notificationsButton setBackgroundImage:[UIImage imageNamed:@"Bell-(No-Notications)"] forState:UIControlStateNormal];

    
#if stockCroppingCheck
    notificationsButton.frame = CGRectMake(287.0, 72.0, 17.0, 19.0);
    [bottomNavigationView addSubview:notificationsButton];
#else
    notificationsButton.frame = CGRectMake(287.0, 136.0, 17.0, 19.0);
    [self.view addSubview:notificationsButton];
#endif
    
    
#if stockCroppingCheck
    UIView *filterView=[[UIView alloc]initWithFrame:CGRectMake(0, 103, 320, 44)];
    [filterView addSubview:[self renderFilterHeaderView]];
    [bottomNavigationView addSubview:filterView];
#else
    UIView *filterView=[[UIView alloc]initWithFrame:CGRectMake(0, 167, 320, 44)];
    [filterView addSubview:[self renderFilterHeaderView]];
    [self.view addSubview:filterView];
#endif
    
self.tableView.backgroundColor=[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
        
        [self refresh:self.refreshControl];
        
        
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
#if stockCroppingCheck
    [topNavigationView addSubview:fromLabel];
#else
    [self.view addSubview:fromLabel];
#endif

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
    
    // Setup string to get weather conditions
    NSString *urlString=[NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f",BG.placemark.location.coordinate.latitude,BG.placemark.location.coordinate.longitude];
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        NSError* error;
        NSString *weather=nil;
        NSString *time=nil;
        
        // Pull weather information
        NSString *jsonString = [request responseString];
        
        NSLog(@"Request=%@", jsonString);
        
        NSDictionary* weatherDictionary = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        NSDictionary *current_observation=[weatherDictionary objectForKey:@"weather"];
        
        // Parsing out the weather and time of day info.
        for(id mainWeather in current_observation) {
            weather=[mainWeather objectForKey:@"main"];
            time=[mainWeather objectForKey:@"icon"];
        }
        
        // Figuring out whether it's day or night.
        time = [time substringFromIndex: [time length] - 1];
        time = ([time isEqualToString:@"d"]) ? @"day": @"night";
        
        // Assigning the time of day and the weather
        BG.timeOfDay=time;
        BG.weatherCondition=weather;
        
        // Pull image from Flickr
        [[BGFlickrManager sharedManager] randomPhotoRequest:^(FlickrRequestInfo * flickrRequestInfo, NSError * error) {
            if(!error) {
                [self.timer invalidate];
                [self crossDissolvePhotos:flickrRequestInfo.photo withTitle:flickrRequestInfo.userInfo];
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
    [UIView transitionWithView:self.view duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
#if stockCroppingCheck

        UIImage *stockBottomImage1=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 0, 320, 64) withOrientation:UIImageOrientationDownMirrored];
        topNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage1];
        
        UIImage *stockBottomImage2=[BeagleUtilities imageByCropping:photo toRect:CGRectMake(0, 64, 320, 103) withOrientation:UIImageOrientationDownMirrored];
        bottomNavigationView.backgroundColor=[UIColor colorWithPatternImage:stockBottomImage2];
        
#else
        UIImageView *stockImageView=(UIImageView*)[self.view viewWithTag:3456];
        stockImageView.image=photo;
        [stockImageView setContentMode:UIViewContentModeScaleAspectFit];
        
#endif

         
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

    if(indexPath.row==[self.tableData count]-1){
        return 174.0f+textRect.size.height;
    }
    return 182.0f+textRect.size.height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    HomeTableViewCell *cell = (HomeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell =[[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    
    cell.delegate=self;
    cell.cellIndex=indexPath.row;
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
    
#if stockCroppingCheck
    if(!footerActivated)
        [bottomNavigationView scrollViewWillBeginDragging:scrollView];
#endif
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
#if stockCroppingCheck
    if(!footerActivated)
[bottomNavigationView scrollViewDidScroll:scrollView];
    
#endif
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self hideSearchBarAndAnimateWithListViewInMiddle];

    
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
- (NSInteger)tableViewHeight
{
	[self.tableView layoutIfNeeded];
	NSInteger tableheight;
	tableheight=[self.tableView contentSize].height;
    [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:tableheight] forKey:@"height"];
	return tableheight;
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
                    
                    
                    id happenarndu=[activities objectForKey:@"beagle_happenarndu"];
                    if (happenarndu != nil && [happenarndu class] != [NSNull class]) {
                        NSMutableArray *activitiesArray=[[NSMutableArray alloc]init];
                        for(id el in happenarndu){
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
            blankHomePageView.delegate=self;
            [blankHomePageView updateViewConstraints];
            blankHomePageView.userInteractionEnabled=YES;
            blankHomePageView.tag=1245;
            [self.view addSubview:blankHomePageView];

        }
        
        
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
            _interestUpdateManager.delegate = nil;
            [_interestUpdateManager releaseServerManager];
            _interestUpdateManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                 BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:interestIndex];
                    if(play.isParticipant){
                        play.isParticipant=FALSE;
                    }
                    else{
                        play.isParticipant=TRUE;
                    }
                    [self.tableView reloadData];
                    
            
       }
        }

    }
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
    else if(serverRequest==kServerCallLeaveInterest ||serverRequest==kServerCallParticipateInterest){
            _interestUpdateManager.delegate = nil;
            [_interestUpdateManager releaseServerManager];
            _interestUpdateManager = nil;
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
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
    }

    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}
#pragma mark - filter  option calls
-(void)filterOptionClicked:(NSInteger)index{
    switch (index) {
        case 0:
        {
            
        }
            break;
            
        case 1:
        {
            
        }
            break;

            
        case 2:
        {
            
        }
            break;

            
        case 3:
        {
            [self createANewActivity:self];
        }
            break;

            
    }
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
#pragma mark - detail Interest Selected 

-(void)detailedInterestScreenRedirect:(NSInteger)index{
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:index];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
    viewController.interestServerManager=[[ServerManager alloc]init];
    viewController.interestServerManager.delegate=viewController;
    [viewController.interestServerManager getDetailedInterest:play.activityId];
    viewController.interestActivity=play;
    [self.navigationController pushViewController:viewController animated:YES];

}

-(void)updateInterestedStatus:(NSInteger)index {
    BeagleActivityClass *play = (BeagleActivityClass *)[self.tableData objectAtIndex:index];
    interestIndex=index;
    
    if(_interestUpdateManager!=nil){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
    }
    
    _interestUpdateManager=[[ServerManager alloc]init];
    _interestUpdateManager.delegate=self;
    
    if (play.isParticipant) {
        [_interestUpdateManager removeMembership:play.activityId];
    }
    else{
        [_interestUpdateManager participateMembership:play.activityId];
    }
}
@end

