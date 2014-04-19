//
//  PlayerProfileItem.m
//  Beagle
//
//  Created by Kanav Gupta on 19/04/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "PlayerProfileItem.h"

static inline CGRect ScaleRect(CGRect rect, float n) {
	return CGRectMake((rect.size.width - rect.size.width * n) / 2, (rect.size.height - rect.size.height * n) / 2, rect.size.width * n, rect.size.height * n);
}

@implementation PlayerProfileItem
@synthesize profileImageUrl,playerId,isInitialized;


# pragma mark -
# pragma mark Initialization method
# pragma mark -




- (id)initProfileItem:(NSString *)iconImageurl label:(NSString *)labelItem playerId:(NSInteger)idP andAction:(actionBlock)block{
	self = [[[NSBundle mainBundle] loadNibNamed:@"PlayerProfileItem" owner:self options:nil] lastObject];
	if (self) {
		// Initialization code
		self.nameLabelItem.text = labelItem;
        self.block = block;
        self.playerId=idP;
        self.profileImageUrl=iconImageurl;
    }
	return self;
}

# pragma mark -
# pragma mark UIView methods
# pragma mark -


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
	if ([_delegate respondsToSelector:@selector(itemTouchesBegan:)]) {
		[_delegate itemTouchesBegan:self];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	CGPoint location = [[touches anyObject] locationInView:self];
	if (!CGRectContainsPoint(ScaleRect(self.bounds, 2.0f), location)) {
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint location = [[touches anyObject] locationInView:self];
	if (CGRectContainsPoint(ScaleRect(self.bounds, 2.0f), location)) {
		if ([_delegate respondsToSelector:@selector(itemTouchesEnd:)]) {
			[_delegate itemTouchesEnd:self];
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}



@end
