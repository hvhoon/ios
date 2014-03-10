//
//  LocationTableViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//


@interface LocationTableViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong,nonatomic) NSArray *locationArray;
@property (strong,nonatomic) NSMutableArray *filteredLocationArray;
@property IBOutlet UISearchBar *locationSearchBar;

@end
