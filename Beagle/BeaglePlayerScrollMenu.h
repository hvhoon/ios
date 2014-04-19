//
//  BeaglePlayerScrollMenu.h
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerProfileItem.h"

@class BeaglePlayerScrollMenu;

@protocol BeaglePlayerScrollMenuDelegate <NSObject>

@optional

- (void)scrollMenu:(BeaglePlayerScrollMenu *)menu didSelectIndex:(NSInteger)selectedIndex;

@end

@interface BeaglePlayerScrollMenu : UIView <PlayerProfileItemDelegate, UIScrollViewDelegate>{
    BOOL isDragging,isDecelerating;
    NSMutableDictionary *playerItemsDictionary;
}

//Type of animations
typedef enum {
	PlayerFadeZoomIn,
	PlayerFadeZoomOut,
	PlayerShake,
	PlayerClassicAnimation,
	PlayerZoomOut
} PlayerAnimation;


@property (nonatomic, weak) id <BeaglePlayerScrollMenuDelegate> delegate;
@property (nonatomic, strong) NSArray *menuArray;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) PlayerAnimation animationType;

- (id)initPlayerScrollMenuWithFrame:(CGRect)frame menuItems:(NSArray *)menuItems;
- (void)setUpPlayerScrollMenu:(NSArray *)menuItems;


@end
