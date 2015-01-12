//
//  BGFlickrManager.m
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

// 5cb1600f86fd1f249ca2f1936e5e9e34
//6523fc3819c667e3
//kanav's account


//36e2980516d0e60864cd29c621a09722
//d309eb551f93b364
//harish's account
#import "BGFlickrManager.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+Resize.h"

@implementation FlickrRequestInfo

- (id) init {
	self = [super init];
	
    if (self != nil) {
        self.photo = [[UIImage alloc] init];
    }
    
    return self;
}

@end

@implementation FlickrAPIRequestSessionInfo
@end

@implementation BGFlickrManager
@synthesize photos,attempts;
static BGFlickrManager *sharedManager = nil;

+ (BGFlickrManager *) sharedManager {
    @synchronized (self) {
        if (sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    }
    
    return sharedManager;
}

-(id) init {
	self = [super init];
	
    if (self != nil) {
        self.flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:@"36e2980516d0e60864cd29c621a09722" sharedSecret:@"d309eb551f93b364"];
        
        FlickrAPIRequestSessionInfo *sessionInfo = [FlickrAPIRequestSessionInfo alloc];
        sessionInfo.flickrAPIRequestType = FlickrAPIRequestPhotoSearch;
        
        self.flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
        self.flickrRequest.sessionInfo = sessionInfo;
                
        [self.flickrRequest setDelegate:self];
	}
    
	return self;
}

- (void) randomPhotoRequest: (void (^)(FlickrRequestInfo *, NSError *)) completion {
    if(!self.isRunning) {
        self.isRunning = true;
        self.completionBlock = completion;
        self.currentSearchType = fullSearch;
        self.found = false;
        
        [self performSelector:@selector(stopFlickrManager:) withObject:nil afterDelay:kFlickrSearchQuitTimeoutDurationInSeconds];
        BeagleManager *BG=[BeagleManager SharedInstance];
        
        if (![self.flickrRequest isRunning]) {
            // Get the Flickr placeID for the user's current location
            ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoId;
            NSString *string=[NSString stringWithFormat:@"%@+%2@",[BG.placemark.addressDictionary objectForKey:@"City"],[BG.placemark administrativeArea]];
            [self.flickrRequest callAPIMethodWithGET:@"flickr.places.find" arguments:[NSDictionary dictionaryWithObjectsAndKeys:string, @"query",nil] tag:0];
        }
    }
}

-(void) photoSearch {
    
    BeagleManager *BG=[BeagleManager SharedInstance];
    
    NSString* tags;
    NSString* searchTypePrint = @"Location only";
    
    // Set the tags based on the search type
    if (self.currentSearchType == fullSearch) {
        tags = BG.weatherCondition;
        tags = [tags stringByAppendingString:@","];
        tags = [tags stringByAppendingString:BG.timeOfDay];
        searchTypePrint = @"Full";
    }
    else if (self.currentSearchType == timeLocationOnly) {
        tags = BG.timeOfDay;
        searchTypePrint = @"Time and Location only";
    }
    else
        tags = @"";
    
    // Print the search type
    NSLog(@"Photo search type = %@", searchTypePrint);
    
    // Search for the right photo based on the search
    ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoSearch;
    [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.search" arguments:[NSDictionary dictionaryWithObjectsAndKeys:@"1463451@N25",@"group_id", tags, @"tags", @"all",@"tag_mode", @"photos", @"content_type",[[BeagleManager SharedInstance]photoId], @"place_id",nil] tag:0];
}

- (void) stopFlickrManager:(id) sender {
    NSError *error = [NSError errorWithDomain:@kAsyncQueueLabel code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"FlickrManager timeout. No photos returned.", NSLocalizedDescriptionKey, nil]];
    self.completionBlock(nil, error);
    [self cleanUpFlickrManager];
}

- (void) cleanUpFlickrManager {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopFlickrManager:) object:nil];
    [self.flickrRequest cancel];
    self.isRunning = false;
    self.found = false;
    self.currentSearchType = fullSearch;
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary {
    
    // Processing post a photo search API request
    if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoSearch) {
        
        self.flickrRequestInfo = [[FlickrRequestInfo alloc] init];
        self.attempts=0;
        self.photos = [inResponseDictionary valueForKeyPath:@"photos.photo"];
        int numberOfPhotos = (int)[self.photos count];
        NSLog(@"Number of photos = %d", numberOfPhotos);
        int randomPhotoIndex=0;
        if(numberOfPhotos>0)
             randomPhotoIndex = [BeagleUtilities getRandomIntBetweenLow:0 andHigh:numberOfPhotos-1];
        
        if([self.photos count]>0){
            [self searchForRequiredSpecRandomly:randomPhotoIndex];
        }
         else{
                [self customSearchWithFlickrApi];
         }
        
        }

    // Upon completion of the Flickr API request for a place id
    else if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoId) {
        
        NSDictionary *places = [inResponseDictionary valueForKeyPath:@"places"];
        NSArray *place =  [places valueForKeyPath:@"place"];
        NSDictionary *item=[place objectAtIndex:0];
        BeagleManager *BG=[BeagleManager SharedInstance];
        BG.photoId =[item valueForKeyPath:@"place_id"];
        
        [self photoSearch];
    }
    else if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoOwner) {
        
        NSDictionary *person = [inResponseDictionary valueForKeyPath:@"person"];
        NSString *username =  [person valueForKeyPath:@"username._text"];
        
        NSString *userInfo = @"";
        
        if([username length]) {
            userInfo = [NSString stringWithFormat:@"%@", username];
        }
        
        self.flickrRequestInfo.userInfo = userInfo;
        
        dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
        dispatch_queue_t main = dispatch_get_main_queue();
        
        dispatch_async(queue, ^{
            
            dispatch_async(main, ^{
                self.completionBlock(self.flickrRequestInfo, nil);
                
                [self cleanUpFlickrManager];
            });
        });
    }
}

-(void)searchForRequiredSpecRandomly:(NSInteger)index{
    
    self.attempts++;
    NSDictionary *photoDict = [self.photos objectAtIndex:index];
    
    NSURL *photoURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrLargeSize];
    

        // Process if we got photos back
        NSLog(@"photoUrl=%@",photoURL);
        dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
        dispatch_queue_t main = dispatch_get_main_queue();
        
        dispatch_async(queue, ^{
            
            self.flickrRequestInfo.photo = [UIImage imageWithData:UIImageJPEGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]], 1)];
            
            // Scale the image appropriately
            self.flickrRequestInfo.photo=[UIImage imageWithCGImage:[self.flickrRequestInfo.photo CGImage] scale:2.0 orientation:UIImageOrientationUp];
            
            // You've got the image of the right dimensions
            if (self.flickrRequestInfo.photo.size.width == 512 && self.flickrRequestInfo.photo.size.height >= 320 && self.flickrRequestInfo.photo.size.width > self.flickrRequestInfo.photo.size.height) {
                float height=self.flickrRequestInfo.photo.size.height-320.0;
                if(height>0) {
                    self.found = true;
                    UIImage *locationImage=[BeagleUtilities imageByCropping:self.flickrRequestInfo.photo toRect:CGRectMake(0, height/2, 512, 320) withOrientation:UIImageOrientationDownMirrored];
                    self.flickrRequestInfo.photo=locationImage;
                    self.flickrRequestInfo.userPhotoWebPageURL = [self.flickrContext photoWebPageURLFromDictionary:photoDict];
                    
                }else{
                    self.found = false;
                }
            }else{
                self.found = false;
            }
            
            dispatch_async(main, ^{
                
                if(!self.found && self.attempts!=[self.photos count]){
                    int numberOfPhotos = (int)[self.photos count];
                     [self searchForRequiredSpecRandomly:[BeagleUtilities getRandomIntBetweenLow:0 andHigh:numberOfPhotos-1]];

                }else if(!self.found && self.attempts==[self.photos count]){
                    [self customSearchWithFlickrApi];
                }else if (self.found){
                    

                        NSString *owner = (NSString *)[photoDict objectForKey:@"owner"];
                        self.flickrRequestInfo.userId = owner;
                        
                        if (![self.flickrRequest isRunning]) {
                            ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoOwner;
                            
                            [self.flickrRequest callAPIMethodWithGET:@"flickr.people.getInfo" arguments:[NSDictionary dictionaryWithObjectsAndKeys:self.flickrRequestInfo.userId, @"user_id", nil] tag:0];
                        }
                    
//                    self.completionBlock(self.flickrRequestInfo, nil);
//                    [self cleanUpFlickrManager];
                    
                }
                
            });
        });
}
-(void)customSearchWithFlickrApi{
    if (self.currentSearchType == fullSearch) {
        self.currentSearchType = timeLocationOnly;
        [self photoSearch];
    }
    else if (self.currentSearchType == timeLocationOnly) {
        self.currentSearchType = locationOnly;
        [self photoSearch];
    }
    else {
        NSError *error = [NSError errorWithDomain:@kAsyncQueueLabel code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"FlickrManager did not return any photos.", NSLocalizedDescriptionKey, nil]];
        
        self.completionBlock(nil, error);
        [self cleanUpFlickrManager];

    }

}
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError {
    self.completionBlock(nil, inError);
    [self cleanUpFlickrManager];
}
- (void) defaultStockPhoto: (void (^)(UIImage *)) completion {
    
    
    dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
    dispatch_queue_t main = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        
        NSString *imagePath = [NSString stringWithFormat:@"defaultLocation"];
        dispatch_async(main, ^{
            completion([UIImage imageNamed:imagePath]);
        });
    });
}

@end
