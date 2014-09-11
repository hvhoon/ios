//
//  LocationBlurView.m
//  Beagle
//
//  Created by Kanav Gupta on 14/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LocationBlurView.h"
#import "UIImage+ImageEffects.h"
#import "UIScreen+Screenshot.h"
#import "GooglePlacesAutocompleteQuery.h"
#import "GooglePlacesAutocompletePlace.h"

@interface LocationBlurView ()<UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate>
@property(nonatomic, weak)  UIView *parent;
@property(nonatomic, assign) CGPoint location;
@property(nonatomic, strong) dispatch_source_t timer;
@property(nonatomic,strong)UITableView*listView;
@property(nonatomic,strong)UISearchBar*citySearchBar;
@end

@implementation LocationBlurView

@synthesize delegate;
- (id) initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        _citySearchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(0, 20, 320, 44)];
        [self addSubview:_citySearchBar];
        _citySearchBar.delegate=self;
        _citySearchBar.placeholder=@"Search City Name";
        
        int height=[UIScreen mainScreen].bounds.size.height > 480.0f ? 288 : 200;
        _listView=[[UITableView alloc]initWithFrame:CGRectMake(0, 64, 320, height)];
        _listView.delegate=self;
        _listView.dataSource=self;
//        _listView.separatorStyle=UITableViewCellSeparatorStyleNone;
        _listView.backgroundColor=[UIColor clearColor];
        [_citySearchBar becomeFirstResponder];
        [self addSubview:_listView];
        searchQuery = [[GooglePlacesAutocompleteQuery alloc] init];
        searchQuery.radius = 100.0;
        shouldBeginEditing = YES;
         [_citySearchBar setShowsCancelButton:YES animated:YES];
        self.listView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return self;
}
#pragma mark -
#pragma mark UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    
    if (![searchBar isFirstResponder]) {
        // User tapped the 'clear' button.
        shouldBeginEditing = NO;
    }
    [self handleSearchForSearchString:searchBar.text];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
//    if (shouldBeginEditing) {
//        // Animate in the table view.
//        NSTimeInterval animationDuration = 0.3;
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDuration:animationDuration];
//        //eself.searchDisplayController.searchResultsTableView.alpha = 1.0;
//        [UIView commitAnimations];
//        
//        [searchBar setShowsCancelButton:YES animated:YES];
//    }
//    BOOL boolToReturn = shouldBeginEditing;
//    shouldBeginEditing = YES;
    return YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self dismissSearchControllerWhileStayingActive];
    [self crossDissolveHide];
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Check to see whether the normal table or search results table is being displayed and return the count from the appropriate array
    return [searchResultPlaces count];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    //tableView.rowHeight = 64;
}
- (GooglePlacesAutocompletePlace *)placeAtIndexPath:(NSIndexPath *)indexPath {
    return [searchResultPlaces objectAtIndex:indexPath.row];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.backgroundColor=[UIColor clearColor];
    [[cell textLabel]setTextColor:[UIColor whiteColor]];
    [[cell textLabel]setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    [[cell textLabel] setText:[self placeAtIndexPath:indexPath].name];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    GooglePlacesAutocompletePlace *place = [self placeAtIndexPath:indexPath];
    [place resolveToPlacemark:^(CLPlacemark *placemark, NSString *addressString, NSError *error) {
        if (error) {
            PresentAlertViewWithErrorAndTitle(error, @"Could not Fetch The Location Details");
        } else if (placemark) {
            
            [self dismissSearchControllerWhileStayingActive];
            [self crossDissolveHide];
            [self.delegate interestLocationSelected:placemark];
            
        }
    }];

}

#pragma mark Content Filtering

- (void)handleSearchForSearchString:(NSString *)searchString {
    searchQuery.location = [[BeagleManager SharedInstance]currentLocation].coordinate;
    searchQuery.input = searchString;
    [searchQuery fetchPlaces:^(NSArray *places, NSError *error) {
        if (error) {
            PresentAlertViewWithErrorAndTitle(error, @"Could not fetch Places");
        } else {
            searchResultPlaces = [NSArray arrayWithArray:places];
            [self.listView reloadData];
        }
    }];
}


- (void)dismissSearchControllerWhileStayingActive {
    // Animate out the table view.
    NSTimeInterval animationDuration = 0.3;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    [UIView commitAnimations];
    
    [_citySearchBar setShowsCancelButton:NO animated:NO];
     [_citySearchBar resignFirstResponder];
}
+ (LocationBlurView *) loadLocationFilter:(UIView *) view {
    LocationBlurView *blur = [[[NSBundle mainBundle] loadNibNamed:@"LocationBlurView" owner:nil options:nil] objectAtIndex:0];
    blur.userInteractionEnabled=YES;
    blur.parent = view;
    blur.location = CGPointMake(0, 0);
    blur.frame = CGRectMake(blur.location.x, -(blur.frame.size.height + blur.location.y), blur.frame.size.width, blur.frame.size.height);
    
    return blur;
}

- (void) awakeFromNib {
    self.layer.cornerRadius = 1;
}

- (void) unload {
    if(self.timer != nil) {
        
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    
    [self removeFromSuperview];
}



- (void) blurBackground {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGRectGetWidth(self.parent.frame), CGRectGetHeight(self.parent.frame)), NO, 1);
    
    [self.parent drawViewHierarchyInRect:CGRectMake(0, 0, CGRectGetWidth(self.parent.frame), CGRectGetHeight(self.parent.frame)) afterScreenUpdates:NO];
    
    
    UIGraphicsEndImageContext();
    
    __block UIImage *snapshot=[UIScreen screenshot];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        snapshot=[snapshot applyBlurWithRadius:5 tintColor:[UIColor colorWithRed:162.0/255.0 green:162.0/255.0 blue:162.0/255.0 alpha:0.69] saturationDeltaFactor:1.8 maskImage:nil];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.backgroundColor=[UIColor colorWithPatternImage:snapshot];
        });
    });
}

- (void) blurWithColor{
    [self blurBackground];
}

- (void) crossDissolveShow {
    
    self.frame = CGRectMake(self.location.x, self.location.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    self.alpha =  0.0f;
    
    [UIView transitionWithView:self duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [_citySearchBar becomeFirstResponder];
        [_citySearchBar setShowsCancelButton:YES animated:YES];
        
    }];
    
    
    
}

- (void) crossDissolveHide {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissEventFilter)])
             [self.delegate dismissEventFilter];
    
    
    if(self.timer != nil) {
        
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    self.frame = CGRectMake(self.location.x, -(self.frame.size.height + self.location.y), self.frame.size.width, self.frame.size.height);
    
    
    [UIView transitionWithView:self duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        self.alpha =0.0f;
    } completion:^(BOOL finished) {
        
    }];
    
    
}


@end
