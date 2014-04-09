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
        
        [self performSelector:@selector(stopFlickrManager:) withObject:nil afterDelay:kFlickrSearchQuitTimeoutDurationInSeconds];
        [self photoIdRequest];
    }
}

- (void) photoRequest {
    if (![self.flickrRequest isRunning]) {
        ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoSearch;
        
        BeagleManager *BG=[BeagleManager SharedInstance];
        
        NSString *testString=[NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=36e2980516d0e60864cd29c621a09722&tags=%@&tag_mode=all&content_type=photos&group_id=1463451@N25&place_id=%@&format=json&nojsoncallback=1",BG.weatherCondition,[[BeagleManager SharedInstance]photoId]];
        
         [self.flickrRequest callAPIMethodWithGET2:[NSURL URLWithString:testString]];


//        [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.search" arguments:[NSDictionary dictionaryWithObjectsAndKeys:@"1463451%40N25",@"group_id",BG.weatherCondition, @"tags", @"all",@"tag_mode", @"photos", @"content_type", [[BeagleManager SharedInstance]photoId], @"place_id",nil] tag:1];

        
    }
}
- (void) photoIdRequest {
    if (![self.flickrRequest isRunning]) {
        ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoId;
        
        BeagleManager *BG=[BeagleManager SharedInstance];
        NSString *string=[NSString stringWithFormat:@"%@+%2@",[BG.placemark.addressDictionary objectForKey:@"City"],[BG.placemark administrativeArea]];
        
        [self.flickrRequest callAPIMethodWithGET:@"flickr.places.find" arguments:[NSDictionary dictionaryWithObjectsAndKeys:string, @"query",nil] tag:0];
    }
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
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary {
    if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoSearch) {
    
        self.flickrRequestInfo = [[FlickrRequestInfo alloc] init];
        
        
        NSArray *photos=[[inResponseDictionary objectForKey:@"photos"]objectForKey:@"photo"];
        
        //NSArray *photos = [inResponseDictionary valueForKeyPath:@"photos.photo"];
                
        int numberOfPhotos = (int)[photos count] - 1;
        
        if(numberOfPhotos >=0) {
            
            int randomPhotoIndex = [BeagleUtilities getRandomIntBetweenLow:0 andHigh:numberOfPhotos];
            
            NSDictionary *photoDict = [photos objectAtIndex:randomPhotoIndex];
            NSURL *photoURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrLargeSize];
                        
            NSString *photoId = (NSString *)[photoDict objectForKey:@"id"];
            NSString *owner = (NSString *)[photoDict objectForKey:@"owner"];
            
            self.flickrRequestInfo.userPhotoWebPageURL = [self.flickrContext photoWebPageURLFromDictionary:photoDict];
            
            dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
            dispatch_queue_t main = dispatch_get_main_queue();
            
            dispatch_async(queue, ^{
                
                self.flickrRequestInfo.photo = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]];
                
                dispatch_async(main, ^{

                    self.flickrRequestInfo.userId = owner;
                    
                    if (![self.flickrRequest isRunning]) {
                        ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoSizes;
                        
                        [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.getSizes" arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoId, @"photo_id", nil] tag:1];
                    }
                });
            });
        } else {
            NSError *error = [NSError errorWithDomain:@kAsyncQueueLabel code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"FlickrManager did not return any photos.", NSLocalizedDescriptionKey, nil]];
            
            self.completionBlock(nil, error);
            
            [self cleanUpFlickrManager];
        }

    } else if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoSizes) {
                
        NSDictionary *photoSizes = [inResponseDictionary valueForKeyPath:@"sizes.size"];
        
        bool found = false;
        
        for (NSDictionary *size in photoSizes) {
            if([[NSString stringWithString:(NSString *)[size objectForKey:@"label"]] isEqualToString:@"Medium 640"]) {
                found = true;
                
                dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
                dispatch_queue_t main = dispatch_get_main_queue();
                
                dispatch_async(queue, ^{
                    
                    //[self resizeCropPhoto];
                    
                    dispatch_async(main, ^{
                        self.completionBlock(self.flickrRequestInfo, nil);
                        
                        [self cleanUpFlickrManager];
                    });
                });
            }
        }
        
        if(!found) {
            [self photoRequest];
        }
            
    } else if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoOwner) {

        NSDictionary *person = [inResponseDictionary valueForKeyPath:@"person"];
        NSString *username =  [person valueForKeyPath:@"username._text"];
        
        NSString *userInfo = @"";
        
        if([username length]) {
            userInfo = [NSString stringWithFormat:@"© %@", username];
        }
        
        self.flickrRequestInfo.userInfo = userInfo;
        
        dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
        dispatch_queue_t main = dispatch_get_main_queue();
        
        dispatch_async(queue, ^{
    
            //[self resizeCropPhoto];
                    
            dispatch_async(main, ^{
                self.completionBlock(self.flickrRequestInfo, nil);
                
                [self cleanUpFlickrManager];
            });
        });
    }
    
    else if(((FlickrAPIRequestSessionInfo *)inRequest.sessionInfo).flickrAPIRequestType == FlickrAPIRequestPhotoId) {
        
        NSDictionary *places = [inResponseDictionary valueForKeyPath:@"places"];
        NSArray *place =  [places valueForKeyPath:@"place"];
        NSDictionary *item=[place objectAtIndex:0];
        BeagleManager *BG=[BeagleManager SharedInstance];
        BG.photoId =[item valueForKeyPath:@"place_id"];
        dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
        dispatch_queue_t main = dispatch_get_main_queue();
        
        dispatch_async(queue, ^{
            
            
            dispatch_async(main, ^{
                
                
                
                if (![self.flickrRequest isRunning]) {
                    ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoSearch;
                    BeagleManager *BG=[BeagleManager SharedInstance];
                    
                    NSString *testString=[NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=36e2980516d0e60864cd29c621a09722&tags=%@&tag_mode=all&content_type=photos&group_id=1463451%40N25&place_id=%@&format=json&nojsoncallback=1",BG.weatherCondition,[[BeagleManager SharedInstance]photoId]];
 #if 0
                    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:testString]];
                    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
                    [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                     {
                         if ([data length] > 0 && error == nil){
                             
                             [self performSelectorOnMainThread:@selector(receivedData:) withObject:data waitUntilDone:NO];
                         }else if ([data length] == 0 && error == nil){
                         }else if (error != nil && error.code == NSURLErrorTimedOut){          }else if (error != nil){
                             NSLog(@"Error=%@",[error description]);
                         }
                     }];
                    


                    dispatch_queue_t myQueue = dispatch_queue_create("myQueue", NULL);
                    
                    // execute a task on that queue asynchronously
                    dispatch_async(myQueue, ^{
                        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:testString]];
                        
                        NSURLResponse *res = nil;
                        NSError *err = nil;
                        
                        NSLog(@"About to send req %@",req.URL);
                        
                        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
                         NSString *stringResponse= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSError *error=nil;
                         NSDictionary* inResponseDictionary = [NSJSONSerialization JSONObjectWithData:[stringResponse dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                        
                        
                        
                        
                        
                    });
#endif
                    //[self.flickrRequest callAPIMethodWithGET2:[NSURL URLWithString:testString]];

                    
                    [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.search" arguments:[NSDictionary dictionaryWithObjectsAndKeys:@"1463451%40N25",@"group_id",BG.weatherCondition, @"tags", @"all",@"tag_mode", @"photos", @"content_type",[[BeagleManager SharedInstance]photoId], @"place_id",nil] tag:1];
                }
            });
        });
    }
}

-(void)receivedData:(NSData*)data{
    
    NSString *stringResponse= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error=nil;
    NSDictionary* inResponseDictionary = [NSJSONSerialization JSONObjectWithData:[stringResponse dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

    {
        
        self.flickrRequestInfo = [[FlickrRequestInfo alloc] init];
        
        
        //NSArray *photos=[[inResponseDictionary objectForKey:@"photos"]objectForKey:@"photo"];
        
        NSArray *photos = [inResponseDictionary valueForKeyPath:@"photos.photo"];
        
        int numberOfPhotos = (int)[photos count] - 1;
        
        if(numberOfPhotos >=0) {
            
            int randomPhotoIndex = [BeagleUtilities getRandomIntBetweenLow:0 andHigh:numberOfPhotos];
            
            NSDictionary *photoDict = [photos objectAtIndex:randomPhotoIndex];
            NSURL *photoURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrLargeSize];
            
            NSString *photoId = (NSString *)[photoDict objectForKey:@"id"];
            NSString *owner = (NSString *)[photoDict objectForKey:@"owner"];
            
            self.flickrRequestInfo.userPhotoWebPageURL = [self.flickrContext photoWebPageURLFromDictionary:photoDict];
            
            dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
            dispatch_queue_t main = dispatch_get_main_queue();
            
            dispatch_async(queue, ^{
                
                self.flickrRequestInfo.photo = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]];
                
                dispatch_async(main, ^{
                    
                    self.flickrRequestInfo.userId = owner;
                    
                    if (![self.flickrRequest isRunning]) {
                        ((FlickrAPIRequestSessionInfo *)self.flickrRequest.sessionInfo).flickrAPIRequestType = FlickrAPIRequestPhotoSizes;
                        
                        [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.getSizes" arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoId, @"photo_id", nil] tag:1];
                    }
                });
            });
        } else {
            NSError *error = [NSError errorWithDomain:@kAsyncQueueLabel code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"FlickrManager did not return any photos.", NSLocalizedDescriptionKey, nil]];
            
            self.completionBlock(nil, error);
            
            [self cleanUpFlickrManager];
        }
        
    }
}

- (void) resizeCropPhoto {
    float goldenRatio = 1.6;
    
    int const constWidth = 640;
    int const constHeight = 334;
    
    int newWidth;
    
    int width;
    int height;
    
    float ratio;
    
    CGSize newSize;
    
    width = self.flickrRequestInfo.photo.size.width;
    height = self.flickrRequestInfo.photo.size.height;
    
    ratio = ((float)width / (float)height);
    
    newWidth = roundf((constHeight * ratio));
    
    newSize = CGSizeMake(newWidth, constHeight);
    
    UIImage *resizedImage =  [self.flickrRequestInfo.photo resizedImage:newSize interpolationQuality:kCGInterpolationDefault];
    
    int cropX = ((newWidth / 2) - (constWidth / 2) * (goldenRatio - 1));
    
    UIImage *croppedImage = [resizedImage croppedImage:CGRectMake(cropX, 0, constWidth, constHeight)];
    
    self.flickrRequestInfo.photo = croppedImage;
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError {
    self.completionBlock(nil, inError);
    
    [self cleanUpFlickrManager];
}

@end
