//
//  ServerManager.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ServerManager.h"
#import "Reachability.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SBJSON.h"
#import "JSON.h"
#import "BeagleActivityClass.h"
#define localHost @"http://192.168.0.102:3000/"
#define localHost1 @"http://localhost:3000/"
#define herokuHost @"http://infinite-spire-6520.herokuapp.com/"
@interface ServerManager()
{
    NSMutableDictionary *_errorCodes;
    ServerCallType _serverCallType;
    Reachability *_internetReachability;
    NSString *_serverUrl;
    NSString *_authkey;
    ASIFormDataRequest *request;
}
@property(nonatomic,retain)Reachability *_internetReachability;
@end

@implementation ServerManager
@synthesize _internetReachability;

-(id)init
{
    self = [super init];
    
    if (self) {
        
        _internetReachability = [Reachability reachabilityForInternetConnection];


        _serverUrl =localHost;

        [self populateErrorCodes];
    }
    return self;
}
-(void)releaseServerManager
{
    [request cancel];
    request.delegate = nil;
    request = nil;
    _serverUrl = nil;
}


-(void)registerPlayerOnBeagle:(BeagleUserClass*)data{
    _serverCallType=kServerCallUserRegisteration;
    if([self isInternetAvailable]){
        
        
        NSMutableDictionary* playerRegisteration =[[NSMutableDictionary alloc] init];
        [playerRegisteration setObject:data.first_name forKey:@"first_name"];
        [playerRegisteration setObject:data.last_name forKey:@"last_name"];
        [playerRegisteration setObject:data.email forKey:@"email"];
        [playerRegisteration setObject:data.profileImageUrl forKey:@"image_url"];
        [playerRegisteration setObject:[NSNumber numberWithInteger:data.fbuid] forKey:@"fbuid"];
        [playerRegisteration setObject:data.access_token forKey:@"access_token"];
        [playerRegisteration setObject:data.location forKey:@"location"];
        if([[[NSUserDefaults standardUserDefaults]valueForKey:@"device_token"]length]!=0)
            [playerRegisteration setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"device_token"] forKey:@"device_token"];
        [playerRegisteration setObject:[NSNumber numberWithBool:data.fb_ticker] forKey:@"fb_ticker"];
        
        
        
        
        NSString *post =[NSString stringWithFormat:@"{\"player\":%@}",[playerRegisteration JSONRepresentation]];
        
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        

        [self callServerWithUrl:[NSString stringWithFormat:@"%@players.json", _serverUrl]
                         method:@"POST"
                         params:nil data:postData];
    }
    else{
        [self internetNotAvailable];
    }
    
    
    
}

-(void)createActivityOnBeagle:(BeagleActivityClass*)data{
    _serverCallType=kServerCallCreateActivity;
    if([self isInternetAvailable]){
        
        
        NSMutableDictionary* activityEvent =[[NSMutableDictionary alloc] init];
        [activityEvent setObject:[NSNumber numberWithInteger:1] forKey:@"atype"];
        [activityEvent setObject:data.startActivityDate forKey:@"start_when"];
        [activityEvent setObject:[NSNumber numberWithFloat:data.latitude] forKey:@"where_lat"];
        [activityEvent setObject:[NSNumber numberWithFloat:data.longitude] forKey:@"where_lng"];
        [activityEvent setObject:data.city forKey:@"where_city"];
        [activityEvent setObject:data.state  forKey:@"where_state"];
        [activityEvent setObject:data.activityDesc forKey:@"what"];
        [activityEvent setObject:data.visibility forKey:@"access"];
        [activityEvent setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"ownnerid"];
        [activityEvent setObject:data.endActivityDate  forKey:@"stop_when"];
        
        
        
        
        NSData *postData = [[activityEvent JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"%@activities.json", _serverUrl]
                         method:@"POST"
                         params:nil data:postData];
    }
    else{
        [self internetNotAvailable];
    }
    
    
    
}


-(void)getActivities{
    _serverCallType = kServerCallGetActivities;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"%@getactivities.json", _serverUrl]
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"pid",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],@"lat",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude],@"lng",
                                 nil] data:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
}
-(void)getDetailedInterest:(NSInteger)activityId{
    _serverCallType = kServerCallGetDetailedInterest;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"%@getactivity.json", _serverUrl]
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"pid",
                                 [NSNumber numberWithInteger:activityId],@"id",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],@"lat",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude],@"lng",
                                 nil] data:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
}
-(void)removeMembership:(NSInteger)activityId{
    _serverCallType = kServerCallLeaveInterest;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* updateMembership =[[NSMutableDictionary alloc] init];
        [updateMembership setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"pid"];
        [updateMembership setObject:[NSNumber numberWithInteger:activityId] forKey:@"id"];
        [updateMembership setObject:@"true" forKey:@"pstatus"];
        
        NSData *postData = [[updateMembership JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"%@leaveactivity.json", _serverUrl]
                         method:@"POST"
                         params:nil data:postData];

    }
    else
    {
        [self internetNotAvailable];
    }
}
-(void)participateMembership:(NSInteger)activityId{
    _serverCallType = kServerCallParticipateInterest;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* updateMembership =[[NSMutableDictionary alloc] init];
        [updateMembership setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"pid"];
        [updateMembership setObject:[NSNumber numberWithInteger:activityId] forKey:@"id"];
        [updateMembership setObject:@"true" forKey:@"pstatus"];
        
        NSData *postData = [[updateMembership JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"%@joinactivity.json", _serverUrl]
                         method:@"PUT"
                         params:nil data:postData];
        
    }
    else
    {
        [self internetNotAvailable];
    }
}

-(void)postAComment:(NSInteger)activityId desc:(NSString*)desc{
    _serverCallType = kServerCallPostComment;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* postComment =[[NSMutableDictionary alloc] init];
        [postComment setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"player_id"];
        [postComment setObject:[NSNumber numberWithInteger:activityId] forKey:@"activity_id"];
        [postComment setObject:desc forKey:@"description"];
        
        NSData *postData = [[postComment JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"%@activity_chats.json", _serverUrl]
                         method:@"POST"
                         params:nil data:postData];
        
    }
    else
    {
        [self internetNotAvailable];
    }
}

-(void)deleteAnInterest:(NSInteger)activityId{
    _serverCallType = kServerCallDeleteActivity;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"%@activities/%ld.json", _serverUrl,(long)activityId]
                         method:@"DELETE"
                         params:nil data:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
}
-(void)updateActivityOnBeagle:(BeagleActivityClass*)data{
    _serverCallType=kServerCallEditActivity;
    if([self isInternetAvailable]){
        
        
        NSMutableDictionary* activityEvent =[[NSMutableDictionary alloc] init];
        [activityEvent setObject:[NSNumber numberWithInteger:1] forKey:@"atype"];
        [activityEvent setObject:data.startActivityDate forKey:@"start_when"];
        [activityEvent setObject:[NSNumber numberWithFloat:data.latitude] forKey:@"where_lat"];
        [activityEvent setObject:[NSNumber numberWithFloat:data.longitude] forKey:@"where_lng"];
        [activityEvent setObject:data.city forKey:@"where_city"];
        [activityEvent setObject:data.state  forKey:@"where_state"];
        [activityEvent setObject:data.activityDesc forKey:@"what"];
        [activityEvent setObject:data.visibility forKey:@"access"];
        [activityEvent setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"ownnerid"];
        [activityEvent setObject:data.endActivityDate  forKey:@"stop_when"];
        
        
        
        
        NSData *postData = [[activityEvent JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"%@activities/%ld.json", _serverUrl,(long)data.activityId]
                         method:@"PUT"
                         params:nil data:postData];
    }
    else{
        [self internetNotAvailable];
    }
    
    
    
}

-(void)updateFacebookTickerStatus:(BOOL)status{
    _serverCallType = kServerCallUpdateFbTicker;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* updateStatus =[[NSMutableDictionary alloc] init];
        [updateStatus setObject:[NSNumber numberWithBool:status] forKey:@"fb_ticker"];
        
        NSData *postData = [[updateStatus JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"%@/players/%ld.json", _serverUrl,(long)[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]]
                         method:@"PUT"
                         params:nil data:postData];
        
    }
    else
    {
        [self internetNotAvailable];
    }
}

-(void)getNotifications{
    _serverCallType=kServerCallGetNotifications;
    
        if([self isInternetAvailable])
        {
            [self callServerWithUrl:[NSString stringWithFormat:@"%@mynotifications.json", _serverUrl]
                             method:@"GET"
                             params:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"logged_in_user_id",
                                     nil] data:nil];
        }
        else
        {
            [self internetNotAvailable];
        }
}
-(void)populateErrorCodes
{
    _errorCodes = [[NSMutableDictionary alloc]init];
    [_errorCodes setValue:@"OK" forKey:@"200"];
    [_errorCodes setValue:@"Bad Request" forKey:@"400"];
    [_errorCodes setValue:@"Unauthorized" forKey:@"401"];
    [_errorCodes setValue:@"Forbidden" forKey:@"403"];
    [_errorCodes setValue:@"Not Found" forKey:@"404"];
    [_errorCodes setValue:@"Internal Server Error" forKey:@"500"];
    [_errorCodes setValue:@"Not Implemented" forKey:@"501"];
}


#pragma mark - Response and Error Methods

- (void)requestFinished:(ASIHTTPRequest *)requestASI
{
    // Use when fetching text data
    NSString *responseString = [requestASI responseString];
    
    SBJSON *parser = [[SBJSON alloc] init];
    NSDictionary *responseInformation = (NSDictionary*)[parser objectWithString:responseString];
    
    NSError *error = nil;
    if (requestASI.responseStatusCode != 200)
    {
        error = [NSError errorWithDomain:@"ServerManager"
                                    code:requestASI.responseStatusCode
                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"%d",[requestASI responseStatusCode]], NSLocalizedFailureReasonErrorKey,
                                          responseString, NSLocalizedDescriptionKey,
                                          nil]];
    }
    if (error)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(serverManagerDidFailWithError:response:forRequest:)])
        {
            [_delegate serverManagerDidFailWithError:error response:responseInformation forRequest:_serverCallType];
        }
    }
    else if (_delegate && [_delegate respondsToSelector:@selector(serverManagerDidFinishWithResponse:forRequest:)])
    {
        [_delegate serverManagerDidFinishWithResponse:responseInformation forRequest:_serverCallType];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)requestASI
{
    NSString *errorCode = [_errorCodes valueForKey:[NSString stringWithFormat:@"%d",[requestASI responseStatusCode]]];
    
    NSError *requestError = [NSError errorWithDomain:@"ServerManager"
                                                code:requestASI.responseStatusCode
                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSString stringWithFormat:@"%d",[requestASI responseStatusCode]], NSLocalizedFailureReasonErrorKey,
                                                      errorCode, NSLocalizedDescriptionKey,
                                                      nil]];
    
    if (_delegate && [_delegate respondsToSelector:@selector(serverManagerDidFailWithError:response:forRequest:)])
    {
        [_delegate serverManagerDidFailWithError:requestError response:nil forRequest:_serverCallType];
    }
}


#pragma mark - Private

- (void)callServerWithUrl:(NSString *)requestUrl method:(NSString *)requestMethod params:(NSDictionary *)params data:(NSData*)data
{
    request = nil;
    if (([requestMethod isEqualToString:@"GET"] || [requestMethod isEqualToString:@"DELETE"]) && params.allKeys.count > 0)
    {
        NSString *getUrl = [NSString stringWithFormat:@"%@?", requestUrl];
        NSArray *keys = [params allKeys];
        for (int index = 0; index < keys.count; index++)
        {
            NSString *nextKey = [keys objectAtIndex:index];
            NSString *value = [params valueForKey:nextKey];
            
            getUrl = [NSString stringWithFormat:@"%@%@=%@", getUrl, nextKey, value];
            
            if (index < keys.count - 1)
            {
                getUrl = [NSString stringWithFormat:@"%@&", getUrl];
            }
        }
        request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[getUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }
    else
    {
        request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestUrl]];
        [request setPostBody:[NSMutableData dataWithData:data]];
     }
    
    

    // set headers valid for all requests
    [request setRequestMethod:requestMethod];

    [request setDelegate:self];
    [request addRequestHeader:@"content-type" value:@"application/json"];
    
    request.allowCompressedResponse = NO;
    request.useCookiePersistence = NO;
    request.shouldCompressRequestBody = NO;
    [request startAsynchronous];
}


-(BOOL)isInternetAvailable{
    return ([self updateInterfaceWithReachability:_internetReachability]);
}

-(BOOL) updateInterfaceWithReachability: (Reachability*) curReach
{
	NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus)
    {
        case NotReachable:
			return NO;
        case ReachableViaWWAN:
			return YES;
        case ReachableViaWiFi:
            return YES;
    }
	return NO;
}

-(void)internetNotAvailable
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(serverManagerDidFailDueToInternetConnectivityForRequest:)])
    {
        [self.delegate serverManagerDidFailDueToInternetConnectivityForRequest:_serverCallType];
    }
}


@end
