//
//  BGFlickrManager.h
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ObjectiveFlickr.h"

@interface FlickrRequestInfo : NSObject

@property(nonatomic, strong) UIImage *photo;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *userInfo;
@property(nonatomic, strong) NSURL *userPhotoWebPageURL;

@end

typedef enum {
    fullSearch,
    timeLocationOnly,
    locationOnly,
} searchType;

@interface BGFlickrManager : NSObject<OFFlickrAPIRequestDelegate>

@property(nonatomic, copy) void (^completionBlock)(FlickrRequestInfo *, NSError *);

@property(nonatomic, assign) bool isRunning;
@property(nonatomic, assign) bool found;
@property(nonatomic, strong) OFFlickrAPIContext *flickrContext;
@property(nonatomic, strong) OFFlickrAPIRequest *flickrRequest;
@property(nonatomic, strong) FlickrRequestInfo *flickrRequestInfo;
@property(nonatomic,strong)NSArray *photos;
@property(nonatomic, strong) NSDate *searchInvalidateCacheTimeout;
@property(nonatomic, strong) NSDate *searchQuitTimeout;
@property(nonatomic, assign) searchType currentSearchType;
@property(nonatomic, assign) NSInteger attempts;
+ (BGFlickrManager *) sharedManager;
- (void) randomPhotoRequest: (void (^)(FlickrRequestInfo *, NSError *)) completion;
- (void) defaultStockPhoto: (void (^)(UIImage *)) completion;
@end

typedef enum {
    FlickrAPIRequestPhotoSearch = 2,
    FlickrAPIRequestPhotoSizes = 3,
    FlickrAPIRequestPhotoOwner = 4,
    FlickrAPIRequestPhotoId=1,
} FlickrAPIRequestType;


@interface FlickrAPIRequestSessionInfo : NSObject

@property(nonatomic, assign) FlickrAPIRequestType flickrAPIRequestType;

@end

