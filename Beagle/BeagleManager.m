//
//  BeagleManager.m
//  Beagle
//
//  Created by Kanav Gupta on 20/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


#import "BeagleManager.h"
#import "FacebookLoginSession.h"
@interface BeagleManager ()<ServerManagerDelegate,FacebookLoginSessionDelegate>{
    ServerManager *signInServerManager;
    NSMutableData *_data;
}
@property(nonatomic,strong)ServerManager *signInServerManager;
@end

@implementation BeagleManager
@synthesize beaglePlayer,currentLocation,placemark,weatherCondition,timeOfDay,photoId,activityCreated,activityDeleted,badgeCount;
@synthesize signInServerManager=_signInServerManager;
+ (id) SharedInstance {
	static id sharedManager = nil;
	
    if (sharedManager == nil) {
        sharedManager = [[self alloc] init];
    }
	
    return sharedManager;
}
-(id)init{
    
    if(self=[super init]){
        
    }
    return self;
}
-(void)autoSign{
    
    FacebookLoginSession *facebookSession=[[FacebookLoginSession alloc]init];
    facebookSession.delegate=self;
    [facebookSession getUserNativeFacebookSession];


}

#pragma mark -
#pragma mark Delegate method From FacebookSession

-(void)successfulFacebookLogin:(BeagleUserClass*)data{
    
    if(_signInServerManager!=nil){
        _signInServerManager.delegate = nil;
        [_signInServerManager releaseServerManager];
        _signInServerManager = nil;
    }
    _signInServerManager=[[ServerManager alloc]init];
    _signInServerManager.delegate=self;
    [_signInServerManager registerPlayerOnBeagle:data];
    
}
-(void)facebookAccountNotSetup{
    
}

-(void)userProfileDataUpdate{
    

        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"User.plist"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"User" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
    
        
        NSMutableDictionary *array = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        
        if (nil == array) {
            array = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
    
        //here add elements to data file and write data to file
    
        if(self.beaglePlayer.access_token != nil && [self.beaglePlayer.access_token class] != [NSNull class])
        [array setObject:self.beaglePlayer.access_token forKey:@"access_token"];
    
    
    [array setObject:[NSNumber numberWithInteger:self.beaglePlayer.beagleUserId] forKey:@"id"];
    [array setObject:[NSNumber numberWithBool:self.beaglePlayer.fb_ticker] forKey:@"facebook_ticker"];
    if(self.beaglePlayer.email != nil && [self.beaglePlayer.email class] != [NSNull class])
          [array setObject:self.beaglePlayer.email forKey:@"email"];
    [array setObject:[NSNumber numberWithInteger:self.beaglePlayer.fbuid ]forKey:@"fbuid"];
    
    if(self.beaglePlayer.first_name != nil && [self.beaglePlayer.first_name class] != [NSNull class])
        [array setObject:self.beaglePlayer.first_name forKey:@"first_name"];
    
    if(self.beaglePlayer.last_name != nil && [self.beaglePlayer.last_name class] != [NSNull class])
     [array setObject:self.beaglePlayer.last_name forKey:@"last_name"];
    if(self.beaglePlayer.profileImageUrl != nil && [self.beaglePlayer.profileImageUrl class] != [NSNull class])
    [array setObject:self.beaglePlayer.profileImageUrl forKey:@"photo_url"];
    
    if(self.beaglePlayer.profileData != nil && [self.beaglePlayer.profileData class] != [NSNull class])
        [array setObject:self.beaglePlayer.profileData forKey:@"photoData"];


    
       [array writeToFile:path atomically:YES];
        
        
        
        
        

}
-(void)getUserObjectInAutoSignInMode{
    
#if 1
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"User.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: path])
    {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"User" ofType:@"plist"];
        
        [fileManager copyItemAtPath:bundle toPath: path error:&error];
    }
    
    
    NSDictionary *array = [NSDictionary dictionaryWithContentsOfFile:path];
    
    
    BeagleUserClass *player=[[BeagleUserClass alloc]init];
    player.access_token=[array valueForKey:@"access_token"];
    player.email=[array valueForKey:@"email"];
    player.fbuid=[[array valueForKey:@"fbuid"]integerValue];
    player.first_name=[array valueForKey:@"first_name"];
    player.last_name=[array valueForKey:@"last_name"];
    player.beagleUserId=[[array valueForKey:@"id"]integerValue];
    player.profileImageUrl=[array valueForKey:@"photo_url"];
    player.profileData=[array valueForKey:@"photoData"];
    player.fb_ticker=[[array valueForKey:@"facebook_ticker"]boolValue];
    self.beaglePlayer=player;
    
    [self autoSign];
#endif
}

- (void)processFacebookProfilePictureData:(NSData *)newProfilePictureData {
    self.beaglePlayer.profileData=newProfilePictureData;
//    [self userProfileDataUpdate];
}

#pragma mark - server calls

- (void)serverManagerDidFinishWithResponse:(NSDictionary*)response forRequest:(ServerCallType)serverRequest{
    
    if(serverRequest==kServerCallUserRegisteration){
        
        _signInServerManager.delegate = nil;
        [_signInServerManager releaseServerManager];
        _signInServerManager = nil;
        
        if (response != nil && [response class] != [NSNull class] && ([response count] != 0)) {
            
            id status=[response objectForKey:@"status"];
            if (status != nil && [status class] != [NSNull class] && [status integerValue]==200){
                
                
                
                
                id player=[response objectForKey:@"player"];
                if (player != nil && [player class] != [NSNull class]) {
                    
                    id beagleId=[player objectForKey:@"id"];
                    if (beagleId != nil && [beagleId class] != [NSNull class]) {
//                        [[self beaglePlayer]setBeagleUserId:[beagleId integerValue]];
//                        NSLog(@"beagleId=%ld",(long)[beagleId integerValue]);
                        
                    }
                    
                    
                    
                    NSURL *pictureURL = [NSURL URLWithString:[player objectForKey:@"image_url"]];
                    
                    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                          timeoutInterval:2.0f];
                    // Run network request asynchronously
                    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                    if (!urlConnection) {
                        NSLog(@"Failed to download picture");
                    }
                }
                
                
                
                
                
            }
        }
        
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self processFacebookProfilePictureData:_data];
}
- (void)serverManagerDidFailWithError:(NSError *)error response:(NSDictionary *)response forRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallUserRegisteration)
    {
        _signInServerManager.delegate = nil;
        [_signInServerManager releaseServerManager];
        _signInServerManager = nil;
    }
    
}

- (void)serverManagerDidFailDueToInternetConnectivityForRequest:(ServerCallType)serverRequest
{
    
    if(serverRequest==kServerCallUserRegisteration)
    {
        _signInServerManager.delegate = nil;
        [_signInServerManager releaseServerManager];
        _signInServerManager = nil;
    }
    
}
@end
