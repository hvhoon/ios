//
//  Constants.h
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#define OBJECTIVE_FLICKR_API_KEY @"5cb1600f86fd1f249ca2f1936e5e9e34"
#define OBJECTIVE_FLICKR_API_SHARED_SECRET @"6523fc3819c667e3"

#define openWeatherAPIKey @"a349ae9dd144770e6573c89b2350e8ac"

//Location
#define kLocationInvalidateCacheTimeoutDurationInSeconds 1800 //30min (60 * 30)
#define kLocationQuitTimeoutDurationInSeconds 10

//Flickr
#define KFlickrSearchLicense @"4,5,6,7"
#define KFlickrSearchRadiusInMiles @"20"
#define kFlickrSearchInvalidateCacheTimeoutDurationInSeconds 900 //15min (60 * 15)
#define kFlickrSearchQuitTimeoutDurationInSeconds 15

//Async Queue Label
#define kAsyncQueueLabel "org.tempuri"
#define kPostInterface 1
#define kHeightClip 3
#define kPostTextClip 3
#define errorAlertTitle @"You're off the grid"
#define errorLimitedConnectivityMessage @"So this is what the 80's felt like.  Please try again when you return to this decade."

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define kTimerIntervalInSeconds 10

#define kParticipantInActivity 12
#define kInterestChat 13
#define kNotificationRecord 14
#define kFriendRecord 15
#define CANCEL_ACTIVITY_TYPE 9
#define CHAT_TYPE 17
#define WHAT_CHANGE_TYPE 1
#define DATE_CHANGE_TYPE 2
#define JOINED_ACTIVITY_TYPE 6
#define PLAYER_JOINED_BEAGLE 7
#define LEAVED_ACTIVITY_TYPE 8
#define ACTIVITY_CREATION_TYPE 11
#define LIKE_TO_JOIN_TYPE 12
#define GOING_TYPE 13
#define ACTIVITY_UPDATE_TYPE 32
#define SUGGESTED_ACTIVITY_CREATION_TYPE 33
#define SELF_ACTIVITY_CREATION_TYPE 34
#define kBeagleBadgeCount @"BeagleBadgeCount"
#define kUpdatePostsOnInterest @"PostUpdateOnDetailedInterest"
#define kUpdateNotificationStack @"UpdateNotificationStack"
#define kUpdateHomeScreenAndNotificationStack @"UpdateHomeScreenAndNotificationStack"
#define kRemoteNotificationReceivedNotification @"RemoteNotificationReceivedWhileRunning"
#define kErrorToGetLocation @"ErrorLocation"
#define kLocationUpdateReceived  @"LocationSuccess"
#define kNotificationForInterestPost @"InAppInterestPostNotification"
#define kNotificationHomeAutoRefresh @"NotificationHomeAutoRefresh"
#define kFacebookSSOLoginAuthentication @"FacebookSSOLoginAuthentication"
#define kFacebookAuthenticationFailed @"FacebookAuthenticationFailed"
#define kFacebookAddOnPermissionsDenied @"FacebookPermissionsDenied"
#ifdef DEBUG
#define herokuHost @"http://obscure-basin-9504.herokuapp.com/"
//#define herokuHost @"http://localhost:3000/"
#else
#define herokuHost @"http://infinite-spire-6520.herokuapp.com/"
#endif
