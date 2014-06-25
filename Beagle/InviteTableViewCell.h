//
//  InviteTableViewCell.h
//  Beagle
//
//  Created by Kanav Gupta on 25/06/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ABTableViewCell.h"
@class BeagleUserClass;
@protocol InviteTableViewCellDelegate <NSObject>

@optional
-(void)inviteFriendOnBeagle:(NSIndexPath*)indexPath;
-(void)unInviteFriendOnBeagle:(NSIndexPath*)indexPath;
@end

@interface InviteTableViewCell : ABTableViewCell{
    BeagleUserClass *bgPlayer;
    UIImage *photoImage;

}
@property(nonatomic,strong)UIImage*photoImage;
@property (nonatomic,weak)id <InviteTableViewCellDelegate> delegate;
@property (nonatomic, strong) BeagleUserClass *bgPlayer;
@property(nonatomic,strong)NSIndexPath *cellIndexPath;

@end
