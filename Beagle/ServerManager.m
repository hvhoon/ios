//
//  ServerManager.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ServerManager.h"
#import "Reachability.h"
#import "InterestChatClass.h"
@interface ServerManager()
{
    ServerCallType _serverCallType;
    Reachability *_internetReachability;
}
@property(nonatomic,retain)Reachability *_internetReachability;
@end

@implementation ServerManager
@synthesize _internetReachability;

+ (ServerManager *)sharedServerManagerClient{
    static ServerManager *_sharedServerManagerHTTPClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedServerManagerHTTPClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:herokuHost]];
    });
    
    return _sharedServerManagerHTTPClient;
}
- (instancetype)initWithBaseURL:(NSURL *)url{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        _internetReachability = [Reachability reachabilityForInternetConnection];

    }
    
    return self;
    
}

-(void)registerPlayerOnBeagle:(BeagleUserClass*)data{
    _serverCallType=kServerCallUserRegisteration;
    if([self isInternetAvailable]){
        NSMutableDictionary* playerRegisteration =[[NSMutableDictionary alloc] init];
        [playerRegisteration setObject:data.first_name forKey:@"first_name"];
        [playerRegisteration setObject:data.last_name forKey:@"last_name"];
        [playerRegisteration setObject:data.email forKey:@"email"];
        [playerRegisteration setObject:data.profileImageUrl forKey:@"image_url"];
        [playerRegisteration setObject:data.fbuid forKey:@"fbuid"];
        [playerRegisteration setObject:data.access_token forKey:@"access_token"];
            if([data.location length]!=0)
            [playerRegisteration setObject:data.location forKey:@"location"];
        if([[[NSUserDefaults standardUserDefaults]valueForKey:@"device_token"]length]!=0)
            [playerRegisteration setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"device_token"] forKey:@"device_token"];
        [playerRegisteration setObject:[NSNumber numberWithBool:data.fb_ticker] forKey:@"fb_ticker"];
        
        NSMutableDictionary *registerParams=[NSMutableDictionary new];
        [registerParams setObject:playerRegisteration forKey:@"player"];
        
        [self callServerWithUrl:@"players.json"
                         method:@"POST"
                         params:registerParams];
     }
    else{
        [self internetNotAvailable];
    }
    
    
    
}

-(void)createActivityOnBeagle:(BeagleActivityClass*)data{
    _serverCallType=kServerCallCreateActivity;
    if([self isInternetAvailable]){
        
        NSMutableDictionary* activityEvent =[[NSMutableDictionary alloc] init];
        [activityEvent setObject:[NSNumber numberWithInteger:data.activityType] forKey:@"atype"];
        [activityEvent setObject:data.startActivityDate forKey:@"start_when"];
        [activityEvent setObject:[NSNumber numberWithFloat:data.latitude] forKey:@"where_lat"];
        [activityEvent setObject:[NSNumber numberWithFloat:data.longitude] forKey:@"where_lng"];
        [activityEvent setObject:data.city forKey:@"where_city"];
        [activityEvent setObject:data.state  forKey:@"where_state"];
        data.activityDesc = [[data.activityDesc componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];

        [activityEvent setObject:data.activityDesc forKey:@"what"];
        [activityEvent setObject:data.visibility forKey:@"access"];
        [activityEvent setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"ownnerid"];
        [activityEvent setObject:data.endActivityDate  forKey:@"stop_when"];
        NSString *bodyData=nil;
        
        if([data.requestString length]!=0){

      NSString *activityEventData=[NSString stringWithFormat:@"\"atype\":\"%@\",\"start_when\":\"%@\",\"where_lat\":\"%@\",\"where_lng\":\"%@\",\"where_city\":\"%@\",\"where_state\":\"%@\",\"what\":\"%@\",\"access\":\"%@\",\"ownnerid\":\"%@\",\"stop_when\":\"%@\"",[NSNumber numberWithInteger:1],data.startActivityDate,[NSNumber numberWithFloat:data.latitude],[NSNumber numberWithFloat:data.longitude],data.city,data.state,data.activityDesc,data.visibility,[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],data.endActivityDate];
         bodyData = [NSString stringWithFormat:@"{\"invitees\":%@,%@}",data.requestString,activityEventData];
            
        }else{
            NSError* error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:activityEvent options:NSJSONWritingPrettyPrinted error:&error];
            bodyData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        }
        NSData *postData = [bodyData dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSError* error;
        NSDictionary* params = [NSJSONSerialization JSONObjectWithData:postData
                                                             options:kNilOptions
                                                               error:&error];
        
        [self callServerWithUrl:@"activities.json"
                         method:@"POST"
                         params:params];
    }
    else{
        [self internetNotAvailable];
    }
    
    
    
}


-(void)getActivities{
    _serverCallType = kServerCallGetActivities;
    if([self isInternetAvailable])
    {
        
        [self callServerWithUrl:@"getactivities.json"
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"pid",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],@"lat",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude],@"lng",
                                 nil]];

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
        [self callServerWithUrl:@"getactivity.json"
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"pid",
                                 [NSNumber numberWithInteger:activityId],@"id",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],@"lat",
                                 [NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude],@"lng",
                                 nil]];
    }
    else
    {
        [self internetNotAvailable];
    }
}
-(void)removeMembership:(NSInteger)activityId playerid:(NSInteger)playerId{
    _serverCallType = kServerCallLeaveInterest;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* updateMembership =[[NSMutableDictionary alloc] init];
        [updateMembership setObject:[NSNumber numberWithInteger:playerId] forKey:@"pid"];
        [updateMembership setObject:[NSNumber numberWithInteger:activityId] forKey:@"id"];
        [updateMembership setObject:@"true" forKey:@"pstatus"];
        
        [self callServerWithUrl:@"leaveactivity.json"
                         method:@"POST"
                         params:updateMembership];

    }
    else
    {
        [self internetNotAvailable];
    }
}
-(void)participateMembership:(NSInteger)activityId playerid:(NSInteger)playerId{
    _serverCallType = kServerCallParticipateInterest;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* updateMembership =[[NSMutableDictionary alloc] init];
        [updateMembership setObject:[NSNumber numberWithInteger:playerId] forKey:@"pid"];
        [updateMembership setObject:[NSNumber numberWithInteger:activityId] forKey:@"id"];
        [updateMembership setObject:@"true" forKey:@"pstatus"];
        [self callServerWithUrl:@"joinactivity.json"
                         method:@"PUT"
                         params:updateMembership];
        
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
        [self callServerWithUrl:@"activity_chats.json"
                         method:@"POST"
                         params:postComment];
        
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
        [self callServerWithUrl:[NSString stringWithFormat:@"activities/%ld.json",(long)activityId]
                         method:@"DELETE"
                         params:nil];
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
        data.activityDesc = [[data.activityDesc componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];

        [activityEvent setObject:data.activityDesc forKey:@"what"];
        [activityEvent setObject:data.visibility forKey:@"access"];
        [activityEvent setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"ownnerid"];
        [activityEvent setObject:data.endActivityDate  forKey:@"stop_when"];
        
        
        [self callServerWithUrl:[NSString stringWithFormat:@"activities/%ld.json",(long)data.activityId]
                         method:@"PUT"
                         params:activityEvent];
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
        [self callServerWithUrl:[NSString stringWithFormat:@"/players/%ld.json",(long)[[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]integerValue]]
                         method:@"PUT"
                         params:updateStatus];
        
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
            [self callServerWithUrl:@"mynotifications.json"
                             method:@"GET"
                             params:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"logged_in_user_id",
                                     nil]];
        }
        else
        {
            [self internetNotAvailable];
        }
}


-(void)requestInAppNotificationForPosts:(NSInteger)chatId notifType:(NSInteger)notifType{
    if(notifType==1)
    _serverCallType=kServerCallInAppNotificationForPosts;
    else if(notifType==2)
        _serverCallType=kServerCallInAppForOfflinePost;
    
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"activity_chats/%ld/acparameter.json",(long)chatId]
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
    }
    else
    {
        [self internetNotAvailable];
    }
    
}
-(void)requestInAppNotification:(NSInteger)notificationId notifType:(NSInteger)notifType{


    if(notifType==1)
        _serverCallType=kServerCallInAppNotification;
    else if(notifType==2)
        _serverCallType=kServerCallRequestForOfflineNotification;
    else if(notifType==3)
        _serverCallType=kServerCallRequestForSilentNotification;


    
    if([self isInternetAvailable])
    {
        if(notifType==3){
        [self callServerWithUrl:@"silentpushparameter.json"
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInteger:notificationId],@"id",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],@"pid",
                                 nil]];
        }else{
            [self callServerWithUrl:@"rsparameter.json"
                             method:@"GET"
                             params:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInteger:notificationId],@"id",
                                     nil]];
        }
    }
    else
    {
        [self internetNotAvailable];
    }
}




-(void)getMoreBackgroundPostsForAnInterest:(InterestChatClass*)lastChatPost activId:(NSInteger)activId{
    _serverCallType=kServerCallGetBackgroundChats;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    
    NSDate *lastDate = [dateFormatter dateFromString:lastChatPost.timestamp];
    NSDate *updatedDate=[lastDate dateByAddingTimeInterval:5];
    NSLog(@"updatedDate=%@",updatedDate);
    


    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"activity_chats/backgroundchat.json?pid=%@&aid=%ld&chatid=%ld&start_time=%@&end_time=%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],(long)activId,(long)lastChatPost.chat_id,[dateFormatter stringFromDate:updatedDate],[dateFormatter stringFromDate:[NSDate date]]]
                         method:@"GET"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
    
}

-(void)getNewBackgroundPostsForAnInterest:(NSInteger)activityId{
        _serverCallType=kServerCallGetBackgroundChats;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];

    if([self isInternetAvailable]) {
        [self callServerWithUrl:[NSString stringWithFormat:@"activity_chats/testbackgroundchat.json?pid=%@&aid=%ld",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],(long)activityId]
                         method:@"GET"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }

}

-(void)getPostDetail:(NSInteger)chatId{
    _serverCallType=kServerInAppChatDetail;
    
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"activity_chats/%ld/chat_detail.json?pid=%@",(long)chatId,[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"]]
                         method:@"GET"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
    
}

-(void)getMutualFriendsNetwork:(NSInteger)friendId{
    _serverCallType=kServerCallGetProfileMutualFriends;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"players/friendprofile.json?id=%@&fid=%ld&lat=%@&lng=%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],(long)friendId,[NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],[NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude]]
                         method:@"GET"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }

}
-(void)getDOS1Friends{
    _serverCallType=kServerCallGetDOS1Friends;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"players/friendwithdos1.json?id=%@&lat=%@&lng=%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],[NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],[NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude]]
                         method:@"GET"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
    
}

-(void)sendingAPostMessageOnFacebook:(NSNumber*)fbuid{
    _serverCallType=kServerPostAPrivateMessageOnFacebook;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"players/send_facebook_message.json?id=%@&fbuid=%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],fbuid]
                         method:@"POST"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }

}
-(void)getNearbyAndWorldWideFriends{
    _serverCallType=kServerCallgetNearbyAndWorldWideFriends;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"players/friendwithdos1NearbyAndWorldwide.json?id=%@&lat=%@&lng=%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],[NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.latitude],[NSNumber numberWithFloat:[[BeagleManager SharedInstance]currentLocation].coordinate.longitude]]
                         method:@"GET"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
    
}
-(void)updateSuggestedPostMembership:(NSInteger)activityId{
        _serverCallType=kServerCallSuggestedPostMembership;
    if([self isInternetAvailable])
    {
        
        NSMutableDictionary* updateMembership =[[NSMutableDictionary alloc] init];
        [updateMembership setObject:[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"] forKey:@"pid"];
        [updateMembership setObject:[NSNumber numberWithInteger:activityId] forKey:@"id"];
        [updateMembership setObject:@"true" forKey:@"pstatus"];
        
        [self callServerWithUrl:@"suggestedactivity.json"
                         method:@"PUT"
                         params:updateMembership];
        
    }
    else
    {
        [self internetNotAvailable];
    }

}

-(void)userInfoOnBeagle:(NSString*)email{
    _serverCallType=kServerGetSignInInfo;
    if([self isInternetAvailable])
    {
        
        [self callServerWithUrl:@"signininfo.json"
                         method:@"GET"
                         params:[NSDictionary dictionaryWithObjectsAndKeys:
                                 email,@"email",
                                 nil]];
    }
    else
    {
        [self internetNotAvailable];
    }

}

-(void)sendingAnEmailInvite:(NSNumber*)fbuid{
    _serverCallType=kServerPostAnEmailInvite;
    if([self isInternetAvailable])
    {
        [self callServerWithUrl:[NSString stringWithFormat:@"players/send_email_invite.json?id=%@&fbuid=%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"beagleId"],fbuid]
                         method:@"POST"
                         params:nil];
    }
    else
    {
        [self internetNotAvailable];
    }
    
}
#pragma mark - Response and Error Methods





#pragma mark - Private
-(void)callServerWithUrl:(NSString *)requestUrl method:(NSString *)requestMethod params:(NSDictionary *)params{
    
    if ([requestMethod isEqualToString:@"GET"]){
    [self GET:requestUrl parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        if ([self.delegate respondsToSelector:@selector(serverManagerDidFinishWithResponse:forRequest:)]) {
            [self.delegate serverManagerDidFinishWithResponse:responseObject forRequest:_serverCallType];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(serverManagerDidFailWithError:response:forRequest:)]) {
            [self.delegate serverManagerDidFailWithError:error response:nil forRequest:_serverCallType];
        }
    }];
    }else if ([requestMethod isEqualToString:@"POST"]){
        [self POST:requestUrl parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
            if ([self.delegate respondsToSelector:@selector(serverManagerDidFinishWithResponse:forRequest:)]) {
                [self.delegate serverManagerDidFinishWithResponse:responseObject forRequest:_serverCallType];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if ([self.delegate respondsToSelector:@selector(serverManagerDidFailWithError:response:forRequest:)]) {
                [self.delegate serverManagerDidFailWithError:error response:nil forRequest:_serverCallType];
            }
        }];
    }
    else if ([requestMethod isEqualToString:@"PUT"]){
        [self PUT:requestUrl parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
            if ([self.delegate respondsToSelector:@selector(serverManagerDidFinishWithResponse:forRequest:)]) {
                [self.delegate serverManagerDidFinishWithResponse:responseObject forRequest:_serverCallType];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if ([self.delegate respondsToSelector:@selector(serverManagerDidFailWithError:response:forRequest:)]) {
                [self.delegate serverManagerDidFailWithError:error response:nil forRequest:_serverCallType];
            }
        }];
    }
    else if ([requestMethod isEqualToString:@"DELETE"]){
        [self DELETE:requestUrl parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
            if ([self.delegate respondsToSelector:@selector(serverManagerDidFinishWithResponse:forRequest:)]) {
                [self.delegate serverManagerDidFinishWithResponse:responseObject forRequest:_serverCallType];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if ([self.delegate respondsToSelector:@selector(serverManagerDidFailWithError:response:forRequest:)]) {
                [self.delegate serverManagerDidFailWithError:error response:nil forRequest:_serverCallType];
            }
        }];
    }
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
