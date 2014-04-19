//
//  DetailInterestViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "DetailInterestViewController.h"
#import "BeagleActivityClass.h"
@interface DetailInterestViewController ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@end

@implementation DetailInterestViewController
@synthesize interestActivity,interestServerManager=_interestServerManager;
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
    
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0]];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 39, 30);
    [backButton setBackgroundImage:[UIImage imageNamed:@"back-button"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];

    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f], NSFontAttributeName,
                           [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];
    
    CGSize dateTextSize = [@"Later Today" boundingRectWithSize:CGSizeMake(300, 999)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil].size;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, dateTextSize.width, dateTextSize.height)];
    
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"Later Today";
    titleLabel.textColor = [UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
    
    if(interestActivity.profilePhotoImage==nil){
        
        [self imageCircular:[UIImage imageNamed:@"picbox"]];
        
        
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadProfileImage:)
                                            object:interestActivity.photoUrl];
        [queue addOperation:operation];
        
    }
    else{
        _profileImageView.image=[BeagleUtilities imageCircularBySize:interestActivity.profilePhotoImage sqr:52.0];
    }


    
    [style setAlignment:NSTextAlignmentRight];
    UIColor *color=[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
                           color,NSForegroundColorAttributeName,
                           style, NSParagraphStyleAttributeName, nil];
    
    CGSize locationTextSize = [interestActivity.locationName boundingRectWithSize:CGSizeMake(300, 999)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil].size;
    
    UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(304-locationTextSize.width,8, locationTextSize.width, locationTextSize.height)];
    
    locationLabel.backgroundColor = [UIColor clearColor];
    locationLabel.text = interestActivity.locationName;
    locationLabel.textColor = color;
    locationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    locationLabel.textAlignment = NSTextAlignmentRight;
    [_backgroundView addSubview:locationLabel];
    
    [style setAlignment:NSTextAlignmentLeft];
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
           [UIColor blackColor],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    CGSize organizerNameSize=[interestActivity.organizerName boundingRectWithSize:CGSizeMake(300, 999)
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                  attributes:attrs
                                                                     context:nil].size;
    
    UILabel *organizerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(76,52-organizerNameSize.height, organizerNameSize.width, organizerNameSize.height)];
    
    organizerNameLabel.backgroundColor = [UIColor clearColor];
    organizerNameLabel.text = interestActivity.organizerName;
    organizerNameLabel.textColor = [UIColor blackColor];
    organizerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    organizerNameLabel.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:organizerNameLabel];

    
    UIImageView *dosRelationImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DOS2"]];
    dosRelationImageView.frame = CGRectMake(76+10+organizerNameSize.width,52-15, 27, 15);
    [_backgroundView addSubview:dosRelationImageView];
    
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [UIFont fontWithName:@"HelveticaNeue" size:17.0f], NSFontAttributeName,
             [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
             style, NSParagraphStyleAttributeName,NSLineBreakByWordWrapping, nil];
    
    CGSize maximumLabelSize = CGSizeMake(288,999);
    
    CGRect commentTextRect = [self.interestActivity.activityDesc boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:attrs
                                                                         context:nil];
    
    
        
        UILabel *activityDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,69,commentTextRect.size.width,commentTextRect.size.height)];
        activityDescLabel.numberOfLines=0;
        activityDescLabel.lineBreakMode=NSLineBreakByWordWrapping;
        activityDescLabel.backgroundColor = [UIColor clearColor];
        activityDescLabel.text = interestActivity.organizerName;
        activityDescLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
        activityDescLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        activityDescLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:activityDescLabel];

    
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
           [UIColor blackColor],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    CGSize participantsCountTextSize;
    UILabel *participantsCountTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,69+8+commentTextRect.size.height+16+locationTextSize.height,
                                                                                    participantsCountTextSize.width, participantsCountTextSize.height)];
    
    participantsCountTextLabel.backgroundColor = [UIColor clearColor];
    participantsCountTextLabel.textColor = [UIColor blackColor];
    participantsCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    participantsCountTextLabel.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:participantsCountTextLabel];
    
    if(self.interestActivity.participantsCount>0 && self.interestActivity.dos2Count>0){
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                                                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                                                                                 attributes:attrs
                                                                                                                                                                                                    context:nil].size;

        participantsCountTextLabel.frame=CGRectMake(16,69+8+commentTextRect.size.height+16+locationTextSize.height,
                                          participantsCountTextSize.width, participantsCountTextSize.height);
        participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count];

        
        
        
        
    }else{
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                       attributes:attrs
                                                                                                                                          context:nil].size;
        participantsCountTextLabel.frame=CGRectMake(16,69+8+commentTextRect.size.height+16+locationTextSize.height,
                                                    participantsCountTextSize.width, participantsCountTextSize.height);
        participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
    }





    // Do any additional setup after loading the view.
}

- (void)loadProfileImage:(NSString*)url {
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    interestActivity.profilePhotoImage=image;
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    _profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:52.0f];
}

-(void)backButtonClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    if(serverRequest==kServercallGetDetailedInterest){
        
        
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
        
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
                        
                    }
                    
                    
                    
                }
                
                
                
                
                
            }
        }
        
        
    }
}


- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    if(serverRequest==kServercallGetDetailedInterest)
    {
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    if(serverRequest==kServercallGetDetailedInterest)
    {
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
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
