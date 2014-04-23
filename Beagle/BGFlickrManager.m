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
    
    self.currentSearchType = fullSearch;
    self.isRunning = false;
    self.found = false;
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary {
    
    // Processing post a photo search API request
    if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoSearch) {
        
        self.flickrRequestInfo = [[FlickrRequestInfo alloc] init];
        
        NSArray *photos = [inResponseDictionary valueForKeyPath:@"photos.photo"];
                
        int numberOfPhotos = (int)[photos count] - 1;
        
        // Did we get any photos back?
        if(numberOfPhotos >=0) {
            
            dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
            dispatch_queue_t main = dispatch_get_main_queue();
            
            dispatch_async(queue, ^{
                
                for (int itr=0; !self.found && itr < numberOfPhotos; itr++)
                {
                    int randomPhotoIndex = [BeagleUtilities getRandomIntBetweenLow:0 andHigh:numberOfPhotos];
                    NSDictionary *photoDict = [photos objectAtIndex:randomPhotoIndex];

                    NSURL *photoURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrMedium640Size];
                    NSLog(@"photoUrl=%@",photoURL);
                    
                    self.flickrRequestInfo.userPhotoWebPageURL = [self.flickrContext photoWebPageURLFromDictionary:photoDict];
                    self.flickrRequestInfo.photo = [UIImage imageWithData:UIImageJPEGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]], 1)];
                    
                    // Scale the image appropriately
                    self.flickrRequestInfo.photo=[UIImage imageWithCGImage:[self.flickrRequestInfo.photo CGImage] scale:2.0 orientation:UIImageOrientationUp];
                    
                    // You've got the image of the right dimensions
                    if (self.flickrRequestInfo.photo.size.width == 320 && self.flickrRequestInfo.photo.size.width > self.flickrRequestInfo.photo.size.height)
                        self.found = true;
                    
                    // Setting the image correctly if it's found
                    if(self.found) {
                        float height=self.flickrRequestInfo.photo.size.height-167.0;
                        if(height>0) {
                            UIImage *locationImage=[BeagleUtilities imageByCropping:self.flickrRequestInfo.photo toRect:CGRectMake(0, height/2, 320, 167) withOrientation:UIImageOrientationDownMirrored];
                            self.flickrRequestInfo.photo=locationImage;
                        }
                        // return back to the main thread with the new image
                        dispatch_async(main, ^{
                            self.completionBlock(self.flickrRequestInfo, nil);
                            [self cleanUpFlickrManager];
                        });
                    }
                }
            
                // If no landscape images were found then let's try again with a different search
                if (!self.found) {
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
            }); // end the async block
        }

        // If no images were returned at all
        else {
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
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError {
    self.completionBlock(nil, inError);
    [self cleanUpFlickrManager];
}

@end
