//
//  PlayerProfileItem.h
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayerProfileItem;

@protocol PlayerProfileItemDelegate <NSObject>

- (void)itemTouchesBegan:(PlayerProfileItem *)item;
- (void)itemTouchesEnd:(PlayerProfileItem *)item;

@end

@interface PlayerProfileItem : UIView

typedef void(^actionBlock)(PlayerProfileItem *item);

typedef enum {
    
	ProfileImageItem,
	ProfileLabelItem,
	ProfileImageAndLabeItem
    
} ProfileItemType;

@property (nonatomic, weak) id <PlayerProfileItemDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabelItem;
@property (nonatomic, copy) actionBlock block;
@property (strong, nonatomic)  NSString *profileImageUrl;
@property(nonatomic,assign)NSInteger playerId;
@property(nonatomic,assign)BOOL isInitialized;

- (id)initProfileItem:(NSString *)iconImageurl label:(NSString *)labelItem playerId:(NSInteger)idP andAction:(actionBlock)block ;



@end
