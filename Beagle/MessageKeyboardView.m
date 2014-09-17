
#import "MessageKeyboardView.h"
#import "BeagleUtilities.h"


static BOOL RDRKeyboardSizeEqualsInputViewSize(CGRect keyboardFrame,
                                               CGRect inputViewBounds) {
    // Convert keyboardFrame
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *view = window.rootViewController.view;
    CGRect convertedRect = [view convertRect:keyboardFrame
                                    fromView:nil];
    
    if (CGSizeEqualToSize(convertedRect.size, inputViewBounds.size)) {
        return YES;
    }
    
    return NO;
}

static BOOL RDRKeyboardFrameChangeEqualsKeyboardHeight(CGRect beginFrame,
                                                       CGRect endFrame) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *view = window.rootViewController.view;
    
    // Convert the begin frame to view coordinates
    CGRect beginFrameConverted = [view convertRect:beginFrame
                                          fromView:nil];
    
    // Convert the end frame to view coordinates
    CGRect endFrameConverted = [view convertRect:endFrame
                                        fromView:nil];
    
    // New and old keyboard origin should differ exactly
    // one keyboard height
    if (fabs(endFrameConverted.origin.y - beginFrameConverted.origin.y)
        != endFrameConverted.size.height) {
        return NO;
    }
    
    return YES;
}

static BOOL RDRKeyboardFrameChangeEqualsInputViewHeight(CGRect beginFrame,
                                                        CGRect endFrame,
                                                        CGRect inputViewBounds) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *view = window.rootViewController.view;
    
    // Convert the begin frame to view coordinates
    CGRect beginFrameConverted = [view convertRect:beginFrame
                                          fromView:nil];
    
    // Convert the end frame to view coordinates
    CGRect endFrameConverted = [view convertRect:endFrame
                                        fromView:nil];
    
    // New and old keyboard origin should differ exactly
    // one keyboard height
    if (fabs(endFrameConverted.origin.y - beginFrameConverted.origin.y)
        != inputViewBounds.size.height) {
        return NO;
    }
    
    return YES;
}

static BOOL RDRKeyboardIsFullyShown(CGRect keyboardFrame) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *view = window.rootViewController.view;
    CGRect convertedRect = [view convertRect:keyboardFrame
                                    fromView:nil];
    
    if ((view.bounds.size.height - convertedRect.size.height)
        != convertedRect.origin.y) {
        return NO;
    }
    
    return YES;
}

static BOOL RDRKeyboardIsFullyHidden(CGRect keyboardFrame) {
    // The window's rootViewController's view
    // is fullscreen.
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *view = window.rootViewController.view;
    
    // Convert rect to view coordinates, which will
    // adjust the frame for rotation.
    CGRect convertedRect = [view convertRect:keyboardFrame
                                    fromView:nil];
    
    // Compare against the view's bounds, NOT the frame
    // since the bounds are adjusted to rotation.
    if (view.bounds.size.height != convertedRect.origin.y) {
        return NO;
    }
    
    return YES;
}

static inline CGFloat RDRTextViewHeight(UITextView *textView) {
    NSTextContainer *textContainer = textView.textContainer;
    CGRect textRect =
    [textView.layoutManager usedRectForTextContainer:textContainer];
    
    CGFloat textViewHeight = textRect.size.height +
    textView.textContainerInset.top + textView.textContainerInset.bottom;
    
    return textViewHeight;
}

static CGFloat RDRContentOffsetForBottom(UIScrollView *scrollView) {
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    
    UIEdgeInsets contentInset = scrollView.contentInset;
    CGFloat bottomInset = contentInset.bottom;
    CGFloat topInset = contentInset.top;
    
    CGFloat contentOffsetY;
    contentOffsetY = contentHeight - (scrollViewHeight - bottomInset);
    contentOffsetY = MAX(contentOffsetY, -topInset);
    
    return contentOffsetY;
}

static inline UIViewAnimationOptions RDRAnimationOptionsForCurve(UIViewAnimationCurve curve) {
    return (curve << 16 | UIViewAnimationOptionBeginFromCurrentState);
}

#pragma mark - KeyboardInputView

#define RDR_KEYBOARD_INPUT_VIEW_MARGIN_VERTICAL                     5
#define RDR_KEYBOARD_INPUT_VIEW_MARGIN_HORIZONTAL                   8
#define RDR_KEYBOARD_INPUT_VIEW_MARGIN_BUTTONS_VERTICAL             7

@interface KeyboardInputView () {
    UITextView *_textView;
    UIButton *_leftButton;
    UIButton *_rightButton;
}

@property (nonatomic, strong, readonly) UIToolbar *toolbar;

@end

@implementation KeyboardInputView

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    // Input view sets its own height
    if (self = [super initWithFrame:frame])
    {
        [self _setupSubviews];
    }
    
    return self;
}

#pragma mark - Getters

- (UITextView *)textView
{
    if (_textView != nil) {
        return _textView;
    }
    
    _textView = [UITextView new];
    self.textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
    self.textView.textColor=[UIColor blackColor];
    return self.textView;
}


- (UIButton *)rightButton
{
    if (_rightButton != nil) {
        return _rightButton;
    }
    
    _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rightButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    _rightButton.titleLabel.textColor=[BeagleUtilities returnBeagleColor:13];
    [_rightButton setTitle:NSLocalizedString(@"Post", nil)
                  forState:UIControlStateNormal];
    
    return _rightButton;
}

#pragma mark - Private

- (void)_setupSubviews
{
    _toolbar = [UIToolbar new];
    _toolbar.translucent = NO;
    [self addSubview:self.toolbar];
    
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    
    [self _setupConstraints];
    
    
}

- (void)_setupConstraints
{
    // Calculate frame with current settings
    CGFloat height = RDRTextViewHeight(self.textView) +
    (2 * RDR_KEYBOARD_INPUT_VIEW_MARGIN_VERTICAL);
    height = roundf(height);
    
    CGRect newFrame = self.frame;
    newFrame.size.height = height;
    self.frame = newFrame;
    
    // Calculate button margin with new frame height
    [self.rightButton sizeToFit];
    
    CGFloat leftButtonMargin =
    roundf((height) / 2.0f);
    CGFloat rightButtonMargin =
    roundf((height - self.rightButton.frame.size.height) / 2.0f);
    
    leftButtonMargin = roundf(leftButtonMargin);
    rightButtonMargin = roundf(rightButtonMargin);
    
    // Set autolayout property
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Define constraints
    NSArray *constraints = nil;
    NSString *visualFormat = nil;
    NSDictionary *views = @{ @"rightButton" : self.rightButton,
                             @"textView" : self.textView,
                             @"toolbar" : self.toolbar};
    NSDictionary *metrics = @{ @"hor" : @(RDR_KEYBOARD_INPUT_VIEW_MARGIN_HORIZONTAL),
                               @"ver" : @(RDR_KEYBOARD_INPUT_VIEW_MARGIN_VERTICAL),
                               @"rightButtonMargin" : @(rightButtonMargin)};
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[toolbar]|"
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|"
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    [self addConstraints:constraints];
    
    visualFormat = @"H:|-(==hor)-[textView]-(==hor)-[rightButton]-(==hor)-|";
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    [self addConstraints:constraints];
    
    
    visualFormat = @"V:|-(>=rightButtonMargin)-[rightButton]-(==rightButtonMargin)-|";
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    [self addConstraints:constraints];
    
    visualFormat = @"V:|-(==ver)-[textView]-(==ver)-|";
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    [self addConstraints:constraints];
}

@end

#pragma mark - UIScrollView + MessageKeyboardView

#define RDR_SCROLL_ANIMATION_DURATION                   0.25f

@implementation UIScrollView (MessageKeyboardView)

#pragma mark - Public

- (BOOL)rdr_isAtBottom
{
    UIScrollView *scrollView = self;
    CGFloat y = scrollView.contentOffset.y;
    CGFloat yBottom = RDRContentOffsetForBottom(scrollView);
    
    return (y == yBottom);
}

- (void)rdr_scrollToBottomAnimated:(BOOL)animated
               withCompletionBlock:(void(^)(void))completionBlock
{
    [self rdr_scrollToBottomWithOptions:0
                               duration:RDR_SCROLL_ANIMATION_DURATION
                        completionBlock:completionBlock];
}

- (void)rdr_scrollToBottomWithOptions:(UIViewAnimationOptions)options
                             duration:(CGFloat)duration
                      completionBlock:(void(^)(void))completionBlock
{
    UIScrollView *scrollView = self;
    CGPoint contentOffset = scrollView.contentOffset;
    contentOffset.y = RDRContentOffsetForBottom(scrollView);
    void(^animations)() = ^{
        scrollView.contentOffset = contentOffset;
    };
    
    void(^completion)(BOOL) = ^(BOOL finished){
        if (completionBlock) {
            completionBlock();
        }
    };
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:options
                     animations:animations
                     completion:completion];
}

@end

#pragma mark - RDRStickyKeyboardView

static NSInteger const RDRInterfaceOrientationUnknown   = -1;

@interface MessageKeyboardView () <UITextViewDelegate> {
    UIInterfaceOrientation _currentOrientation;
    BOOL _visible;
}



@end

@implementation MessageKeyboardView
@synthesize dummyInputView,interested,delegate;
#pragma mark - Lifecycle

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
    if (self = [super init])
    {
        _scrollView = scrollView;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|
        UIViewAutoresizingFlexibleHeight;
        //_scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        
        _currentOrientation = RDRInterfaceOrientationUnknown;
        
        [self _setupSubviews];
        [self _registerForNotifications];
    }
    
    return self;
}

- (void)dealloc
{
    [self _unregisterForNotifications];
}

#pragma mark - Overrides

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == nil) {
        [super willMoveToSuperview:newSuperview];
        return;
    }
    
    [self _setInitialFrames];
    [super willMoveToSuperview:newSuperview];
}

#pragma mark - Public

- (void)reloadInputAccessoryView
{
    [self _updateInputViewFrameWithKeyboardFrame:CGRectZero
                                     forceReload:YES];
}

#pragma mark - Private

- (void)_setupSubviews
{
    [self addSubview:self.scrollView];
    
    _inputView = [KeyboardInputView new];
    self.inputView.autoresizingMask = UIViewAutoresizingFlexibleWidth|
    UIViewAutoresizingFlexibleHeight;
    self.inputView.textView.delegate = self;
    
    self.dummyInputView = [KeyboardInputView new];
    self.dummyInputView.autoresizingMask = UIViewAutoresizingFlexibleWidth|
    UIViewAutoresizingFlexibleTopMargin;
    self.dummyInputView.textView.inputAccessoryView = self.inputView;
    self.dummyInputView.textView.tintColor = [UIColor clearColor];
    self.dummyInputView.textView.delegate = self;
    self.dummyInputView.textView.text=@"Join the conversation";
    self.dummyInputView.textView.textColor = [BeagleUtilities returnBeagleColor:3];
    [self addSubview:self.dummyInputView];
    
}

- (void)_setInitialFrames
{
    CGRect scrollViewFrame = CGRectZero;
    scrollViewFrame.origin.y=0;
    scrollViewFrame.size.width = self.frame.size.width;
    if(interested){

    scrollViewFrame.size.height = self.frame.size.height - self.inputView.frame.size.height;
    }
    else{
        scrollViewFrame.size.height = self.frame.size.height;

    }
    self.scrollView.frame = scrollViewFrame;
    
    CGRect inputViewFrame = self.inputView.frame;
    inputViewFrame.size.width = self.frame.size.width;
    self.inputView.frame = inputViewFrame;
    
    CGRect dummyInputViewFrame = CGRectZero;
    dummyInputViewFrame.origin.y = self.frame.size.height - inputViewFrame.size.height;
    dummyInputViewFrame.size = inputViewFrame.size;
    self.dummyInputView.frame = dummyInputViewFrame;
}

#pragma mark - Notifications

- (void)_registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)_unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark - Notification handlers
#pragma mark - Keyboard

- (void)_keyboardWillShow:(NSNotification *)notification
{
    [Appsee pause];
    _visible=TRUE;
    if (self.delegate && [self.delegate respondsToSelector:@selector(show)])
        [self.delegate show];

    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    // Check if orientation changed
    [self _updateInputViewFrameIfOrientationChanged:endFrame];
    
    [self.inputView.textView becomeFirstResponder];
    
    // Disregard false notification
    // This works around a bug in iOS
    CGRect inputViewBounds = self.inputView.bounds;
    if (RDRKeyboardSizeEqualsInputViewSize(endFrame, inputViewBounds)) {
        return;
    }
    
    if (RDRKeyboardSizeEqualsInputViewSize(beginFrame, inputViewBounds)) {
        return;
    }
    
    // New and old keyboard origin should differ exactly
    // one keyboard height
    if (!RDRKeyboardFrameChangeEqualsKeyboardHeight(beginFrame, endFrame)) {
        return;
    }
    
    // Make sure the keyboard is actually shown
    if (!RDRKeyboardIsFullyShown(endFrame)) {
        return;
    }
    
    // Make sure the keyboard was not already shown
    if (RDRKeyboardIsFullyShown(beginFrame)) {
        return;
    }
    
    [self _scrollViewAdaptInsetsToKeyboardFrame:endFrame];
    [self.scrollView rdr_scrollToBottomWithOptions:RDRAnimationOptionsForCurve(curve)
                                          duration:duration
                                   completionBlock:nil];
}

- (void)_keyboardWillChangeFrame:(NSNotification *)notification
{
    [self _keyboardWillHide:notification];
    
    [self _keyboardWillSwitch:notification];
}

    

- (void)_keyboardWillHide:(NSNotification *)notification
{
    [Appsee resume];
    
        _visible=FALSE;
        if (self.delegate && [self.delegate respondsToSelector:@selector(hide)])
                [self.delegate hide];
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    // When the user has lifted his or her finger, the
    // size of the end frame equals the size of the input view.
    CGRect inputViewBounds = self.inputView.bounds;
    if (!RDRKeyboardSizeEqualsInputViewSize(endFrame, inputViewBounds)) {
        return;
    }
    
    if (RDRKeyboardFrameChangeEqualsInputViewHeight(beginFrame,
                                                    endFrame,
                                                    inputViewBounds)){
        self.inputView.alpha = 0.0f;
    }
    
    UIView *view = self.window.rootViewController.view;
    CGRect beginFrameConverted = [view convertRect:beginFrame
                                          fromView:nil];
    
    CGRect viewRect = CGRectZero;
    viewRect.origin.y = view.bounds.size.height;
    viewRect.size = beginFrameConverted.size;
    
    CGRect windowRect = [self.window convertRect:viewRect fromView:view];
    [self _scrollViewAdaptInsetsToKeyboardFrame:windowRect];
    [self.scrollView rdr_scrollToBottomWithOptions:RDRAnimationOptionsForCurve(curve)
                                          duration:duration
                                   completionBlock:nil];
}

#pragma mark - Notification handler helpers

- (void)_keyboardWillSwitch:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    // Disregard false notification
    // This works around a bug in iOS
    CGRect inputViewBounds = self.inputView.bounds;
    if (RDRKeyboardSizeEqualsInputViewSize(endFrame, inputViewBounds)) {
        return;
    }
    
    if (RDRKeyboardSizeEqualsInputViewSize(beginFrame, inputViewBounds)) {
        return;
    }
    
    // Disregard when old and new keyboard origin differ
    // exactly one keyboard height
    if (RDRKeyboardFrameChangeEqualsKeyboardHeight(beginFrame, endFrame)) {
        return;
    }
    
    // Make sure keyboard is fully shown
    if (RDRKeyboardIsFullyHidden(endFrame)) {
        return;
    }
    
    
    [self _scrollViewAdaptInsetsToKeyboardFrame:endFrame];
    [self.scrollView rdr_scrollToBottomWithOptions:RDRAnimationOptionsForCurve(curve)
                                          duration:duration
                                   completionBlock:nil];
}

#pragma mark - Scrollview

- (void)_scrollViewAdaptInsetsToKeyboardFrame:(CGRect)keyboardFrame
{
    // Convert keyboard frame to view coordinates
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *view = window.rootViewController.view;
    CGRect convertedRect = [view convertRect:keyboardFrame
                                    fromView:nil];
    
    CGFloat keyboardHeight = convertedRect.size.height;
    CGFloat inputViewHeight = self.inputView.bounds.size.height;
    
    CGFloat bottomInset = keyboardHeight - inputViewHeight;
    bottomInset *= RDRKeyboardIsFullyHidden(keyboardFrame) ? 0 : 1;
    
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = bottomInset;
    self.scrollView.contentInset = contentInset;
    
    UIEdgeInsets scrollIndicatorInsets = self.scrollView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = bottomInset;
    self.scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    
}

#pragma mark - Input view

- (void)_updateInputViewFrameIfOrientationChanged:(CGRect)keyboardFrame
{
    // Check if orientation changed
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientation orientation = application.statusBarOrientation;
    
    if (_currentOrientation != RDRInterfaceOrientationUnknown &&
        _currentOrientation != orientation) {
        [self _updateInputViewFrameWithKeyboardFrame:keyboardFrame
                                         forceReload:YES];
    }
    
    _currentOrientation = orientation;
}

- (void)_updateInputViewFrameWithKeyboardFrame:(CGRect)keyboardFrame
                                   forceReload:(BOOL)reload
{
    

#ifdef DEBUG
    NSCAssert(!(CGRectEqualToRect(keyboardFrame, CGRectZero) &&
                self.inputView.superview == nil), nil);
#endif
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *view = window.rootViewController.view;
    CGRect windowKeyboardFrame = keyboardFrame;
    
    if (self.inputView.superview != nil) {
        windowKeyboardFrame = [window convertRect:self.inputView.superview.frame
                                         fromView:self.inputView.superview.superview];
    }
    
    // Convert keyboard frame to view coordinates
    CGRect viewKeyboardFrame = [view convertRect:windowKeyboardFrame
                                        fromView:nil];
    
    
    // Calculate max input view height
    CGFloat maxInputViewHeight = viewKeyboardFrame.origin.y -
    self.frame.origin.y - self.scrollView.contentInset.top;
    maxInputViewHeight += self.inputView.bounds.size.height;
    
    // Calculate the height the input view ideally
    // has based on its textview's content
    UITextView *textView = self.inputView.textView;
    CGFloat newInputViewHeight = RDRTextViewHeight(textView);
    newInputViewHeight += (2 * RDR_KEYBOARD_INPUT_VIEW_MARGIN_VERTICAL);
    newInputViewHeight = ceilf(newInputViewHeight);

    newInputViewHeight = MIN(maxInputViewHeight, newInputViewHeight);
    // If the new input view height equals the current,
    // nothing has to be changed
    if (self.inputView.bounds.size.height == newInputViewHeight) {
        return;
    }
    
    // Propagate the height change
    // Update the scrollview's frame
    CGRect scrollViewFrame = self.scrollView.frame;
    scrollViewFrame.size.height = self.frame.size.height - newInputViewHeight;
    self.scrollView.frame = scrollViewFrame;
    
    // The new input view height is different from the current.
    // Update the dummy input view's frame
    CGRect dummyInputViewFrame = self.dummyInputView.frame;
    dummyInputViewFrame.size.height = newInputViewHeight;
    dummyInputViewFrame.origin.y = self.frame.size.height - newInputViewHeight;
    NSLog(@"self.frame.size.height=%f",self.frame.size.height);
    NSLog(@"newInputViewHeight=%f",newInputViewHeight);
    self.dummyInputView.frame = dummyInputViewFrame;
    
    CGRect inputViewFrame = self.inputView.frame;
    inputViewFrame.size.height = newInputViewHeight;
    self.inputView.frame = inputViewFrame;
    
    
//    [self.scrollView rdr_scrollToBottomWithOptions:7
//                                          duration:0.3
//                                   completionBlock:nil];

    
    if (reload) {
//        [self.dummyInputView.textView setNeedsDisplay];
//        [self.dummyInputView.textView setNeedsLayout];
        [self.dummyInputView.textView becomeFirstResponder];
//        [self.dummyInputView.textView reloadInputViews];
//        [self.inputView.textView becomeFirstResponder];
    }
}

-(void)resize{
    
    if(_visible)
        [self _updateInputViewFrameWithKeyboardFrame:CGRectZero forceReload:NO];


}
#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (textView != self.inputView.textView) {
        return YES;
    }
    
    // Synchronize text between actual input view and
    // dummy input view.
    self.dummyInputView.textView.text = textView.text;
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self _updateInputViewFrameWithKeyboardFrame:CGRectZero
                                     forceReload:YES];
}

@end
