//
//  LocationTableViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LocationTableViewController.h"
#import "Location.h"

@interface LocationTableViewController ()

@end

@implementation LocationTableViewController
@synthesize locationArray;
@synthesize filteredLocationArray;
@synthesize candySearchBar;
@synthesize delegate;
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

// Add this method
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self.navigationController setNavigationBarHidden:NO];
    
    // Don't show the scope bar or cancel button until editing begins
    [candySearchBar setShowsScopeBar:NO];
    [candySearchBar sizeToFit];
    
//    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
//    {
//        [self prefersStatusBarHidden];
//        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
//    }

     [[UIApplication sharedApplication] setStatusBarHidden:YES];
    // Hide the search bar until user scrolls up
//    CGRect newBounds = [[self tableView] bounds];
//    newBounds.origin.y = newBounds.origin.y + candySearchBar.bounds.size.height;
//    [[self tableView] setBounds:newBounds];


    
    self.locationArray = [NSArray arrayWithObjects:
                  [Location locationCategory:@"location" name:@"Alabama,AL"],
                  [Location locationCategory:@"location" name:@"Alaska,AK"],
                  [Location locationCategory:@"location" name:@"Arkansas,AR"],
                  [Location locationCategory:@"location" name:@"Washington,WA"],
                  [Location locationCategory:@"location" name:@"Texas,TX"],
                  [Location locationCategory:@"location" name:@"Virginia,VA"],
                  [Location locationCategory:@"location" name:@"Pennsylvania,PA"],
                  [Location locationCategory:@"location" name:@"Tennessee,TN"],
                  [Location locationCategory:@"location" name:@"Vermont,VT"],
                  [Location locationCategory:@"location" name:@"Wyoming,WY"],

                  [Location locationCategory:@"other" name:@"Arizona,AZ"], nil];
    
    // Initialize the filteredCandyArray with a capacity equal to the candyArray's capacity
    self.filteredLocationArray = [NSMutableArray arrayWithCapacity:[self.locationArray count]];
    
    // Reload the table
    [[self tableView] reloadData];
    
//        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//        // make your gesture recognizer priority
//        singleTap.numberOfTapsRequired = 1;
//        [[self tableView ]addGestureRecognizer:singleTap];

    //[candySearchBar becomeFirstResponder];
    
    [self.searchDisplayController setActive:YES animated:YES];
    [self.searchDisplayController.searchBar becomeFirstResponder];
    self.searchDisplayController.searchResultsTableView.backgroundColor=[UIColor lightGrayColor];
}
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller{
    
}
- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    
}
- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller{
    
}
- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller{
    [candySearchBar resignFirstResponder];
    [delegate dismissLocationTable:self];
    
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [candySearchBar resignFirstResponder];
    [delegate dismissLocationTable:self];

    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Check to see whether the normal table or search results table is being displayed and return the count from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [self.filteredLocationArray count];
    }
	else
	{
        return [self.locationArray count];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    //tableView.rowHeight = 64;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Location *location = nil;
    cell.backgroundColor=[UIColor clearColor];
    // Check to see whether the normal table or search results table is being displayed and set the Candy object from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        location = [self.filteredLocationArray objectAtIndex:[indexPath row]];
    }
	else
	{
        location = [self.locationArray objectAtIndex:[indexPath row]];
    }
    
    // Configure the cell
    [[cell textLabel] setText:[location name]];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [delegate dismissLocationTable:self];
}


#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	// Update the filtered array based on the search text and scope.
	
    // Remove all objects from the filtered search array
	[self.filteredLocationArray removeAllObjects];
    
	// Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
    NSArray *tempArray = [self.locationArray filteredArrayUsingPredicate:predicate];
    
    
    self.filteredLocationArray = [NSMutableArray arrayWithArray:tempArray];
}


#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView{
    
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView{
    
}
@end
