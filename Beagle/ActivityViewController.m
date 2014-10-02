//
//  ActivityViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ActivityViewController.h"
#import "TimeFilterView.h"
#import "EventTimeBlurView.h"
#import "EventVisibilityBlurView.h"
#import "LocationBlurView.h"
#import "DetailInterestViewController.h"
#import "InterestInviteViewController.h"
#import "CreateAnimationBlurView.h"
#define DISABLED_ALPHA 0.5f

enum Weeks {
    SUNDAY = 1,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
};
@interface ActivityViewController ()<UITextViewDelegate,ServerManagerDelegate,EventTimeBlurViewDelegate,EventVisibilityBlurViewDelegate,LocationBlurViewDelegate,InAppNotificationViewDelegate,CreateAnimationBlurViewDelegate>{
    IBOutlet UIImageView *profileImageView;
    IBOutlet UITextView *descriptionTextView;
    UILabel *placeholderLabel;
    IBOutlet UILabel *countTextLabel;
    IBOutlet UIButton *timeFilterButton;
    IBOutlet UIButton *visibilityFilterButton;
    IBOutlet UIButton *locationFilterButton;
    IBOutlet UIButton *deleteButton;
    IBOutlet UIImageView *backgroundView;
    ServerManager *activityServerManager;
    ServerManager *deleteActivityManager;
    NSInteger timeIndex;
    NSInteger visibilityIndex;
    NSTimer *timer;
    NSInteger locationType;
}
@property (nonatomic, strong) NSMutableIndexSet *optionIndices;
@property(nonatomic, strong) EventTimeBlurView *blrTimeView;
@property(nonatomic, strong) EventVisibilityBlurView *blrVisbilityView;
@property(nonatomic, strong) LocationBlurView *blrLocationView;
@property(nonatomic,strong)CreateAnimationBlurView *animationBlurView;
@property(nonatomic,strong)ServerManager *activityServerManager;
@property(nonatomic,strong)ServerManager *deleteActivityManager;
@end

@implementation ActivityViewController
@synthesize bg_activity;
@synthesize activityServerManager;
@synthesize editState;
@synthesize deleteActivityManager=_deleteActivityManager;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (createButtonClicked:) name:kLocationUpdateReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLocationError) name:kErrorToGetLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveBackgroundInNotification:) name:kRemoteNotificationReceivedNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postInAppNotification:) name:kNotificationForInterestPost object:Nil];
    
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    [self.navigationController.navigationBar setTintColor:[[BeagleManager SharedInstance] darkDominantColor]];
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    if(BG.activityDeleted){
        BG.activityDeleted=FALSE;
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }

    
}
- (void)viewWillLayoutSubviews {
    
    if (![descriptionTextView isFirstResponder]) {
        [descriptionTextView becomeFirstResponder];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    // All the variables we need to present this screen correctly
    self.blrTimeView=[[EventTimeBlurView alloc]initWithFrame:[UIScreen mainScreen].bounds parentView:self.view];
    self.blrVisbilityView=[EventVisibilityBlurView loadVisibilityFilter:self.view];
    self.blrVisbilityView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.blrVisbilityView.delegate=self;
    self.blrTimeView.delegate=self;
    NSString *visibilityText = nil;
    [self.blrVisbilityView updateConstraints];
    UIColor* clickable = [[BeagleManager SharedInstance] darkDominantColor];
    self.animationBlurView=[CreateAnimationBlurView loadCreateAnimationView:self.view];
    self.animationBlurView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.animationBlurView.delegate=self;
    self.blrLocationView=[LocationBlurView loadLocationFilter:self.view];
    self.blrLocationView.delegate=self;
    
    // Not giving the user the ability to change the location yet!
    locationFilterButton.userInteractionEnabled = NO;
    
    // Setting the color for he Visibility, Time filter and Delete buttons
    // Visibility text and image
    [visibilityFilterButton setTitleColor:clickable forState:UIControlStateNormal];
    [visibilityFilterButton setTitleColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
    [visibilityFilterButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Visibility"] withColor:clickable] forState:UIControlStateNormal];
    [visibilityFilterButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Visibility"] withColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    [visibilityFilterButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Outline-Visibility"] withColor:clickable] forState:UIControlStateNormal];
    [visibilityFilterButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Outline-Visibility"] withColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    
    // Time text and image
    [timeFilterButton setTitleColor:clickable forState:UIControlStateNormal];
    [timeFilterButton setTitleColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA] forState:UIControlStateHighlighted];
    [timeFilterButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Time"] withColor:clickable] forState:UIControlStateNormal];
    [timeFilterButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Time"] withColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    [timeFilterButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Outline-Time"] withColor:clickable] forState:UIControlStateNormal];
    [timeFilterButton setBackgroundImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Button-Outline-Time"] withColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    
    // Delete button
    [deleteButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Delete"] withColor:clickable] forState:UIControlStateNormal];
    [deleteButton setImage:[BeagleUtilities colorImage:[UIImage imageNamed:@"Delete"] withColor:[clickable colorWithAlphaComponent:DISABLED_ALPHA]] forState:UIControlStateHighlighted];
    
    // If we are in CREATE mode
    if(!editState){
        bg_activity=[[BeagleActivityClass alloc]init];
        bg_activity.state=[[BeagleManager SharedInstance]placemark].administrativeArea;
        bg_activity.city=[[[BeagleManager SharedInstance]placemark].addressDictionary objectForKey:@"City"];
        bg_activity.latitude=[[BeagleManager SharedInstance]currentLocation].coordinate.latitude;
        bg_activity.longitude=[[BeagleManager SharedInstance]currentLocation].coordinate.longitude;
    }
    self.optionIndices = [NSMutableIndexSet indexSetWithIndex:1];
    
    NSString *location = bg_activity.city;
    
    // Error handling
    if(location==nil)
        location = @"your city";
    
    // Add your profile image regardless of state!
    if([[[BeagleManager SharedInstance]beaglePlayer]profileData]==nil){
        
        [self imageCircular:[UIImage imageNamed:@"picbox"]];

        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl]];
        [queue addOperation:operation];

    }
    else{
        [self imageCircular:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];
        [self.animationBlurView loadAnimationView:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];
    }
    
    // Setup the navigation controller
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTintColor:clickable];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClicked:)];
        
    // Either way update the count given the text in the description field
    countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",(unsigned long)140-[descriptionTextView.text length]];
    [countTextLabel setTextAlignment:NSTextAlignmentRight];
    
    // We are SAVING if the activity has already been created
    if(editState){
        // Setup the navigation bar
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(createButtonClicked:)];
        [self.navigationItem.rightBarButtonItem setTintColor:[BeagleUtilities returnBeagleColor:13]];
        self.navigationItem.rightBarButtonItem.enabled=YES;
        
        // Add the description field and populate it
        descriptionTextView.text=self.bg_activity.activityDesc;
        
        // Setup the labels appropriately
        timeIndex=-1;
        visibilityIndex=-1;
        [visibilityFilterButton setTitle:self.bg_activity.visibility forState:UIControlStateNormal];
        [timeFilterButton setTitle:[BeagleUtilities activityTime:self.bg_activity.startActivityDate endate:self.bg_activity.endActivityDate] forState:UIControlStateNormal];
        visibilityFilterButton.hidden=YES;
        deleteButton.hidden=NO;
        
        // Setting up the correct privacy text
        if([bg_activity.visibility isEqualToString:@"public"])
            visibilityText = [NSString stringWithFormat:@"Visible to everybody in %@", location];
        else if([bg_activity.visibility isEqualToString:@"private"])
            visibilityText = [NSString stringWithFormat:@"Visible to friends in %@", location];
        else
            visibilityText = @"Visible to select friends";
    }
    // Or we are simply CREATING a new activity
    else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleDone target:self action:@selector(createButtonClicked:)];
        [self.navigationItem.rightBarButtonItem setTintColor:[[[BeagleManager SharedInstance] darkDominantColor] colorWithAlphaComponent:DISABLED_ALPHA]];
        self.navigationItem.rightBarButtonItem.enabled=NO;
        
        // Setting up the labels for a new activity
        timeIndex=1;
        visibilityIndex=2;
        [visibilityFilterButton setTitle:@"Friends" forState:UIControlStateNormal];
        [timeFilterButton setTitle:@"Later Today" forState:UIControlStateNormal];
        
        // Setting the visibility label
        switch (visibilityIndex) {
            case 2:
                visibilityText = [NSString stringWithFormat:@"We'll tell your friends in %@", location];
                break;
            case 3:
                visibilityText = @"We'll tell the friends you selected";
            default:
                visibilityText = [NSString stringWithFormat:@"We'll tell your friends in %@", location];
                break;
        }
    }
    
    // Setting the visibility text all the way at the end
    [locationFilterButton setTitleColor:[[BeagleManager SharedInstance] darkDominantColor] forState:UIControlStateNormal];
    [locationFilterButton setTitle:visibilityText forState:UIControlStateNormal];
    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude==0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude==0.0f){
        locationType=1;
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
        return;
    }
    
    if([self.bg_activity.city length]==0 && [self.bg_activity.state length]==0){
        
        locationType=1;
        //reverse geocode
        [self reverseGeocode];
    }

//    descriptionTextView.keyboardType=UIKeyboardTypeDefault;
//    descriptionTextView.autocorrectionType=UITextAutocorrectionTypeYes;
    
//    [descriptionTextView becomeFirstResponder];

}
	// Do any additional setup after loading the view.


-(void)viewDidDisappear:(BOOL)animated{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationForInterestPost object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationUpdateReceived object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kErrorToGetLocation object:nil];
}

- (void)didReceiveBackgroundInNotification:(NSNotification*) note{

    BeagleNotificationClass *notifObject=[BeagleUtilities getNotificationObject:note];
    
  if(notifObject.notifType==2 && notifObject.activity.activityId!=0 && (notifObject.notificationType==WHAT_CHANGE_TYPE||notifObject.notificationType==DATE_CHANGE_TYPE||notifObject.notificationType==GOING_TYPE||notifObject.notificationType==LEAVED_ACTIVITY_TYPE|| notifObject.notificationType==ACTIVITY_CREATION_TYPE || notifObject.notificationType==JOINED_ACTIVITY_TYPE)){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        viewController.inappNotification=YES;
        
        UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
        [self presentViewController:activityNavigationController animated:YES completion:^{
            [viewController.interestServerManager getDetailedInterest:notifObject.activity.activityId];
            
        }];
      [BeagleUtilities updateBadgeInfoOnTheServer:notifObject.notificationId];

      
    }
    else if (notifObject.notifType==2 && notifObject.notificationType==CANCEL_ACTIVITY_TYPE){
        [self dismissViewControllerAnimated:YES completion:Nil];
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
    
    if(notifObject.notifType==2 && notifObject.activity.activityId!=0 && notifObject.notificationType==CHAT_TYPE){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DetailInterestViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestScreen"];
        viewController.interestServerManager=[[ServerManager alloc]init];
        viewController.interestServerManager.delegate=viewController;
        viewController.isRedirected=TRUE;
        viewController.toLastPost=TRUE;
        viewController.inappNotification=YES;
        
        UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
        [self presentViewController:activityNavigationController animated:YES completion:^{
            [viewController.interestServerManager getDetailedInterest:notifObject.activity.activityId];

        }];
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
    viewController.inappNotification=YES;
    if(notification.notificationType==CHAT_TYPE)
        viewController.toLastPost=TRUE;
    
    UINavigationController *activityNavigationController=[[UINavigationController alloc]initWithRootViewController:viewController];
    [self presentViewController:activityNavigationController animated:YES completion:^{
        [viewController.interestServerManager getDetailedInterest:notification.activity.activityId];
        
    }];
    [BeagleUtilities updateBadgeInfoOnTheServer:notification.notificationId];

}


#pragma mark InAppNotificationView Handler
- (void)notificationView:(InAppNotificationView *)inAppNotification didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    NSLog(@"Button Index = %ld", (long)buttonIndex);
//    [BeagleUtilities updateBadgeInfoOnTheServer:inAppNotification.notification.notificationId];
}

- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
    [self.animationBlurView loadAnimationView:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];

    UIImage* image =[[UIImage alloc] initWithData:imageData];
    if (image)
        [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}

-(void)imageCircular:(UIImage*)image{
    
    profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:70.0f];
}

-(void)cancelButtonClicked:(id)sender{
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
#else
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
#endif

}
-(void)updateCreateEventParameters{
    bg_activity.activityDesc=descriptionTextView.text;
    bg_activity.activityType=1;
    NSDate *today = [NSDate date];
    NSLog(@"Today date is %@",today);
    
    //Set the first day of the week
    NSCalendar *gregorian = [[NSCalendar alloc]        initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:today];
    NSInteger dayofweek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:today] weekday];// this will give you current day of week
    [components setDay:([components day] - ((dayofweek) - 2))];// for beginning of the week.
    NSDate *beginningOfWeek = [gregorian dateFromComponents:components];
    
    //Set the last day of the Week End Date
    NSCalendar *gregorianEnd = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *componentsEnd = [gregorianEnd components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:today];
    NSInteger Enddayofweek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:today] weekday];// this will give you current day of week
    [componentsEnd setDay:([componentsEnd day]+(7-Enddayofweek))];// get the last day of the week (before the weekend)
    NSDate *EndOfWeek = [gregorianEnd dateFromComponents:componentsEnd]; // set the last day of the week (before the weekend)
    NSCalendar* myCalendar = [NSCalendar currentCalendar];
    components = [myCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                               fromDate:EndOfWeek];
    // Set the start of the weekend
    [components setHour:00];
    [components setMinute:00];
    [components setSecond:00];
    NSDate *startOfThisWeekend=[myCalendar dateFromComponents:components];
    NSDate *thisSatStart = startOfThisWeekend;
    
    // If it so happens that we are already in the weekend
    if([thisSatStart timeIntervalSinceDate:[NSDate date]]<0){
        thisSatStart=[NSDate date];
    }
    
    // Set the end of the weekend
    [componentsEnd setHour:23];
    [componentsEnd setMinute:59];
    [componentsEnd setSecond:59];
    [componentsEnd setDay:([componentsEnd day]+1)]; // Advance one day ahead
    NSDate *endOfThisWeekend=[myCalendar dateFromComponents:componentsEnd];
    
    // Set the dates for next week
    NSDate *nextSatStart = [startOfThisWeekend dateByAddingTimeInterval:60*60*24*7]; // Add 1 weej from the start of this weekend
    NSDate *nextSundayEnd = [endOfThisWeekend dateByAddingTimeInterval:60*60*24*7]; // Add 1 week from the end of this week
    NSDate *nextMondayStart = [startOfThisWeekend dateByAddingTimeInterval:60*60*48]; // Add 2 days from the start of this weekend
    
    // Set tomorrow start and end
    components = [myCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                               fromDate:[[NSDate date] dateByAddingTimeInterval:60*60*24]];
    [components setHour:00];
    [components setMinute:00];
    [components setSecond:00];
    NSDate *tomorrowStart=[myCalendar dateFromComponents:components];
    
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    NSDate *tomorrowEnd=[myCalendar dateFromComponents:components];
    
    // Set later today
    components = [myCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                               fromDate:[NSDate date]];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    NSDate *laterToday=[myCalendar dateFromComponents:components];
    
    // Set in 1 month start and end dates
    NSDateComponents *monthComponents = [[NSDateComponents alloc] init];
    monthComponents.month = 1;
    NSLog(@"The beginning of this week = %@",beginningOfWeek);
    
#if 0
    NSDate *oneMonthFromNow = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0];
    
    // Verifying all date stuff
    NSLog(@"Later Today= %@",laterToday);
    NSLog(@"Tomorrow start = %@",tomorrowStart);
    NSLog(@"Tomorrow end = %@",tomorrowEnd);
    NSLog(@"The beginning of this weekend = %@", startOfThisWeekend);
    NSLog(@"The End of this weekend = %@", endOfThisWeekend);
    NSLog(@"The beginning of next week = %@", nextMondayStart);
    NSLog(@"The beginning of next weekend = %@", nextSatStart);
    NSLog(@"The end of next weekend = %@", nextSundayEnd);
    NSLog(@"One Month From Now = %@",oneMonthFromNow);
    NSLog(@"One Month from Now = %@",endOfMonth);
#endif
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    [components setMonth:[components month]+1];
    [components setDay:0];
    NSDate *endOfMonth = [myCalendar dateFromComponents:components];
    
    switch (timeIndex) {
            // Setting the start date as NOW and the end date as LATER TODAY
        case 1: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:[NSDate date]];//later today start
            bg_activity.endActivityDate=[dateFormatter stringFromDate:laterToday];//later today end
        }
            break;
            // Setting the start date as NOW and the end date as END OF THIS WEEKEND
        case 2: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:[NSDate date]];//this weekStart
            bg_activity.endActivityDate=[dateFormatter stringFromDate:endOfThisWeekend];//this  week end
        }
            break;
            // Setting the start date as NEXT MONDAY and the end date as the END OF NEXT WEEKEND
        case 3: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:nextMondayStart];//next week start
            bg_activity.endActivityDate=[dateFormatter stringFromDate:nextSundayEnd];//next weekend end
        }
            break;
            // Setting the start date as NOW and the end date as the END OF THE MONTH
        case 4: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:[NSDate date]];//month start
            bg_activity.endActivityDate=[dateFormatter stringFromDate:endOfMonth];//month end
        }
            break;
            // Setting the start date as TOMORROW and the end date as TOMORROW
        case 5: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:tomorrowStart];//tomorrow start
            bg_activity.endActivityDate=[dateFormatter stringFromDate:tomorrowEnd];//tomorrow end
        }
            break;
            // Setting the start date as THIS WEEKEND START and the end date as THIS WEEKEND END
        case 6: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:thisSatStart];//this weekend start
            bg_activity.endActivityDate=[dateFormatter stringFromDate:endOfThisWeekend];//this weekend end
        }
            break;
            // Setting the start date as NEXT SATURDAY START and the end date as NEXT SUNDAY END
        case 7: {
            bg_activity.startActivityDate=[dateFormatter stringFromDate:nextSatStart];//next weekend start
            bg_activity.endActivityDate=[dateFormatter stringFromDate:nextSundayEnd];//next weekend end
        }
            break;
    }
    
    switch (visibilityIndex) {
        case 1:
        {
            bg_activity.visibility=@"public";
            
        }
            break;
            
        case 2:
        {
            bg_activity.visibility=@"private";
            
        }
            break;
            
            
        case 3:
        {
            bg_activity.visibility=@"custom";
            
        }
            break;
    }
    
    bg_activity.ownerid=[[BeagleManager SharedInstance]beaglePlayer].beagleUserId;

}
-(void)createButtonClicked:(id)sender{
    
    if(locationType==1){
        if([self.bg_activity.city length]==0 && [self.bg_activity.state length]==0){
            
            //reverse geocode
            [self reverseGeocode];
        }

        return;

    }
    
    if([descriptionTextView.text length]==0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Description"
                                                        message:@"Your interest must have a description."
                                                       delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
        [alert show];
        return;
    }

    
    [self updateCreateEventParameters];
    
    if(visibilityIndex==3 && !editState){
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        InterestInviteViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestInvite"];
        viewController.interestDetail=bg_activity;
        [self.navigationController pushViewController:viewController animated:YES];
        return;
        
    }

    
    
    if(self.activityServerManager!=nil){
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
    }

    self.activityServerManager=[[ServerManager alloc]init];
    self.activityServerManager.delegate=self;
    
    if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude==0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude==0.0f){
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] startStandardUpdates];
        return;
    }
    
    if([self.bg_activity.city length]==0 && [self.bg_activity.state length]==0){

        //reverse geocode
        
        [self reverseGeocode];
        return;
    }


    if(editState) {
        [self.activityServerManager updateActivityOnBeagle:bg_activity];
    }
    else{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
        [self.animationBlurView blurWithColor];
        [self.animationBlurView crossDissolveShow];
        UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
        [keyboard addSubview:self.animationBlurView];

       [self.activityServerManager createActivityOnBeagle:bg_activity];
    }
    
}

-(void)reverseGeocode{
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    CLLocation *newLocation=[[CLLocation alloc]initWithLatitude:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude longitude:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude];
    
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if(!error) {
            BeagleManager *BG=[BeagleManager SharedInstance];
            BG.placemark=[placemarks objectAtIndex:0];
            bg_activity.state=[[BeagleManager SharedInstance]placemark].administrativeArea;
            bg_activity.city=[[[BeagleManager SharedInstance]placemark].addressDictionary objectForKey:@"City"];
            if(locationType!=1)
                [self createButtonClicked:nil];
            else if (locationType==1){
                NSString *visibilityText=nil;
                switch (visibilityIndex) {
                    case 2:
                        visibilityText = [NSString stringWithFormat:@"We'll tell your friends in %@", self.bg_activity.city];
                        break;
                    case 3:
                        visibilityText = @"We'll tell the friends you selected";
                    default:
                        visibilityText = [NSString stringWithFormat:@"We'll tell your friends in %@", self.bg_activity.city];
                        break;
                }
            [locationFilterButton setTitle:visibilityText forState:UIControlStateNormal];
            }
            
        }
        else{
            NSLog(@"reverseGeocodeLocation: %@", error.description);
            [self showLocationError];
        }
    }];

}
#define kDeleteActivity 2
-(IBAction)deleteButtonClicked:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete this activity?"
                                                    message:nil
                                                   delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No",nil];
    alert.tag=kDeleteActivity;
    [alert show];

}

#pragma mark -
#pragma mark UIAlertView methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    [alertView resignFirstResponder];
    
        if (buttonIndex == 0) {
            
            switch (alertView.tag) {
                case kDeleteActivity:
                {
                    if(_deleteActivityManager!=nil){
                        _deleteActivityManager.delegate = nil;
                        [_deleteActivityManager releaseServerManager];
                        _deleteActivityManager = nil;
                    }
                    
                    _deleteActivityManager=[[ServerManager alloc]init];
                    _deleteActivityManager.delegate=self;
                    [_deleteActivityManager deleteAnInterest:bg_activity.activityId];
                }
                    break;
                    
            }
        }
        
        else{
            NSLog(@"Clicked Cancel Button");
        }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITexViewDelegate Methods


-(void)textViewDidChange:(UITextView *)textView{
    
    [self.navigationItem.rightBarButtonItem setTintColor:[[[BeagleManager SharedInstance] darkDominantColor] colorWithAlphaComponent:DISABLED_ALPHA]];
    self.navigationItem.rightBarButtonItem.enabled=NO;

    if([BeagleUtilities checkIfTheTextIsBlank:[textView text]]){
        
      if([[BeagleManager SharedInstance]currentLocation].coordinate.latitude!=0.0f && [[BeagleManager SharedInstance] currentLocation].coordinate.longitude!=0.0f){
          
        if([self.bg_activity.city length]!=0 && [self.bg_activity.state length]!=0){
            
            [self.navigationItem.rightBarButtonItem setTintColor:[BeagleUtilities returnBeagleColor:13]];
            self.navigationItem.rightBarButtonItem.enabled=YES;
            locationType=2;

        }
      }

    }

}

-(void)textViewDidBeginEditing:(UITextView *)textView{

}


-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	BOOL flag = NO;
	
	
	if([text length] == 0)
	{
		if([textView.text length] != 0)
		{
			flag = YES;
			NSString *Temp = countTextLabel.text;
			int j = [Temp intValue];
            
			j = j-1 ;
			countTextLabel.text= [[NSString alloc] initWithFormat:@"%ld",(long)(141-[textView.text length])];
            
			return YES;
		}
		else {
			return NO;
		}
		
		
	}
	else if([[textView text] length] == 140)
	{
        return NO;
	}
	if(flag == NO)
	{
		countTextLabel.text= [[NSString alloc] initWithFormat:@"%ld",(long)(140-[descriptionTextView.text length]-1)];
		
		
	}
	
	
	return YES;
	
	
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if (![textView hasText]) {
        placeholderLabel.hidden = NO;
    }
}


- (IBAction)visibilityFilter:(id)sender{
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [self.blrVisbilityView blurWithColor];
    [self.blrVisbilityView crossDissolveShow];
    UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
    
    [keyboard addSubview:self.blrVisbilityView];

}

- (IBAction)locationFilter:(id)sender{
    
    [descriptionTextView resignFirstResponder];
    self.navigationController.navigationBar.alpha=0.0;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [self.blrLocationView blurWithColor];
    [self.blrLocationView crossDissolveShow];
    [self.view addSubview:self.blrLocationView];

    
}


- (IBAction)timeFilter:(id)sender{

    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [self.blrTimeView blurWithColor:[BlurColorComponents darkEffect]];
    [self.blrTimeView crossDissolveShow];
    [self.blrTimeView updatePickerDateForEditState];

    if(editState){
        if([BeagleUtilities checkIfTheDateHasBeenSetUsingAPicker:self.bg_activity.startActivityDate endDate:self.bg_activity.endActivityDate]){
            [self.blrTimeView updatePickerTime:self.bg_activity.startActivityDate];
        }
    }
    UIWindow* keyboard = [[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1];
    
    [keyboard addSubview:self.blrTimeView];
        
}

-(void)interestLocationSelected:(CLPlacemark*)placemark{
    
    
    bg_activity.state=placemark.administrativeArea;
    bg_activity.city=[placemark.addressDictionary objectForKey:@"City"];
    self.bg_activity.latitude=placemark.location.coordinate.latitude;
    self.bg_activity.longitude=placemark.location.coordinate.longitude;
    
    
    NSString *locationFilter=[NSString stringWithFormat:@"%@, %@",[placemark.addressDictionary objectForKey:@"City"],placemark.administrativeArea];
    [locationFilterButton setTitle:locationFilter forState:UIControlStateNormal];
    

}

#pragma mark -
#pragma mark Event Blur Delegate Method

-(void)changeTimeFilter:(NSInteger)index{
    
    timeIndex=index;
    switch (index) {
        case 1:
        {
            
          [timeFilterButton setTitle:@"Later Today" forState:UIControlStateNormal];
        }
            break;
            
        case 2:
        {
                [timeFilterButton setTitle:@"This Week" forState:UIControlStateNormal];
        }
            break;
            
            
        case 3:
        {
            [timeFilterButton setTitle:@"Next Week" forState:UIControlStateNormal];
        }
            break;
            
            
        case 4:
        {
            [timeFilterButton setTitle:@"This Month" forState:UIControlStateNormal];
        }
            break;
            
            
        case 5:
        {

            [timeFilterButton setTitle:@"Tomorrow" forState:UIControlStateNormal];
        }
            break;
            
            
        case 6:
        {
            [timeFilterButton setTitle:@"This Weekend" forState:UIControlStateNormal];
        }
            
            break;
            
            
        case 7:
        {
            [timeFilterButton setTitle:@"Next Weekend" forState:UIControlStateNormal];
        }
            break;
            
        case 8:
        {
            [timeFilterButton setTitle:@"Pick a Date" forState:UIControlStateNormal];
        }
            break;
            
            
    }
}

- (void)dismissEventFilter{
    [descriptionTextView becomeFirstResponder];
    self.navigationController.navigationBar.alpha=1.0;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];

}
-(void)pickDate:(NSDate*)eventDate{
    timeIndex=8;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setAMSymbol:@"am"];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    NSString *eventDateString = [dateFormatter stringFromDate:eventDate];

    
    NSDate *dateSelected = [dateFormatter dateFromString:eventDateString];//add the string
    NSString *todayDate = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *currentDate=[dateFormatter dateFromString:todayDate];

    
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    NSInteger destinationGMTOffset1 = [destinationTimeZone secondsFromGMTForDate:dateSelected];
    NSInteger destinationGMTOffset2 = [destinationTimeZone secondsFromGMTForDate:currentDate];
    
    NSTimeInterval interval2 = destinationGMTOffset1;
    NSTimeInterval interval3 = destinationGMTOffset2;
    
    NSDate* destinationDate =[[NSDate alloc] initWithTimeInterval:interval2 sinceDate:dateSelected];
    NSDate* currentDateTime =[[NSDate alloc] initWithTimeInterval:interval3 sinceDate:currentDate];

    NSInteger differenceInDays =
    [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:destinationDate]-
    [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:currentDateTime];

    NSDateComponents*components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSSecondCalendarUnit|NSMinuteCalendarUnit
                                                fromDate:eventDate];

    if(differenceInDays==0){
        NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
        localDateFormatter.dateFormat=@"h:mma";
        [localDateFormatter setPMSymbol:@"pm"];
        [localDateFormatter setAMSymbol:@"am"];

        [timeFilterButton setTitle:[NSString stringWithFormat:@"Today, %@",[localDateFormatter stringFromDate:eventDate]] forState:UIControlStateNormal];

        //user has picked today
    }else if(differenceInDays==1){
        NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
        localDateFormatter.dateFormat=@"h:mma";
        [localDateFormatter setPMSymbol:@"pm"];
        [localDateFormatter setAMSymbol:@"am"];
        
        [timeFilterButton setTitle:[NSString stringWithFormat:@"Tomorrow, %@",[localDateFormatter stringFromDate:eventDate]] forState:UIControlStateNormal];
    }
    else{
        NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
        
        localDateFormatter.dateFormat=@"EEE, MMM d, h:mma";
        [localDateFormatter setPMSymbol:@"pm"];
        [localDateFormatter setAMSymbol:@"am"];
        [localDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSString *formattedDateString = [localDateFormatter stringFromDate:eventDate];
        [timeFilterButton setTitle:formattedDateString forState:UIControlStateNormal];
        
    }
    
    [components setHour: [components hour]];
    [components setMinute:[components minute]];
    [components setSecond:[components second]];
    
    self.bg_activity.startActivityDate=[dateFormatter stringFromDate:[calendar dateFromComponents:components]];
    [components setHour: [components hour]+3];
    [components setMinute:[components minute]+1];
    [components setSecond:[components second]+1];
    self.bg_activity.endActivityDate=[dateFormatter stringFromDate:[calendar dateFromComponents:components]];
    
    

}

-(void)changeVisibilityFilter:(NSInteger)index{
    visibilityIndex=index;
    [self.navigationItem.rightBarButtonItem setTitle:@"Create"];
    
    NSString *location = bg_activity.city;
    
    if(location == nil)
        location = @"your city";
    
    switch (index) {
        case 1:
        {
            [visibilityFilterButton setTitle:@"Public" forState:UIControlStateNormal];
            [locationFilterButton setTitle:[NSString stringWithFormat:@"We'll tell your friends in %@", location] forState:UIControlStateNormal];
        }
            break;
            
        case 2:
        {
            [visibilityFilterButton setTitle:@"Friends" forState:UIControlStateNormal];
            [locationFilterButton setTitle:[NSString stringWithFormat:@"We'll tell your friends in %@", location] forState:UIControlStateNormal];

        }
            break;
        case 3:
        {
            [visibilityFilterButton setTitle:@"Private" forState:UIControlStateNormal];
            [locationFilterButton setTitle:[NSString stringWithFormat:@"We'll tell the friends you selected"] forState:UIControlStateNormal];
            [self.navigationItem.rightBarButtonItem setTitle:@"Select"];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            InterestInviteViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"interestInvite"];
            [self updateCreateEventParameters];
            viewController.interestDetail=bg_activity;
            [self.navigationController pushViewController:viewController animated:YES];


        }
            break;
    }
}
-(void)showLocationError{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Where's Waldo?"
                                                    message:@"We are unable to get your current location"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    [alert show];

}
-(void)dealloc{
    
    
    for (ASIHTTPRequest *req in [ASIHTTPRequest.sharedQueue operations]) {
        [req clearDelegatesAndCancel];
        [req setDelegate:nil];
        [req setDidFailSelector:nil];
        [req setDidFinishSelector:nil];
    }
    [ASIHTTPRequest.sharedQueue cancelAllOperations];
}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    

    if(serverRequest==kServerCallCreateActivity||serverRequest==kServerCallEditActivity){
        
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;

        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                if(serverRequest==kServerCallCreateActivity){
                    
                    id player=[response objectForKey:@"player"];
                    if (player != nil && [status class] != [NSNull class]){
                        
                        self.bg_activity.activityId=[[player objectForKey:@"id"]integerValue];
                        self.bg_activity.organizerName =[NSString stringWithFormat:@"%@ %@",[[[BeagleManager SharedInstance]beaglePlayer]first_name],[[[BeagleManager SharedInstance]beaglePlayer]last_name]];
                        self.bg_activity.locationName=[NSString stringWithFormat:@"%@, %@",self.bg_activity.city,self.bg_activity.state];

                        self.bg_activity.dosRelation = 0;
                        self.bg_activity.dos1count = 0;
                        self.bg_activity.participantsCount = 0;
                        self.bg_activity.isParticipant=1;
                        self.bg_activity.postCount = 0;
                        self.bg_activity.photoUrl=[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl];
                        self.bg_activity.profilePhotoImage=[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]];
                        
                    }
                    [self.animationBlurView show];
                    timer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                             target: self
                                                           selector:@selector(hideCreateOverlay)
                                                           userInfo: nil repeats:NO];

                }else if (serverRequest==kServerCallEditActivity){
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
                    [self.navigationController dismissViewControllerAnimated:NO completion:^{
                        [descriptionTextView becomeFirstResponder];
                        [descriptionTextView resignFirstResponder];
                        
                    }];
#else
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
#endif
                }

            }
        }
        
    }
    else if (serverRequest==kServerCallDeleteActivity){
        
        _deleteActivityManager.delegate = nil;
        [_deleteActivityManager releaseServerManager];
        _deleteActivityManager = nil;

        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                BeagleManager *BG=[BeagleManager SharedInstance];
                BG.activityDeleted=TRUE;
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
                [self.navigationController dismissViewControllerAnimated:NO completion:^{
                    [descriptionTextView becomeFirstResponder];
                    [descriptionTextView resignFirstResponder];
                    
                }];
#else
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
#endif
                
                
                
            }
        }

    }
    
    BeagleNotificationClass *notifObject=[[BeagleNotificationClass alloc]init];
    notifObject.activity=self.bg_activity;
    if(serverRequest==kServerCallEditActivity)
        notifObject.notificationType=ACTIVITY_UPDATE_TYPE;
    else if (serverRequest==kServerCallDeleteActivity)
        notifObject.notificationType=CANCEL_ACTIVITY_TYPE;
    else if(serverRequest==kServerCallCreateActivity){
        notifObject.notificationType=ACTIVITY_CREATION_TYPE;
    }
    
    NSMutableDictionary *notificationDictionary=[NSMutableDictionary new];
    [notificationDictionary setObject:notifObject forKey:@"notify"];
    NSNotification* notification = [NSNotification notificationWithName:kNotificationHomeAutoRefresh object:self userInfo:notificationDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];


}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{

    if(serverRequest==kServerCallCreateActivity||serverRequest==kServerCallEditActivity)
    {
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
        if(serverRequest==kServerCallCreateActivity){
            [self.animationBlurView hide];
        }

    }
    else if (serverRequest==kServerCallDeleteActivity){
        
        _deleteActivityManager.delegate = nil;
        [_deleteActivityManager releaseServerManager];
        _deleteActivityManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{

    if(serverRequest==kServerCallCreateActivity||serverRequest==kServerCallEditActivity)
    {
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
        if(serverRequest==kServerCallCreateActivity){
                [self.animationBlurView hide];
        }
    }
    else if (serverRequest==kServerCallDeleteActivity){
        
        _deleteActivityManager.delegate = nil;
        [_deleteActivityManager releaseServerManager];
        _deleteActivityManager = nil;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}
-(void)hideCreateOverlay{
    [timer invalidate];
    [self.animationBlurView hide];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    [self.navigationController dismissViewControllerAnimated:NO completion:^{
        [descriptionTextView becomeFirstResponder];
        [descriptionTextView resignFirstResponder];
        
    }];
#else
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
#endif

}
-(void)dismissCreateAnimationBlurView{
    [timer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    [self.navigationController dismissViewControllerAnimated:NO completion:^{
        [descriptionTextView becomeFirstResponder];
        [descriptionTextView resignFirstResponder];
        
    }];
#else
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
#endif

    
}
@end
