//
//  FriendsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 19/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "FriendsViewController.h"
#import "BeagleUserClass.h"
@interface FriendsViewController ()<ServerManagerDelegate>
@property(nonatomic,strong)ServerManager*friendsManager;
@property(nonatomic,strong)NSArray *commonBeagleFriendsArray;
@property(nonatomic,strong)NSArray *commonFacebookFriendsArray;

@end

@implementation FriendsViewController
@synthesize friendsManager=_friendsManager;
@synthesize friendId;
@synthesize commonBeagleFriendsArray=_commonBeagleFriendsArray;
@synthesize commonFacebookFriendsArray=_commonFacebookFriendsArray;
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
    
    if(_friendsManager!=nil){
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
    }
    
    _friendsManager=[[ServerManager alloc]init];
    _friendsManager.delegate=self;
    [_friendsManager getMutualFriendsNetwork:friendId];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallGetProfileMutualFriends){
        
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id profile=[response objectForKey:@"profile"];
                if (profile != nil && [profile class] != [NSNull class]) {
                    
                    NSArray *beagle_friends=[profile objectForKey:@"beagle_friends"];
                    if (beagle_friends != nil && [beagle_friends class] != [NSNull class] && [beagle_friends count]!=0) {
                        
                        
                        NSMutableArray *beagleFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in beagle_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [beagleFriendsArray addObject:userClass];
                        }
                        
                        if([beagleFriendsArray count]!=0){
                            _commonBeagleFriendsArray=[NSArray arrayWithArray:beagleFriendsArray];
                        }
                        
                    }
                    NSArray *facebook_friends=[profile objectForKey:@"facebook_friends"];
                    if (facebook_friends != nil && [facebook_friends class] != [NSNull class] && [facebook_friends count]!=0) {

                        NSMutableArray *facebookFriendsArray=[[NSMutableArray alloc]init];
                        for(id el in facebook_friends){
                            BeagleUserClass *userClass=[[BeagleUserClass alloc]initWithProfileDictionary:el];
                            [facebookFriendsArray addObject:userClass];
                        }
                        
                        if([facebookFriendsArray count]!=0){
                            _commonFacebookFriendsArray=[NSArray arrayWithArray:facebookFriendsArray];
                        }


                        
                    }
                    
                    
                    
                }
            }
        }
        
    }
}

- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetProfileMutualFriends)
    {
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
    }
    
    NSString *message = NSLocalizedString (@"Unable to initiate request.",
                                           @"NSURLConnection initialization method failed.");
    BeagleAlertWithMessage(message);
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallGetProfileMutualFriends)
    {
        _friendsManager.delegate = nil;
        [_friendsManager releaseServerManager];
        _friendsManager = nil;
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
