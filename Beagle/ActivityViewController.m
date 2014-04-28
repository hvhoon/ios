//
//  ActivityViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

//36e2980516d0e60864cd29c621a09722

#import "ActivityViewController.h"
#import "TimeFilterView.h"
#import "LocationTableViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "BeagleActivityClass.h"

enum Weeks {
    SUNDAY = 1,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
};
@interface ActivityViewController ()<UITextViewDelegate,LocationTableViewDelegate,ServerManagerDelegate>{
    IBOutlet UIImageView *profileImageView;
    IBOutlet UITextView *descriptionTextView;
    UILabel *placeholderLabel;
    IBOutlet UILabel *countTextLabel;
    IBOutlet UIButton *timeFilterButton;
    IBOutlet UIButton *visibilityFilterButton;
    IBOutlet UIButton *locationFilterButton;
    IBOutlet UIImageView *backgroundView;
    ServerManager *activityServerManager;
}
@property (nonatomic, strong) NSMutableIndexSet *optionIndices;
@property(nonatomic,strong)BeagleActivityClass *bg_activity;
@property(nonatomic,strong)ServerManager *activityServerManager;
@end

@implementation ActivityViewController
@synthesize bg_activity;
@synthesize activityServerManager;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    bg_activity=[[BeagleActivityClass alloc]init];
    self.optionIndices = [NSMutableIndexSet indexSetWithIndex:1];
    
    
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
        [self imageCircular:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData] scale:2.0]];
    }
    

    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClicked:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleDone target:self action:@selector(createButtonClicked:)];
    [self.navigationItem.rightBarButtonItem setTintColor:[UIColor darkGrayColor]];
    self.navigationItem.rightBarButtonItem.enabled=NO;
    
    countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",(unsigned long)140-[descriptionTextView.text length]];
    [descriptionTextView becomeFirstResponder];

    [timeFilterButton setTitle:@"Next Weekend" forState:UIControlStateNormal];
    //[timeFilterButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    //[timeFilterButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    //[timeFilterButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
    
    [visibilityFilterButton setTitle:@"Friends Only" forState:UIControlStateNormal];
    //[visibilityFilterButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    //[visibilityFilterButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    //[visibilityFilterButton.titleLabel setTextAlignment:NSTextAlignmentLeft];

    NSString *locationFilter=[NSString stringWithFormat:@"%@, %@",[[[BeagleManager SharedInstance]placemark].addressDictionary objectForKey:@"City"],[[BeagleManager SharedInstance]placemark].administrativeArea];
    [locationFilterButton setTitle:locationFilter forState:UIControlStateNormal];
    //[locationFilterButton setTitleColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    //[locationFilterButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    //[locationFilterButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
   //locationFilterButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    //backgroundView.backgroundColor=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    
    [countTextLabel setTextAlignment:NSTextAlignmentRight];
    //[countTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    //[countTextLabel setTextColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0]];
    

	// Do any additional setup after loading the view.
}


- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}

-(void)imageCircular:(UIImage*)image{
    
    profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:35.0f];
}

-(void)cancelButtonClicked:(id)sender{
    
    [self.navigationController dismissViewControllerAnimated:YES completion:Nil];
}
-(void)createButtonClicked:(id)sender{
    
    if([descriptionTextView.text length]==0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Description"
                                                        message:@"Your activity must have a description."
                                                       delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
        [alert show];
        return;
    }
    bg_activity.activityDesc=descriptionTextView.text;
    bg_activity.visibiltyFilter=@"Friends only";
    
    
    
    NSDate *today = [NSDate date];
    NSLog(@"Today date is %@",today);
    
    //Week Start Date
    
    NSCalendar *gregorian = [[NSCalendar alloc]        initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *components = [gregorian components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:today];
    
    NSInteger dayofweek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:today] weekday];// this will give you current day of week
    
    [components setDay:([components day] - ((dayofweek) - 2))];// for beginning of the week.
    
    NSDate *beginningOfWeek = [gregorian dateFromComponents:components];
    
    
    NSLog(@"%@",beginningOfWeek);
    
    
    
    
    //Week End Date
    
    NSCalendar *gregorianEnd = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *componentsEnd = [gregorianEnd components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:today];
    
    NSInteger Enddayofweek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:today] weekday];// this will give you current day of week
    
    [componentsEnd setDay:([componentsEnd day]+(7-Enddayofweek)+1)];// for end day of the week
    
    NSDate *EndOfWeek = [gregorianEnd dateFromComponents:componentsEnd];
    NSLog(@"%@",EndOfWeek);
    
    NSCalendar* myCalendar = [NSCalendar currentCalendar];
    components = [myCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                 fromDate:EndOfWeek];
    
    
    [components setHour:00];
    [components setMinute:01];
    [components setSecond:00];
    NSLog(@"weekdayComponentsStart=%@",[myCalendar dateFromComponents:components]);
    NSDate *startOfThisWeekend=[myCalendar dateFromComponents:components];
    
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:00];

    NSDate *endOfThisWeekend=[myCalendar dateFromComponents:components];
    
    NSDate *nextFridayStart = [startOfThisWeekend dateByAddingTimeInterval:60*60*24*6];
    NSDate *nextSundayEnd = [endOfThisWeekend dateByAddingTimeInterval:60*60*24*7];
    NSDate *nextMondayStart = [startOfThisWeekend dateByAddingTimeInterval:60*60*24];
    NSDate *thisSatStart = [startOfThisWeekend dateByAddingTimeInterval:-60*60*24];
    if([thisSatStart timeIntervalSinceDate:[NSDate date]]<0){
        thisSatStart=[NSDate date];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
//    NSDate *startActivityDate = [dateFormatter dateFromString:startDate];

    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
//    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//    [dateFormatter setTimeZone:gmt];
    
    
    bg_activity.startActivityDate=[dateFormatter stringFromDate:nextFridayStart];//next weekend
    bg_activity.startActivityDate=[dateFormatter stringFromDate:nextMondayStart];//next week
    bg_activity.startActivityDate=[dateFormatter stringFromDate:thisSatStart];//this weekend start
    bg_activity.endActivityDate=[dateFormatter stringFromDate:nextSundayEnd];
    bg_activity.endActivityDate=[dateFormatter stringFromDate:endOfThisWeekend];//end of this weekend

    bg_activity.visibiltyFilter=@"Public";
    bg_activity.state=[[BeagleManager SharedInstance]placemark].administrativeArea;
    bg_activity.city=[[[BeagleManager SharedInstance]placemark].addressDictionary objectForKey:@"City"];
    bg_activity.timeFilter=@"Next Weekend";
    bg_activity.latitude=[[BeagleManager SharedInstance]currentLocation].coordinate.latitude;
    bg_activity.longitude=[[BeagleManager SharedInstance]currentLocation].coordinate.longitude;

    bg_activity.ownerid=[[BeagleManager SharedInstance]beaglePlayer].beagleUserId;
    
    if(self.activityServerManager!=nil){
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
    }

    self.activityServerManager=[[ServerManager alloc]init];
    self.activityServerManager.delegate=self;
    [self.activityServerManager createActivityOnBeagle:bg_activity];

    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITexViewDelegate Methods


-(void)textViewDidChange:(UITextView *)textView{
    
    if([[textView text]length]!=0){
        
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
        self.navigationItem.rightBarButtonItem.enabled=YES;
    }
    else {
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor darkGrayColor]];
        self.navigationItem.rightBarButtonItem.enabled=NO;
    }

}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    
}
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	BOOL flag = NO;
	
	
	if ([text isEqualToString:@"\n"]){
        [self createButtonClicked:self];
        return NO;
	}
	
	if([text length] == 0)
	{
		if([textView.text length] != 0)
		{
			flag = YES;
			NSString *Temp = countTextLabel.text;
			int j = [Temp intValue];
            
			j = j-1 ;
			countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",141-[textView.text length]];
            
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
		countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",140-[descriptionTextView.text length]-1];
		
		
	}
	
	
	return YES;
	
	
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if (![textView hasText]) {
        placeholderLabel.hidden = NO;
    }
    
    
    
}


- (IBAction)visibilityFilter:(id)sender{
    
}

- (IBAction)locationFilter:(id)sender{
    
    [descriptionTextView resignFirstResponder];
    
    LocationTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"locationScreen"];
    viewController.delegate=self;
    [self presentPopupViewController:viewController animationType:MJPopupViewAnimationSlideLeftLeft];
}


- (IBAction)timeFilter:(id)sender{
    
}

- (void)dismissLocationTable:(LocationTableViewController*)viewController{
    
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideLeftLeft];
    [descriptionTextView becomeFirstResponder];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{

    
    if(serverRequest==kServerCallCreateActivity){
        
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                BeagleManager *BG=[BeagleManager SharedInstance];
                BG.activtyCreated=TRUE;
                [self.navigationController dismissViewControllerAnimated:YES completion:Nil];

            }
        }
        
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{

    if(serverRequest==kServerCallCreateActivity)
    {
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{

    if(serverRequest==kServerCallCreateActivity)
    {
        self.activityServerManager.delegate = nil;
        [self.activityServerManager releaseServerManager];
        self.activityServerManager = nil;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}

@end
