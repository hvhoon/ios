//
//  BGStockPhotoManager.h
//  Beagle
//
//  Created by Kanav Gupta on 4/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BGPhotos.h"

@interface BGStockPhotoManager : NSObject

@property(nonatomic, strong) NSMutableSet *stockPhotoSet;

+ (BGStockPhotoManager *) sharedManager;
- (void) randomStockPhoto: (void (^)(BGPhotos *)) completion;

@end
