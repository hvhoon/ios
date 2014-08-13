//
//  HomeTableViewCell.h
//  Beagle
//
//  Created by Kanav Gupta on 21/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ABTableViewCell.h"
@class BeagleActivityClass;
@protocol HomeTableViewCellDelegate <NSObject>

@optional
-(void)detailedInterestScreenRedirect:(NSInteger)index;
-(void)updateInterestedStatus:(NSInteger)index;
-(void)profileScreenRedirect:(NSInteger)index;
-(void)askNearbyFriendsToPartOfSuggestedPost:(NSInteger)index;
@end

@interface HomeTableViewCell : ABTableViewCell{
   BeagleActivityClass *bg_activity;
   UIImage *photoImage;
   CGRect interestedRect;
   CGRect profileRect;
   CGRect nameRect;
}
@property(nonatomic,strong)UIImage*photoImage;
@property (nonatomic,weak)id <HomeTableViewCellDelegate> delegate;
@property (nonatomic, strong) BeagleActivityClass *bg_activity;
@property(nonatomic,assign)NSInteger cellIndex;
@end
