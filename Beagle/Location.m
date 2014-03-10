//
//  Location.m
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "Location.h"

@implementation Location
@synthesize category;
@synthesize name;

+ (id)locationCategory:(NSString *)category name:(NSString *)name
{
    Location *newLocation = [[self alloc] init];
    [newLocation setCategory:category];
    [newLocation setName:name];
    return newLocation;
}

@end

