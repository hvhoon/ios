//
//  LocationTableViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol LocationTableViewDelegate;
@interface LocationTableViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong,nonatomic)IBOutlet UITableView *tableView;
@property (assign, nonatomic) id <LocationTableViewDelegate>delegate;
@property (strong,nonatomic) NSArray *locationArray;
@property (strong,nonatomic) NSMutableArray *filteredLocationArray;
@property IBOutlet UISearchBar *candySearchBar;

@end

@protocol LocationTableViewDelegate<NSObject>
@optional
- (void)dismissLocationTable:(LocationTableViewController*)viewController;
@end
