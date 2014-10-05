//
//  BeagleTextStorage.m
//  Beagle
//
//  Created by Kanav Gupta on 26/09/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BeagleTextStorage.h"

@implementation BeagleTextStorage {
    NSMutableAttributedString *_backingStore;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _backingStore = [[NSMutableAttributedString alloc] init];
    }
    
    return self;
}

- (NSString *)string {
    return [_backingStore string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [_backingStore attributesAtIndex:location effectiveRange:range];
}

- (NSAttributedString *)attributedString {
    return _backingStore;
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range {
    [self beginEditing];
    [_backingStore setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)addAttributes:(NSDictionary *)attrs range:(NSRange)range {
    [self beginEditing];
    [_backingStore addAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttribute:(NSString *)name range:(NSRange)range {
    [self beginEditing];
    [_backingStore removeAttribute:name range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
    [self beginEditing];
    [_backingStore replaceCharactersInRange:range withString:string];
    [self edited:(NSTextStorageEditedCharacters|NSTextStorageEditedAttributes) range:range changeInLength:string.length - range.length];
    [self endEditing];
}

#pragma mark -
#pragma mark Private methods

- (BOOL)isValidRange:(NSRange)range inString:(NSMutableAttributedString *)string {
    NSLog(@"%s", __FUNCTION__);
    if (range.location < string.length && range.location + range.length <= string.length)
        return YES;
    else
        return NO;
}

@end
