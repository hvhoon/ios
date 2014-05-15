//
//  LocationBlurView.h
//  Beagle
//
//  Created by Kanav Gupta on 14/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GooglePlacesAutocompleteQuery;
@protocol LocationBlurViewDelegate <NSObject>

@optional
- (void)dismissEventFilter;
-(void)interestLocationSelected:(CLPlacemark*)placemark;
@end
@interface LocationBlurView : UIView<UISearchBarDelegate>{
    NSArray *searchResultPlaces;
    GooglePlacesAutocompleteQuery *searchQuery;
    BOOL shouldBeginEditing;

}
@property(nonatomic,assign)id<LocationBlurViewDelegate>delegate;
+ (LocationBlurView *) loadLocationFilter:(UIView *) view;

- (void) unload;
- (void) crossDissolveShow;
- (void) crossDissolveHide;
- (void) blurWithColor;

@end
