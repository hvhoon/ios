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
@synthesize candyArray;
@synthesize filteredCandyArray;
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

    /*** Sample Data for candyArray ***/
    
    candyArray = [NSArray arrayWithObjects:
                  [Location locationCategory:@"chocolate" name:@"chocolate bar"],
                  [Location locationCategory:@"chocolate" name:@"chocolate chip"],
                  [Location locationCategory:@"chocolate" name:@"dark chocolate"],
                  [Location locationCategory:@"hard" name:@"lollipop"],
                  [Location locationCategory:@"hard" name:@"candy cane"],
                  [Location locationCategory:@"hard" name:@"jaw breaker"],
                  [Location locationCategory:@"other" name:@"caramel"],
                  [Location locationCategory:@"other" name:@"sour chew"],
                  [Location locationCategory:@"other" name:@"peanut butter cup"],
                  [Location locationCategory:@"other" name:@"gummi bear"], nil];
    
    // Initialize the filteredCandyArray with a capacity equal to the candyArray's capacity
    filteredCandyArray = [NSMutableArray arrayWithCapacity:[candyArray count]];
    
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
    [delegate cancelButtonClicked3:self];
    
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [candySearchBar resignFirstResponder];
    [delegate cancelButtonClicked3:self];

    
    
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
        return [filteredCandyArray count];
    }
	else
	{
        return [candyArray count];
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
    
    // Create a new Candy Object
    Location *candy = nil;
    cell.backgroundColor=[UIColor clearColor];
    // Check to see whether the normal table or search results table is being displayed and set the Candy object from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        candy = [filteredCandyArray objectAtIndex:[indexPath row]];
    }
	else
	{
        candy = [candyArray objectAtIndex:[indexPath row]];
    }
    
    // Configure the cell
    [[cell textLabel] setText:[candy name]];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [delegate cancelButtonClicked3:self];
}


#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	// Update the filtered array based on the search text and scope.
	
    // Remove all objects from the filtered search array
	[self.filteredCandyArray removeAllObjects];
    
	// Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
    NSArray *tempArray = [candyArray filteredArrayUsingPredicate:predicate];
    
    
    filteredCandyArray = [NSMutableArray arrayWithArray:tempArray];
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
