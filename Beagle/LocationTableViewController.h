//
//  LocationTableViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GooglePlacesAutocompleteQuery;
@protocol LocationTableViewDelegate;

@interface LocationTableViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate,UITableViewDataSource,UITableViewDelegate>{
    NSArray *searchResultPlaces;
    GooglePlacesAutocompleteQuery *searchQuery;
    BOOL shouldBeginEditing;
}
@property (assign, nonatomic) id <LocationTableViewDelegate>delegate;
@end

@protocol LocationTableViewDelegate<NSObject>
@optional
- (void)dismissLocationTable:(LocationTableViewController*)viewController;
@end
