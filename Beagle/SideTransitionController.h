
#import <UIKit/UIKit.h>

@class SideTransitionController;

@protocol SideTransitionControllerDelegate <NSObject>
@optional
- (void)sidebar:(SideTransitionController *)sidebar willShowOnScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(SideTransitionController *)sidebar didShowOnScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(SideTransitionController *)sidebar willDismissFromScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(SideTransitionController *)sidebar didDismissFromScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(SideTransitionController *)sidebar didTapItemAtIndex:(NSUInteger)index;
- (void)sidebar:(SideTransitionController *)sidebar didEnable:(BOOL)itemEnabled itemAtIndex:(NSUInteger)index;
@end

@interface SideTransitionController : UIViewController

+ (instancetype)visibleSidebar;

@property (nonatomic, assign) CGFloat width;

@property (nonatomic, strong, readonly) UIScrollView *contentView;

@property (nonatomic, assign) BOOL showFromRight;

@property (nonatomic, assign) CGFloat animationDuration;

@property (nonatomic, assign) CGSize itemSize;

@property (nonatomic, strong) UIColor *tintColor;

@property (nonatomic, strong) UIColor *itemBackgroundColor;

@property (nonatomic, assign) NSUInteger borderWidth;

@property (nonatomic, assign) BOOL isSingleSelect;

// An optional delegate to respond to interaction events
@property (nonatomic, weak) id <SideTransitionControllerDelegate> delegate;

- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices borderColors:(NSArray *)colors;
- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices;
- (instancetype)initWithImages:(NSArray *)images;

- (void)show;
- (void)showAnimated:(BOOL)animated;
- (void)showInViewController:(UIViewController *)controller animated:(BOOL)animated;

- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end
