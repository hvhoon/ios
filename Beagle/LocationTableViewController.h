//
//  LocationTableViewController.h
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol MJSecondPopupDelegate3;
@interface LocationTableViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong,nonatomic)IBOutlet UITableView *tableView;
@property (assign, nonatomic) id <MJSecondPopupDelegate3>delegate;
@property (strong,nonatomic) NSArray *candyArray;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;
@property IBOutlet UISearchBar *candySearchBar;

@end

@protocol MJSecondPopupDelegate3<NSObject>
@optional
- (void)cancelButtonClicked3:(LocationTableViewController*)secondDetailViewController;
@end
