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
#import "BeagleUserClass.h"
#import "ServerManager.h"
#import "BeagleUserClass.h"

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
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

    [self.navigationController setNavigationBarHidden:NO];
    
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
        [self imageCircular:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];
    }
    
//    NSArray* fontNames = [UIFont fontNamesForFamilyName:@"Helvetica Neue"];
//    for( NSString* aFontName in fontNames ) {
//        NSLog( @"Font name: %@", aFontName );
//    }
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0]];
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(0, 0, 30, 30);
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    CGSize constrainedSize = CGSizeMake(320, 9999);
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0], NSFontAttributeName,[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                                          nil];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Cancel" attributes:attributesDictionary];
    
    CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    if (requiredHeight.size.width > 320) {
        requiredHeight = CGRectMake(0,0, 320, requiredHeight.size.height);
    }
    CGRect newFrame = cancelButton.frame;
    newFrame.size.height = requiredHeight.size.height;
    newFrame.size.width = requiredHeight.size.width;
    cancelButton.frame=newFrame;
    [cancelButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    cancelButton.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
    self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    
    
    UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    createButton.frame = CGRectMake(0, 0, 30, 30);
    [createButton setTitle:@"Create" forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(createButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                                          nil];
    
    string = [[NSMutableAttributedString alloc] initWithString:@"Create" attributes:attributesDictionary];
    
     requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    if (requiredHeight.size.width > 320) {
        requiredHeight = CGRectMake(0,0, 320, requiredHeight.size.height);
    }
    newFrame = createButton.frame;
    newFrame.size.height = requiredHeight.size.height;
    newFrame.size.width = requiredHeight.size.width;
    createButton.frame=newFrame;
    [createButton setTitleColor:[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    createButton.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithCustomView:createButton];
    
    self.navigationItem.rightBarButtonItem.enabled=NO;
    
    
    placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, descriptionTextView.frame.size.width - 20.0, 34.0)];
    [placeholderLabel setText:@"Tell us more..."];
    // placeholderLabel is instance variable retained by view controller
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    placeholderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0];
    placeholderLabel.textColor=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    
    descriptionTextView.returnKeyType=UIReturnKeyDone;
    [descriptionTextView setFont:[UIFont fontWithName:@"HelveticaNeue" size:17.0f]];
    // textView is UITextView object you want add placeholder text to
    [descriptionTextView addSubview:placeholderLabel];
    
    countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",(unsigned long)140-[descriptionTextView.text length]];
    [descriptionTextView becomeFirstResponder];


    [timeFilterButton setTitle:@"Next Weekend" forState:UIControlStateNormal];
    [timeFilterButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [timeFilterButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    [timeFilterButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
    
    [visibilityFilterButton setTitle:@"Friends Only" forState:UIControlStateNormal];
    [visibilityFilterButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [visibilityFilterButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    [visibilityFilterButton.titleLabel setTextAlignment:NSTextAlignmentLeft];

    NSString *locationFilter=[NSString stringWithFormat:@"%@, %@",[[[BeagleManager SharedInstance]placemark].addressDictionary objectForKey:@"City"],[[BeagleManager SharedInstance]placemark].administrativeArea];
    [locationFilterButton setTitle:locationFilter forState:UIControlStateNormal];
    [locationFilterButton setTitleColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [locationFilterButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    [locationFilterButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
   locationFilterButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    backgroundView.backgroundColor=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    
    [countTextLabel setTextAlignment:NSTextAlignmentRight];
    [countTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]];
    [countTextLabel setTextColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0]];
    

	// Do any additional setup after loading the view.
}


- (void)loadProfileImage:(NSString*)url {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}

-(void)imageCircular:(UIImage*)image{
    if(image.size.height != image.size.width)
        image = [BeagleUtilities autoCrop:image];
//
    // If the image needs to be compressed
    if(image.size.height > 35 || image.size.width > 35)
        image = [BeagleUtilities compressImage:image size:CGSizeMake(35,35)];
    
    UIGraphicsBeginImageContext(image.size);
    {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGAffineTransform trnsfrm = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0));
        trnsfrm = CGAffineTransformConcat(trnsfrm, CGAffineTransformMakeTranslation(0.0, image.size.height));
        CGContextConcatCTM(ctx, trnsfrm);
        CGContextBeginPath(ctx);
        CGContextAddEllipseInRect(ctx, CGRectMake(0.0, 0.0, image.size.width, image.size.height));
        CGContextClip(ctx);
        CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, image.size.width, image.size.height), image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    profileImageView.image=image;

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
    NSDate *EndOfWeek2=[myCalendar dateFromComponents:components];
    
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:00];

    NSDate *EndOfWeek3=[myCalendar dateFromComponents:components];
    
    NSDate *newDate1 = [EndOfWeek2 dateByAddingTimeInterval:60*60*24*6];
    NSDate *newDate2 = [EndOfWeek3 dateByAddingTimeInterval:60*60*24*7];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    bg_activity.startActivityDate=[dateFormatter stringFromDate:newDate1];
    bg_activity.endActivityDate=[dateFormatter stringFromDate:newDate2];
    bg_activity.visibiltyFilter=@"Friends Only";
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
    
    if(![textView hasText]) {
        placeholderLabel.hidden = NO;
    }
    else{
        placeholderLabel.hidden = YES;
    }
    CGSize constrainedSize = CGSizeMake(320, 9999);
    UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    createButton.frame = CGRectMake(0, 0, 30, 30);
    [createButton setTitle:@"Create" forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(createButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if([[textView text]length]!=0){
        
        
        NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,[UIColor colorWithRed:0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                                              nil];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Create" attributes:attributesDictionary];
        
        CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        if (requiredHeight.size.width > 320) {
            requiredHeight = CGRectMake(0,0, 320, requiredHeight.size.height);
        }
        CGRect newFrame = createButton.frame;
        newFrame.size.height = requiredHeight.size.height;
        newFrame.size.width = requiredHeight.size.width;
        createButton.frame=newFrame;
        [createButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        createButton.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
        self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithCustomView:createButton];
        self.navigationItem.rightBarButtonItem.enabled=YES;
        
        
    }
    else{
        NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                                              nil];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Create" attributes:attributesDictionary];
        
        CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        if (requiredHeight.size.width > 320) {
            requiredHeight = CGRectMake(0,0, 320, requiredHeight.size.height);
        }
        CGRect  newFrame = createButton.frame;
        newFrame.size.height = requiredHeight.size.height;
        newFrame.size.width = requiredHeight.size.width;
        createButton.frame=newFrame;
        [createButton setTitleColor:[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        createButton.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
        self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithCustomView:createButton];
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
