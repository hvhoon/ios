//
//  BeagleLabel.m
//  Beagle
//
//  Created by Kanav Gupta on 26/09/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "BeagleLabel.h"
#import "BeagleTextStorage.h"

#define STURLRegex @"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’])|([a-z0-9.\\-]+[.]com)|([a-z0-9.\\-]+[.]buzz)|([a-z0-9.\\-]+[.]org))"
#pragma mark -
#pragma mark STTweetLabel

@interface BeagleLabel () <UITextViewDelegate>

@property (strong) BeagleTextStorage *textStorage;
@property (strong) NSLayoutManager *layoutManager;
@property (strong) NSTextContainer *textContainer;
@property (nonatomic, strong) NSString *cleanText;
@property (strong) NSMutableArray *rangesOfHotWords;
@property (nonatomic, strong) NSDictionary *attributesText;
@property (nonatomic, strong) NSDictionary *attributesHandle;
@property (nonatomic, strong) NSDictionary *attributesHashtag;
@property (nonatomic, strong) NSDictionary *attributesLink;
@property (strong) UITextView *textView;
- (void)determineHotWords;
- (void)determineLinks;
- (void)updateText;

@end

@implementation BeagleLabel {
    BOOL _isTouchesMoved;
    NSRange _selectableRange;
    int _firstCharIndex;
    CGPoint _firstTouchLocation;
}
@synthesize fontType;
#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame type:(NSInteger)type{
    self = [super initWithFrame:frame];
    fontType=type;
    
    if (self) {
        [self setupLabel];
    }
    
    return self;
}

#pragma mark -
#pragma mark Responder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)copy:(id)sender {
    [[UIPasteboard generalPasteboard] setString:[_cleanText substringWithRange:_selectableRange]];
    
    @try {
        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:_selectableRange];
    } @catch (NSException *exception) {
    }
}
-(BOOL)isValidURL:(NSString*)text {
    NSUInteger length = [text length];
    // Empty strings should return NO
    if (length > 0) {
        NSError *error = nil;
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        if (dataDetector && !error) {
            NSRange range = NSMakeRange(0, length);
            NSRange notFoundRange = (NSRange){NSNotFound, 0};
            NSRange linkRange = [dataDetector rangeOfFirstMatchInString:text options:0 range:range];
            if (!NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange)) {
                return YES;
            }
        }
        else {
            NSLog(@"Could not create link data detector: %@ %@", [error localizedDescription], [error userInfo]);
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Setup

- (void)setupLabel{
    // Set the basic properties
    [self setBackgroundColor:[UIColor clearColor]];
    [self setClipsToBounds:NO];
    [self setUserInteractionEnabled:YES];
    [self setNumberOfLines:0];
    
    _leftToRight = YES;
    _textSelectable = YES;
    _selectionColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    switch (fontType) {
        case 1:
        {
            _attributesText = @{NSForegroundColorAttributeName: self.textColor, NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:17.0f]};
            _attributesHandle = @{NSForegroundColorAttributeName: [UIColor redColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:17.0f]};
            _attributesHashtag = @{NSForegroundColorAttributeName: [[UIColor alloc] initWithWhite:170.0/255.0 alpha:1.0], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:17.0f]};
            _attributesLink = @{NSForegroundColorAttributeName:[[BeagleManager SharedInstance] mediumDominantColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:17.0f]};
            
        }
            break;

        case 2:
        {
            _attributesText = @{NSForegroundColorAttributeName: self.textColor, NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]};
            _attributesHandle = @{NSForegroundColorAttributeName: [UIColor redColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]};
            _attributesHashtag = @{NSForegroundColorAttributeName: [[UIColor alloc] initWithWhite:170.0/255.0 alpha:1.0], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]};
            _attributesLink = @{NSForegroundColorAttributeName:[[BeagleManager SharedInstance] mediumDominantColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]};
            
        }
            break;

        default:
            break;
    }
    
    self.validProtocols = @[@"http", @"https",@"www"];
}

#pragma mark -
#pragma mark Printing and calculating text

- (void)determineHotWords {
    // Need a text
    if (_cleanText == nil)
        return;
    
    _textStorage = [[BeagleTextStorage alloc] init];
    _layoutManager = [[NSLayoutManager alloc] init];
    
    NSMutableString *tmpText = [[NSMutableString alloc] initWithString:_cleanText];
    
    // Support RTL
    if (!_leftToRight) {
        tmpText = [[NSMutableString alloc] init];
        [tmpText appendString:@"\u200F"];
        [tmpText appendString:_cleanText];
    }
    
    // Define a character set for hot characters (@ handle, # hashtag)
    NSString *hotCharacters = @"@#";
    NSCharacterSet *hotCharactersSet = [NSCharacterSet characterSetWithCharactersInString:hotCharacters];
    
    // Define a character set for the complete world (determine the end of the hot word)
    NSMutableCharacterSet *validCharactersSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [validCharactersSet removeCharactersInString:@"!@#$%^&*()-={[]}|;:',<>.?/"];
    [validCharactersSet addCharactersInString:@"_"];
    
    _rangesOfHotWords = [[NSMutableArray alloc] init];
    
    while ([tmpText rangeOfCharacterFromSet:hotCharactersSet].location < tmpText.length) {
        NSRange range = [tmpText rangeOfCharacterFromSet:hotCharactersSet];
        
        BeagleHotWord hotWord;
        
        switch ([tmpText characterAtIndex:range.location]) {
            case '@':
                hotWord = BeagleHandle;
                break;
            case '#':
                hotWord = BeagleHashtag;
                break;
            default:
                break;
        }
        
        [tmpText replaceCharactersInRange:range withString:@"%"];
        // If the hot character is not preceded by a alphanumeric characater, ie email (sebastien@world.com)
        if (range.location > 0 && [validCharactersSet characterIsMember:[tmpText characterAtIndex:range.location - 1]])
            continue;
        
        // Determine the length of the hot word
        int length = (int)range.length;
        
        while (range.location + length < tmpText.length) {
            BOOL charIsMember = [validCharactersSet characterIsMember:[tmpText characterAtIndex:range.location + length]];
            
            if (charIsMember)
                length++;
            else
                break;
        }
        
        // Register the hot word and its range
        if (length > 1)
            [_rangesOfHotWords addObject:@{@"hotWord": @(hotWord), @"range": [NSValue valueWithRange:NSMakeRange(range.location, length)]}];
    }
    
    [self determineLinks];
    [self updateText];
}

- (void)determineLinks {
    
#if 0
     NSMutableString *tmpText = [[NSMutableString alloc] initWithString:_cleanText];
    [tmpText enumerateSubstringsInRange:NSMakeRange(0, tmpText.length) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
        {
            NSUInteger length = [substring length];
            // Empty strings should return NO
            if (length > 0) {
                NSError *error = nil;
                NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
                if (dataDetector && !error) {
                    NSRange range = NSMakeRange(0, length);
                    NSRange notFoundRange = (NSRange){NSNotFound, 0};
                    NSRange linkRange = [dataDetector rangeOfFirstMatchInString:substring options:0 range:range];
                    if (!NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange)) {
                        [_rangesOfHotWords addObject:@{@"hotWord": @(BeagleLink), @"protocol": @"http", @"range": [NSValue valueWithRange:substringRange]}];
                        
                    }
                }
                else {
                    NSLog(@"Could not create link data detector: %@ %@", [error localizedDescription], [error userInfo]);
                }
            }
        }
    }];

    NSMutableString *tmpText = [[NSMutableString alloc] initWithString:_cleanText];
    
    NSError *regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:STURLRegex options:0 error:&regexError];
    
    [regex enumerateMatchesInString:tmpText options:0 range:NSMakeRange(0, tmpText.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *protocol = @"http";
        NSString *link = [tmpText substringWithRange:result.range];
        NSRange protocolRange = [link rangeOfString:@"://"];
        if (protocolRange.location != NSNotFound) {
            protocol = [link substringToIndex:protocolRange.location];
        }
        
        if ([_validProtocols containsObject:protocol.lowercaseString]) {
            [_rangesOfHotWords addObject:@{@"hotWord": @(BeagleLink), @"protocol": protocol, @"range": [NSValue valueWithRange:result.range]}];
        }
    }];
#endif
    
    NSArray *words=[_cleanText componentsSeparatedByString:@" "];
    for(NSString *word in words){

        
            NSUInteger length = [word length];
            // Empty strings should return NO
            if (length > 0) {
                NSError *error = nil;
                NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
                if (dataDetector && !error) {
                    NSRange range = NSMakeRange(0, length);
                    NSRange notFoundRange = (NSRange){NSNotFound, 0};
                    NSRange linkRange = [dataDetector rangeOfFirstMatchInString:word options:0 range:range];
                    if (!NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange)) {
                        NSRange searchRange = [_cleanText rangeOfString:word];
                        [_rangesOfHotWords addObject:@{@"hotWord": @(BeagleLink), @"protocol": @"http", @"range": [NSValue valueWithRange:searchRange]}];
                        
                    }
                }
                else {
                    NSLog(@"Could not create link data detector: %@ %@", [error localizedDescription], [error userInfo]);
                }
            }

    }
}
- (void)updateText
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_cleanText];
    [attributedString setAttributes:_attributesText range:NSMakeRange(0, _cleanText.length)];
    
    for (NSDictionary *dictionary in _rangesOfHotWords)  {
        NSRange range = [[dictionary objectForKey:@"range"] rangeValue];
        BeagleHotWord hotWord = (BeagleHotWord)[[dictionary objectForKey:@"hotWord"] intValue];
        [attributedString setAttributes:[self attributesForHotWord:hotWord] range:range];
    }
    
    [_textStorage appendAttributedString:attributedString];
    
    _textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
    [_layoutManager addTextContainer:_textContainer];
    [_textStorage addLayoutManager:_layoutManager];
    
    if (_textView != nil)
        [_textView removeFromSuperview];
    

    
    _textView = [[UITextView alloc] initWithFrame:self.bounds textContainer:_textContainer];
    _textView.delegate = self;
    _textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textContainer.lineFragmentPadding = 0;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.userInteractionEnabled = NO;
    [self addSubview:_textView];
}

#pragma mark -
#pragma mark Public methods

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width {
    if (_cleanText == nil)
        return CGSizeZero;
    
    return [_textView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
}

#pragma mark -
#pragma mark Private methods

- (NSArray *)hotWordsList {
    return _rangesOfHotWords;
}

#pragma mark -
#pragma mark Setters

- (void)setText:(NSString *)text {
    [super setText:@""];
    _cleanText = text;
    [self determineHotWords];
}

- (void)setValidProtocols:(NSArray *)validProtocols {
    _validProtocols = validProtocols;
    [self determineHotWords];
}

- (void)setAttributes:(NSDictionary *)attributes {
    if (!attributes[NSFontAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSFontAttributeName] = self.font;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    if (!attributes[NSForegroundColorAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSForegroundColorAttributeName] = self.textColor;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    _attributesText = attributes;
    
    [self determineHotWords];
}

- (void)setAttributes:(NSDictionary *)attributes hotWord:(BeagleHotWord)hotWord {
    if (!attributes[NSFontAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSFontAttributeName] = self.font;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    if (!attributes[NSForegroundColorAttributeName]) {
        NSMutableDictionary *copy = [attributes mutableCopy];
        copy[NSForegroundColorAttributeName] = self.textColor;
        attributes = [NSDictionary dictionaryWithDictionary:copy];
    }
    
    switch (hotWord)  {
        case BeagleHandle:
            _attributesHandle = attributes;
            break;
        case BeagleHashtag:
            _attributesHashtag = attributes;
            break;
        case BeagleLink:
            _attributesLink = attributes;
            break;
        default:
            break;
    }
    
    [self determineHotWords];
}

- (void)setLeftToRight:(BOOL)leftToRight {
    _leftToRight = leftToRight;
    
    [self determineHotWords];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    _textView.textAlignment = textAlignment;
}

- (void)setDetectionBlock:(void (^)(BeagleHotWord, NSString *, NSString *, NSRange))detectionBlock {
    if (detectionBlock) {
        _detectionBlock = [detectionBlock copy];
        self.userInteractionEnabled = YES;
    } else {
        _detectionBlock = nil;
        self.userInteractionEnabled = NO;
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.text = attributedText.string;
    if (self.text.length > 0) {
        [self setAttributes:[attributedText attributesAtIndex:0 effectiveRange:NULL]];
    }
}

#pragma mark -
#pragma mark Getters

- (NSString *)text {
    return _cleanText;
}

- (NSDictionary *)attributes {
    return _attributesText;
}

- (NSDictionary *)attributesForHotWord:(BeagleHotWord)hotWord {
    switch (hotWord) {
        case BeagleHandle:
            return _attributesHandle;
            break;
        case BeagleHashtag:
            return _attributesHashtag;
            break;
        case BeagleLink:
            return _attributesLink;
            break;
        default:
            break;
    }
}

- (BOOL)isLeftToRight {
    return _leftToRight;
}

#pragma mark -
#pragma mark Retrieve word after touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(![self getTouchedHotword:touches]) {
        [super touchesBegan:touches withEvent:event];
    }
    
    _isTouchesMoved = NO;
    
//    @try {
//        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:_selectableRange];
//    } @catch (NSException *exception) {
//    }
    
    _selectableRange = NSMakeRange(0, 0);
    _firstTouchLocation = [[touches anyObject] locationInView:_textView];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if([self getTouchedHotword:touches] == nil) {
        [super touchesMoved:touches withEvent:event];
    }
    
    if (!_textSelectable) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setMenuVisible:NO animated:YES];
        
        return;
    }
    
    _isTouchesMoved = YES;
    
    int charIndex = [self charIndexAtLocation:[[touches anyObject] locationInView:_textView]];
    
    @try {
        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:_selectableRange];
    } @catch (NSException *exception) {
    }
    
    if (_selectableRange.length == 0) {
        _selectableRange = NSMakeRange(charIndex, 1);
        _firstCharIndex = charIndex;
    } else if (charIndex > _firstCharIndex) {
        _selectableRange = NSMakeRange(_firstCharIndex, charIndex - _firstCharIndex + 1);
    } else if (charIndex < _firstCharIndex) {
        _firstTouchLocation = [[touches anyObject] locationInView:_textView];
        
        _selectableRange = NSMakeRange(charIndex, _firstCharIndex - charIndex);
    }
    
    @try {
        [_textStorage addAttribute:NSBackgroundColorAttributeName value:_selectionColor range:_selectableRange];
    } @catch (NSException *exception) {
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    
    if (_isTouchesMoved) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setTargetRect:CGRectMake(_firstTouchLocation.x, _firstTouchLocation.y, 1.0, 1.0) inView:self];
        [menuController setMenuVisible:YES animated:YES];
        
        [self becomeFirstResponder];
        
        return;
    }
    
    if (!CGRectContainsPoint(_textView.frame, touchLocation))
        return;
    
    id touchedHotword = [self getTouchedHotword:touches];
    if(touchedHotword != nil) {
        NSRange range = [[touchedHotword objectForKey:@"range"] rangeValue];
        
        _detectionBlock((BeagleHotWord)[[touchedHotword objectForKey:@"hotWord"] intValue], [_cleanText substringWithRange:range], [touchedHotword objectForKey:@"protocol"], range);
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (NSUInteger)charIndexAtLocation:(CGPoint)touchLocation {
    NSUInteger glyphIndex = [_layoutManager glyphIndexForPoint:touchLocation inTextContainer:_textView.textContainer];
    CGRect boundingRect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:_textView.textContainer];
    
    if (CGRectContainsPoint(boundingRect, touchLocation))
        return [_layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    else
        return -1;
}

- (id)getTouchedHotword:(NSSet *)touches {
    NSUInteger charIndex = [self charIndexAtLocation:[[touches anyObject] locationInView:_textView]];
    
    for (id obj in _rangesOfHotWords) {
        NSRange range = [[obj objectForKey:@"range"] rangeValue];
        
        if (charIndex >= range.location && charIndex < range.location + range.length) {
            return obj;
        }
    }
    
    return nil;
}

@end
