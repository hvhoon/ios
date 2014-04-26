
#import <UIKit/UIKit.h>

#pragma mark - KeyboardInputView

@interface KeyboardInputView : UIView

@property (nonatomic, strong, readonly) UIButton *rightButton;
@property (nonatomic, strong, readonly) UITextView *textView;

@end

#pragma mark - UIScrollView+MessageKeyboardView

@interface UIScrollView (MessageKeyboardView)

- (BOOL)rdr_isAtBottom;
- (void)rdr_scrollToBottomAnimated:(BOOL)animated
               withCompletionBlock:(void(^)(void))completionBlock;

- (void)rdr_scrollToBottomWithOptions:(UIViewAnimationOptions)options
                             duration:(CGFloat)duration
                      completionBlock:(void(^)(void))completionBlock;

@end

#pragma mark - MessageKeyboardView

@interface MessageKeyboardView : UIView

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) KeyboardInputView *inputView;
@property (nonatomic, strong) KeyboardInputView *dummyInputView;
// Designated initializer
- (instancetype)initWithScrollView:(UIScrollView *)scrollView;
- (void)reloadInputAccessoryView;
- (void)textViewDidChange:(UITextView *)textView;

@end