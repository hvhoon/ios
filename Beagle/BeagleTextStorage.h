//
//  BeagleTextStorage.h
//  Beagle
//
//  Created by Kanav Gupta on 26/09/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeagleTextStorage : NSTextStorage

- (NSAttributedString *)attributedString;
- (void)addAttributes:(NSDictionary *)attrs range:(NSRange)range;
- (void)removeAttribute:(NSString *)name range:(NSRange)range;

@end
