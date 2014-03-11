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
@synthesize locationSearchBar;
@synthesize delegate;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    locationSearchBar.showsCancelButton=YES;
    locationSearchBar.delegate=self;
    
    locationSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    locationSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    // Don't show the scope bar or cancel button until editing begins
    //[locationSearchBar setShowsScopeBar:NO];
   // [locationSearchBar sizeToFit];
   // self.searchDisplayController.displaysSearchBarInNavigationBar=YES;
    // Hide the search bar until user scrolls up
//    CGRect newBounds = [[self tableView] bounds];
//    newBounds.origin.y = newBounds.origin.y + locationSearchBar.bounds.size.height;
//    newBounds.origin.y=+20.0f;
//    [[self tableView] setBounds:newBounds];

    
    locationArray = [NSArray arrayWithObjects:
                  [Location locationCategory:@"NY" name:@"New York"],
                  [Location locationCategory:@"CA" name:@"San Francisco"],
                  [Location locationCategory:@"chocolate" name:@"dark chocolate"],
                  [Location locationCategory:@"hard" name:@"lollipop"],
                  [Location locationCategory:@"hard" name:@"candy cane"],
                  [Location locationCategory:@"hard" name:@"jaw breaker"],
                  [Location locationCategory:@"other" name:@"caramel"],
                  [Location locationCategory:@"other" name:@"sour chew"],
                  [Location locationCategory:@"other" name:@"peanut butter cup"],
                  [Location locationCategory:@"other" name:@"gummi bear"], nil];
    
    filteredLocationArray = [NSMutableArray arrayWithCapacity:[locationArray count]];
    
    // Reload the table
//    [[self tableView] reloadData];
//        [locationSearchBar becomeFirstResponder];
    [ self performSelector:@selector(test) withObject:nil afterDelay:0.01];

   // [self.searchDisplayController setActive:YES animated:YES];
}
-(void)test{
    [locationSearchBar becomeFirstResponder];
    [self searchDisplayController:self.searchDisplayController shouldReloadTableForSearchString:@""];
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    // Manually activate search mode
    // Use animated=NO so we'll be able to immediately un-hide it again
    [self.searchDisplayController setActive:YES animated:NO];
    
    // Hand over control to UISearchDisplayController during the search
    locationSearchBar.delegate = (id <UISearchBarDelegate>)self.searchDisplayController;
    
    return YES;
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
        return [filteredLocationArray count];
    }
	else
	{
        return [locationArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Location *location = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        location = [filteredLocationArray objectAtIndex:[indexPath row]];
    }
	else
	{
        location = [locationArray objectAtIndex:[indexPath row]];
    }
    
    // Configure the cell
    [[cell textLabel] setText:[location name]];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate filterIndex:indexPath.row];
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	// Update the filtered array based on the search text and scope.
	
    // Remove all objects from the filtered search array
	[self.filteredLocationArray removeAllObjects];
    [locationSearchBar setShowsScopeBar:NO];
	// Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
    NSArray *tempArray = [locationArray filteredArrayUsingPredicate:predicate];
    
//    if(![scope isEqualToString:@"All"]) {
//        // Further filter the array with the scope
//        NSPredicate *scopePredicate = [NSPredicate predicateWithFormat:@"SELF.category contains[c] %@",scope];
//        tempArray = [tempArray filteredArrayUsingPredicate:scopePredicate];
//    }
    
    filteredLocationArray = [NSMutableArray arrayWithArray:tempArray];
}


#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     nil];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     nil];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark - Search Button

- (IBAction)goToSearch:(id)sender
{
    // If you're worried that your users might not catch on to the fact that a search bar is available if they scroll to reveal it, a search icon will help them
    // Note that if you didn't hide your search bar, you should probably not include this, as it would be redundant
    [locationSearchBar becomeFirstResponder];
}



















@end
