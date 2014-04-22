//
//  Constants.h
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#define OBJECTIVE_FLICKR_API_KEY @"5cb1600f86fd1f249ca2f1936e5e9e34"
#define OBJECTIVE_FLICKR_API_SHARED_SECRET @"6523fc3819c667e3"

#define WeatherUndergroundApiKey @"5706a66cb7258dd4"

//Location
#define kLocationInvalidateCacheTimeoutDurationInSeconds 1800 //30min (60 * 30)
#define kLocationQuitTimeoutDurationInSeconds 10

//Flickr
#define KFlickrSearchLicense @"4,5,6,7"
#define KFlickrSearchRadiusInMiles @"20"
#define kFlickrSearchInvalidateCacheTimeoutDurationInSeconds 900 //15min (60 * 15)
#define kFlickrSearchQuitTimeoutDurationInSeconds 3600

//Async Queue Label
#define kAsyncQueueLabel "org.tempuri"


#define errorAlertTitle @"Error"
#define errorLimitedConnectivityMessage @"Limited internet connectivity"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define kTimerIntervalInSeconds 10

#define kParticipantInActivity 12