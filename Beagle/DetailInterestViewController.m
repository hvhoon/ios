//
//  DetailInterestViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "DetailInterestViewController.h"
#import "BeagleActivityClass.h"
#import "BeaglePlayerScrollMenu.h"
#import "PlayerProfileItem.h"
#import "InterestChatClass.h"
static NSString * const CellIdentifier = @"cell";
@interface DetailInterestViewController ()<BeaglePlayerScrollMenuDelegate,ServerManagerDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIImageView *profileImageView;
@property (strong,nonatomic)BeaglePlayerScrollMenu *scrollMenu;
@property(nonatomic,strong)ServerManager*interestUpdateManager;
@end

@implementation DetailInterestViewController
@synthesize interestActivity,interestServerManager=_interestServerManager,backgroundView=_backgroundView;
@synthesize scrollMenu=_scrollMenu;
@synthesize interestUpdateManager=_interestUpdateManager;
@synthesize profileImageView=_profileImageView;
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
    
    _backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, 72, 320, 400)];
    _backgroundView.backgroundColor=[UIColor whiteColor];
    
    _profileImageView=[[UIImageView alloc]initWithFrame:CGRectMake(16, 8, 52, 52)];
    [_backgroundView addSubview:_profileImageView];
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
    
    
        
        UILabel *activityDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72,commentTextRect.size.width,commentTextRect.size.height)];
        activityDescLabel.numberOfLines=0;
        activityDescLabel.lineBreakMode=NSLineBreakByWordWrapping;
        activityDescLabel.backgroundColor = [UIColor clearColor];
        activityDescLabel.text = interestActivity.activityDesc;
        activityDescLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
        activityDescLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
        activityDescLabel.textAlignment = NSTextAlignmentLeft;
        [_backgroundView addSubview:activityDescLabel];

    
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
           [UIColor blackColor],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    CGSize participantsCountTextSize;
    UILabel *participantsCountTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72+commentTextRect.size.height+16,
                                                                                    participantsCountTextSize.width, participantsCountTextSize.height)];
    
    participantsCountTextLabel.backgroundColor = [UIColor clearColor];
    participantsCountTextLabel.textColor = [UIColor blackColor];
    participantsCountTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    participantsCountTextLabel.textAlignment = NSTextAlignmentLeft;
    participantsCountTextLabel.tag=347;
    
    if(self.interestActivity.participantsCount>0 && self.interestActivity.dos2Count>0){
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                                                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                                                                                 attributes:attrs
                                                                                                                                                                                                    context:nil].size;

        participantsCountTextLabel.frame=CGRectMake(16,72+commentTextRect.size.height+16,
                                          participantsCountTextSize.width, participantsCountTextSize.height);
        participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count];

        
        
        
        
    }else{
        
        participantsCountTextSize = [[NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                                                       attributes:attrs
                                                                                                                                          context:nil].size;
        participantsCountTextLabel.frame=CGRectMake(16,72+commentTextRect.size.height+16,
                                                    participantsCountTextSize.width, participantsCountTextSize.height);
        participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
    }
    [_backgroundView addSubview:participantsCountTextLabel];

    [style setAlignment:NSTextAlignmentLeft];
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
             [UIColor blackColor],NSForegroundColorAttributeName,
             style, NSParagraphStyleAttributeName, nil];
    
    CGFloat variance=0.0f;

    if(self.interestActivity.ownerid==[[[BeagleManager SharedInstance]beaglePlayer]beagleUserId]){
        //owner
        if(self.interestActivity.participantsCount>1){
            _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, 72+commentTextRect.size.height+16+participantsCountTextSize.height+16, 268, 55)];
            [_backgroundView addSubview:_scrollMenu];
            variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+55;
        }
        else{
            
            
            CGSize noParticipantsTextSize = [@"No participants" boundingRectWithSize:CGSizeMake(300, 999)
                                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                                               attributes:attrs
                                                                                  context:nil].size;
            
            UILabel *noParticipantsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72+commentTextRect.size.height+16+participantsCountTextSize.height+16, noParticipantsTextSize.width, noParticipantsTextSize.height)];
            
            noParticipantsLabel.backgroundColor = [UIColor clearColor];
            noParticipantsLabel.text = @"No participants";
            noParticipantsLabel.textColor = [UIColor blackColor];
            noParticipantsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
            noParticipantsLabel.textAlignment = NSTextAlignmentLeft;
            [_backgroundView addSubview:noParticipantsLabel];
            
            variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+noParticipantsTextSize.height;


        }
    }
    else if(self.interestActivity.isParticipant){
        //not a owner but a participant
         if(self.interestActivity.participantsCount>1){
             _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, 72+commentTextRect.size.height+16+participantsCountTextSize.height+16, 268, 55)];
             [_backgroundView addSubview:_scrollMenu];
             variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+55;


         }
         else{
             CGSize noParticipantsTextSize = [@"Be the first one to express interest!" boundingRectWithSize:CGSizeMake(300, 999)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                                           attributes:attrs
                                                                              context:nil].size;
             
             UILabel *noParticipantsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72+commentTextRect.size.height+16+participantsCountTextSize.height+16, noParticipantsTextSize.width, noParticipantsTextSize.height)];
             
             noParticipantsLabel.backgroundColor = [UIColor clearColor];
             noParticipantsLabel.text = @"Be the first one to express interest!";
             noParticipantsLabel.textColor = [UIColor blackColor];
             noParticipantsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
             noParticipantsLabel.textAlignment = NSTextAlignmentLeft;
             [_backgroundView addSubview:noParticipantsLabel];
             variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+noParticipantsTextSize.height;


         }
    }
    else{
        //neither owner nor  participant
        if(self.interestActivity.participantsCount>1){
            variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+55;

            _scrollMenu=[[BeaglePlayerScrollMenu alloc]initWithFrame:CGRectMake(16, 72+commentTextRect.size.height+16+participantsCountTextSize.height+16, 268, 55)];
            [_backgroundView addSubview:_scrollMenu];
            
        }
        else{
            CGSize noParticipantsTextSize = [@"Be the first one to express interest!" boundingRectWithSize:CGSizeMake(300, 999)
                                                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                attributes:attrs
                                                                                                   context:nil].size;
            
            UILabel *noParticipantsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,72+commentTextRect.size.height+16+participantsCountTextSize.height+16, noParticipantsTextSize.width, noParticipantsTextSize.height)];
            
            noParticipantsLabel.backgroundColor = [UIColor clearColor];
            noParticipantsLabel.text = @"Be the first one to express interest!";
            noParticipantsLabel.textColor = [UIColor blackColor];
            noParticipantsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
            noParticipantsLabel.textAlignment = NSTextAlignmentLeft;
            [_backgroundView addSubview:noParticipantsLabel];
            variance=72+commentTextRect.size.height+16+participantsCountTextSize.height+16+noParticipantsTextSize.height;

            
        }

    }
    
    
    UIImageView *starImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, variance+16, 16, 15)];
    starImageView.tag=345;
    [_backgroundView addSubview:starImageView];

    if(self.interestActivity.isParticipant){
        
    starImageView.image=[UIImage imageNamed:@"Star"];

    }
    
    else{
        
        starImageView.image=[UIImage imageNamed:@"Star-Unfilled"];
        
    }
    
    attrs=[NSDictionary dictionaryWithObjectsAndKeys:
           [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f], NSFontAttributeName,
           [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
           style, NSParagraphStyleAttributeName, nil];
    
    

    
    CGSize interestedSize = [@"I'm Interested"  boundingRectWithSize:CGSizeMake(288, 999)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:attrs
                                                             context:nil].size;
    
    UILabel *interestedLabel = [[UILabel alloc] initWithFrame:CGRectMake(42,variance+16, interestedSize.width, interestedSize.height)];
    interestedLabel.tag=346;
    interestedLabel.backgroundColor = [UIColor clearColor];
    interestedLabel.text = @"I'm Interested";
    interestedLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
    interestedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
    interestedLabel.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:interestedLabel];
    
    interestedLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestures:)];
    [interestedLabel addGestureRecognizer:tapGesture];

    
    
    UIImageView *commentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(306-21, variance+16, 21, 18)];
    [_backgroundView addSubview:commentImageView];

    if(self.interestActivity.postCount>0)
        commentImageView.image=[UIImage imageNamed:@"Comment"];
    else{
        commentImageView.image=[UIImage imageNamed:@"Add-Comment"];
    }
    
    [style setAlignment:NSTextAlignmentLeft];
    
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f], NSFontAttributeName,
             [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0],NSForegroundColorAttributeName,
             style, NSParagraphStyleAttributeName, nil];
    
    CGSize postCountTextSize = [[NSString stringWithFormat:@"%ld",(long)self.interestActivity.postCount]  boundingRectWithSize:CGSizeMake(288, 999)
                                                                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                                                                               attributes:attrs
                                                                                                                  context:nil].size;
    
    UILabel *postCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(300-21- postCountTextSize.width,variance+16-2, postCountTextSize.width, postCountTextSize.height)];
    
    postCountLabel.backgroundColor = [UIColor clearColor];
    postCountLabel.text = [NSString stringWithFormat:@"%ld",(long)self.interestActivity.postCount];
    postCountLabel.textColor = [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0];
    postCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    postCountLabel.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:postCountLabel];

    
    _backgroundView.frame=CGRectMake(0, 72, 320, variance+16+18+16);
    [self.view addSubview:_backgroundView];

    
}


-(void)handleTapGestures:(UITapGestureRecognizer*)sender{
    
    if(self.interestActivity.dosRelation!=0){
        if(_interestUpdateManager!=nil){
            _interestUpdateManager.delegate = nil;
            [_interestUpdateManager releaseServerManager];
            _interestUpdateManager = nil;
        }
        
        _interestUpdateManager=[[ServerManager alloc]init];
        _interestUpdateManager.delegate=self;
        
        if (self.interestActivity.isParticipant) {
            [_interestUpdateManager removeMembership:self.interestActivity.activityId];
        }
        else{
            [_interestUpdateManager participateMembership:self.interestActivity.activityId];
        }
        
    }
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
    if(serverRequest==kServerCallGetDetailedInterest){
        
        
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id interest=[response objectForKey:@"interest"];
                if (interest != nil && [interest class] != [NSNull class]) {
                    
                    
                    id participants=[interest objectForKey:@"participants"];
                    if (participants != nil && [participants class] != [NSNull class] && [participants count]!=0) {
                        NSMutableArray *participantsArray=[[NSMutableArray alloc]init];
                        for(id el in participants){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithDictionary:el];
                            [participantsArray addObject:userClass];
                        }
                        [self setUpPlayerScroll:participantsArray];

                        
                    }
                     id chats=[interest objectForKey:@"chats"];
                    if (chats != nil && [chats class] != [NSNull class] && [chats count]!=0) {
                        NSMutableArray *chatsArray=[[NSMutableArray alloc]init];
                        for(id el in chats){
                            InterestChatClass *userClass=[[InterestChatClass alloc]initWithDictionary:el];
                            [chatsArray addObject:userClass];
                        }
                        
                        
                    }
                    
                }
                
                

                
            }
        }
        
        
    }
    
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            id message=[response objectForKey:@"message"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                UILabel *participantsCountTextLabel=(UILabel*)[self.view viewWithTag:347];
                if([message isEqualToString:@"Joined"]){
                    self.interestActivity.participantsCount++;
                    
                }else{
                    self.interestActivity.participantsCount--;
                    
                }
                if(self.interestActivity.participantsCount>0 && self.interestActivity.dos2Count>0){
                    
                    participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested -  %ld Friends",(long)self.interestActivity.participantsCount,(long)self.interestActivity.dos2Count];
                }else{
                     participantsCountTextLabel.text = [NSString stringWithFormat:@"%ld Interested",(long)self.interestActivity.participantsCount];
                }
                UIImageView *starImageView=(UIImageView*)[self.view viewWithTag:345];

                if(self.interestActivity.isParticipant){
                    self.interestActivity.isParticipant=FALSE;
                    starImageView.image=[UIImage imageNamed:@"Star-Unfilled"];
                }
                else{
                    self.interestActivity.isParticipant=TRUE;
                    starImageView.image=[UIImage imageNamed:@"Star"];
                }
                
                

            }
        }
        
    }
}


- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    if(serverRequest==kServerCallGetDetailedInterest)
    {
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
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
    if(serverRequest==kServerCallGetDetailedInterest)
    {
        _interestServerManager.delegate = nil;
        [_interestServerManager releaseServerManager];
        _interestServerManager = nil;
    }
    else if(serverRequest==kServerCallLeaveInterest||serverRequest==kServerCallParticipateInterest){
        _interestUpdateManager.delegate = nil;
        [_interestUpdateManager releaseServerManager];
        _interestUpdateManager = nil;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorAlertTitle message:errorLimitedConnectivityMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}
- (void)setUpPlayerScroll:(NSArray*)elements{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (BeagleUserClass * player in elements)
    {
        
		PlayerProfileItem *item = [[PlayerProfileItem alloc] initProfileItem:player.profileImageUrl
                                   
                                                label:player.first_name playerId:player.beagleUserId
                                           andAction: ^(PlayerProfileItem *item)  {
                                               
                                               NSLog(@"Block called! %ld", (long)player.beagleUserId);
                                               //DO somenthing here
                                           }];
        
		[array addObject:item];
	}
    
	[_scrollMenu setUpPlayerScrollMenu:array];
    
	//We choose an animation when the user touch the item (you can create your own animation)
	[_scrollMenu setAnimationType:PlayerZoomOut];
	_scrollMenu.delegate = self;
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
