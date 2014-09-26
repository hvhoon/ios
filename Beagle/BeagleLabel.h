//
//  BeagleLabel.h
//  Beagle
//
//  Created by Kanav Gupta on 26/09/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

typedef enum {
    BeagleHandle = 0,
    BeagleHashtag,
    BeagleLink
} BeagleHotWord;

@interface BeagleLabel : UILabel

@property (nonatomic, strong) NSArray *validProtocols;
@property (nonatomic, assign) BOOL leftToRight;
@property (nonatomic, assign) BOOL textSelectable;
@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, copy) void (^detectionBlock)(BeagleHotWord hotWord, NSString *string, NSString *protocol, NSRange range);

- (void)setAttributes:(NSDictionary *)attributes;
- (void)setAttributes:(NSDictionary *)attributes hotWord:(BeagleHotWord)hotWord;
- (void)setupLabel:(NSInteger)TypeFont;
- (NSDictionary *)attributes;
- (NSDictionary *)attributesForHotWord:(BeagleHotWord)hotWord;
- (id)initWithFrame:(CGRect)frame fontType:(NSInteger)fontType;
- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width;

@end
