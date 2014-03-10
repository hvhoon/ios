//
//  Location.h
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


@interface Location : NSObject {
    NSString *category;
    NSString *name;
}

@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *name;

+ (id)locationCategory:(NSString*)category name:(NSString*)name;

@end
