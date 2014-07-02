//
//  FriendsTableViewCell.h
//  Beagle
//
//  Created by Kanav Gupta on 20/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ABTableViewCell.h"
@class BeagleUserClass;
@protocol FriendsTableViewCellDelegate <NSObject>

@optional
-(void)inviteFacebookFriendOnBeagle:(NSIndexPath*)indexPath;
-(void)userProfileSelected:(NSIndexPath*)indexPath;
@end

@interface FriendsTableViewCell : ABTableViewCell{
    BeagleUserClass *bgPlayer;
    UIImage *photoImage;
    CGRect interestedRect;
    CGRect profileRect;
    CGRect nameRect;
}
@property(nonatomic,strong)UIImage*photoImage;
@property (nonatomic,weak)id <FriendsTableViewCellDelegate> delegate;
@property (nonatomic, strong) BeagleUserClass *bgPlayer;
@property(nonatomic,strong)NSIndexPath *cellIndexPath;
@end
