//
//  BGStockPhotoManager.m
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BGStockPhotoManager.h"
#import "UIImage+ImageEffects.h"

@implementation BGStockPhotoManager

static BGStockPhotoManager *sharedManager = nil;

+ (BGStockPhotoManager *) sharedManager {
    @synchronized (self) {
        if (sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    }
    
    return sharedManager;
}

- (id) init {
	self = [super init];
	
    if (self != nil) {
        [self load];
	}
    
	return self;
}

- (void) load {
    NSArray *files = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:@"StockPhotos"];
    
    self.stockPhotoSet = [[NSMutableSet alloc] init];
    
    NSString *prefix;
    NSString *token;
    
    for (NSString *fileName in files) {
        prefix = [fileName lastPathComponent];
        
        token = [prefix substringWithRange:NSMakeRange(0, 3)];
        [self.stockPhotoSet addObject:token];
    }
}

- (void) randomStockPhoto: (void (^)(BGPhotos *)) completion {
    
    BGPhotos *photos = [[BGPhotos alloc] init];
    
    dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
    dispatch_queue_t main = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        NSInteger stockPhotoCount = ([self.stockPhotoSet count] - 1);
        NSInteger randomIndex = [BeagleUtilities getRandomIntBetweenLow:0 andHigh:stockPhotoCount];
    
        NSString *imagePath = [NSString stringWithFormat:@"%@/%03ld-StockPhoto-320x568.png", @"StockPhotos", (long)randomIndex];
    
        photos.photo = [UIImage imageNamed:imagePath];
        
        dispatch_async(main, ^{
            completion(photos);
        });
    });
}

@end
