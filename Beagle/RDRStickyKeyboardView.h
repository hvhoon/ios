
#import <UIKit/UIKit.h>

#pragma mark - RDRKeyboardInputView
@protocol RDRKeyboardInputViewDelagte <NSObject>

@optional
-(void)updateInterestedStatus;
@end


@interface RDRKeyboardInputView : UIView

//@property (nonatomic, strong, readonly) UIButton *leftButton;
@property (nonatomic, strong, readonly) UIButton *rightButton;
@property (nonatomic, strong, readonly) UITextView *textView;
@property (nonatomic,weak)id <RDRKeyboardInputViewDelagte> delegate;
@end

#pragma mark - UIScrollView+RDRStickyKeyboardView

@interface UIScrollView (RDRStickyKeyboardView)

- (BOOL)rdr_isAtBottom;
- (void)rdr_scrollToBottomAnimated:(BOOL)animated
               withCompletionBlock:(void(^)(void))completionBlock;

- (void)rdr_scrollToBottomWithOptions:(UIViewAnimationOptions)options
                             duration:(CGFloat)duration
                      completionBlock:(void(^)(void))completionBlock;

@end

#pragma mark - RDRStickyKeyboardView

@interface RDRStickyKeyboardView : UIView

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) RDRKeyboardInputView *inputView;

// Designated initializer
- (instancetype)initWithScrollView:(UIScrollView *)scrollView;
- (void)reloadInputAccessoryView;

@end
