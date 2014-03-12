
#define __IPHONE_OS_VERSION_SOFT_MAX_REQUIRED __IPHONE_7_0

#import "SideTransitionController.h"
#import <QuartzCore/QuartzCore.h>
#import "TimeFilterView.h"
#import "CustomPickerView.h"
#import "LocationTableViewController.h"
#pragma mark - Categories



#pragma mark - Public Classes

@interface SideTransitionController ()<TimeFilterDelegate,UIScrollViewDelegate,CustomPickerViewDelegate,LocationFilterDelgate,UISearchBarDelegate>{
UIToolbar *_nativeBlurView;
    BOOL pageControlBeingUsed;
    int page;

}
@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, strong) UIImageView *blurView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) NSArray *images;
//@property (nonatomic, strong) NSArray *borderColors;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) NSMutableIndexSet *selectedIndices;


@end

static SideTransitionController *rn_frostedMenu;

@implementation SideTransitionController

+ (instancetype)visibleSidebar {
    return rn_frostedMenu;
}

- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices borderColors:(NSArray *)colors {
    if (self = [super init]) {
        _isSingleSelect = NO;
        _contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
        _contentView.alwaysBounceHorizontal = NO;
        _contentView.alwaysBounceVertical = YES;
        _contentView.clipsToBounds = NO;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.showsVerticalScrollIndicator = NO;
        
        _contentView.userInteractionEnabled=YES;
        _contentView.indicatorStyle=UIScrollViewIndicatorStyleBlack;
        
        
        // Enable or Disable scrolling
        
        _contentView.pagingEnabled = YES;
        _contentView.delegate = self;
        _contentView.bounces=NO;

        
        
        self.showFromRight=FALSE;
        _width = 320;
        _animationDuration = 0.3f;
        _itemSize = CGSizeMake(75, 75);
        _itemViews = [NSMutableArray array];
        _tintColor = [UIColor colorWithWhite:0.2 alpha:0.73];
        _borderWidth = 2;
        _itemBackgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
        
//        if (colors) {
//            NSAssert([colors count] == [images count], @"Border color count must match images count. If you want a blank border, use [UIColor clearColor].");
//        }
        
        _selectedIndices = [selectedIndices mutableCopy] ?: [NSMutableIndexSet indexSet];
//        _borderColors = colors;
        _images = images;
        
        [_images enumerateObjectsUsingBlock:^(NSNumber *image, NSUInteger idx, BOOL *stop) {
            
            if([image intValue]==1){
            
            for (int i = 0; i < 2; i++) {
//                CGRect frame;
//                frame.origin.x = 0;
//                frame.origin.y = _contentView.frame.size.height* i;
//                frame.size = _contentView.frame.size;
                
                switch (i) {
                    case 0:
                    {
                        TimeFilterView *filterView = [[TimeFilterView alloc]initWithFrame:CGRectMake(0, 0, 320, 568)];
                        filterView.delegate=self;
                        [_contentView addSubview:filterView];
                        
                    }
                        
                        
                    
                        break;
                    case 1:
                    {
                        

                        UIView *customPickerView = [[UIView alloc]initWithFrame:CGRectMake(0, 568, 320, 568)];
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomPickerView" owner:self options:nil];
                        CustomPickerView *view=[nib objectAtIndex:0];
                        view.frame=CGRectMake(0, 0, 320, 568);
                        view.userInteractionEnabled=YES;

                        customPickerView.userInteractionEnabled=YES;
                        [_contentView addSubview:customPickerView];
                        [customPickerView addSubview:view];
                        [view buildTheLogic];

                    }
                        break;
                        
                        
                    default:
                        break;
                }		
                
                
            }
                
              _contentView.contentSize = CGSizeMake(320,1136);
            }
            else if([image integerValue]==2){
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                

                LocationTableViewController *initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"locationScreen"];
                initialViewController.delegate=self;
                [self addChildViewController:initialViewController];
                
                initialViewController.view.frame = CGRectMake(0.0f, 0, 320.0f, 368.0f);

                
                [self.view addSubview:initialViewController.view];
//                [_contentView addSubview:initialViewController.view];


                
            }
            else{
                UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
                searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
                searchBarView.autoresizingMask = 0;
                searchBar.delegate = self;
                [searchBarView addSubview:searchBar];
                [self.navigationController setNavigationBarHidden:NO];
                self.navigationItem.titleView = searchBarView;
                [searchBar becomeFirstResponder];
            }
//            RNCalloutItemView *view = [[RNCalloutItemView alloc] init];
//            view.itemIndex = idx;
//            view.clipsToBounds = YES;
//            view.imageView.image = image;
//            [_contentView addSubview:view];
            
//            [_itemViews addObject:view];
            
//            if (_borderColors && _selectedIndices && [_selectedIndices containsIndex:idx]) {
//                UIColor *color = _borderColors[idx];
//                view.layer.borderColor = color.CGColor;
//            }
//            else {
//                view.layer.borderColor = [UIColor clearColor].CGColor;
//            }
        }];
        
        //self.contentView.contentSize = CGSizeMake(0, items * (self.itemSize.height + leftPadding) + leftPadding);
    }
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    
    //NSLog(@"scrollViewDidScroll");
    
    return;
    if (!pageControlBeingUsed) {
		
        // Switch the indicator when more than 50% of the previous/next view is visible
		CGFloat pageWidth = _contentView.frame.size.height;
        page = floor((_contentView.contentOffset.y - pageWidth / 2) / pageWidth) + 1;
        //NSLog(@"page=%d",page);
        
            switch (page) {
                case 0:
                {
//                    pageControlBeingUsed=TRUE;
//                    [_contentView scrollRectToVisible:CGRectMake(0, 0, 320, 568) animated:YES];
                }
                    break;
                case 1:
                {
                    pageControlBeingUsed=TRUE;
                    [self timeToScrollDown];

//                     [_contentView scrollRectToVisible:CGRectMake(0, 568, 320, 568) animated:YES];
                }
                    break;
                default:
                    break;
            }
        }
    
}

-(void)timeToScrollDown{
    
    
//        CGRect frame;
//        frame.origin.x = 0;
//        frame.origin.y = _contentView.frame.size.height;
//        frame.size = _contentView.frame.size;
    
    
    CGRect frame = _contentView.frame;
    frame.origin.x = 0;
    frame.origin.y =  frame.size.height * page;
    [_contentView scrollRectToVisible:frame animated:YES];

    
//        switch (page) {
//            case 0:
//            {
//                frame.origin.y = 568;
//            }
//                break;
//                
//            case 1:
//            {
//                frame.origin.y = 0;
//                
//            }
//                break;
//        }
//        
//        [_contentView scrollRectToVisible:frame animated:YES];
    
    //pageControlBeingUsed = YES;
    
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	pageControlBeingUsed = NO;
   //NSLog(@"scrollViewWillBeginDragging");
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	pageControlBeingUsed = NO;
    //NSLog(@"scrollViewDidEndDecelerating");
}

-(void) filterIndex:(NSInteger) index{
     [self.delegate sidebar:self didTapItemAtIndex:index];
}
- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices {
    return [self initWithImages:images selectedIndices:selectedIndices borderColors:nil];
}

- (instancetype)initWithImages:(NSArray *)images {
    return [self initWithImages:images selectedIndices:nil borderColors:nil];
}

- (instancetype)init {
    NSAssert(NO, @"Unable to create with plain init.");
    return nil;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentView];
//    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    [self.view addGestureRecognizer:self.tapGesture];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if ([self isViewLoaded] && self.view.window != nil) {
        self.view.alpha = 0;
//        UIImage *blurImage = [self.parentViewController.view rn_screenshot];
//        blurImage = [blurImage applyBlurWithRadius:5 tintColor:self.tintColor saturationDeltaFactor:1.8 maskImage:nil];
//        self.blurView.image = blurImage;
        self.view.alpha = 1;
        
        [self layoutSubviews];
    }
}

- (void)showInViewController:(UIViewController *)controller animated:(BOOL)animated {
    if (rn_frostedMenu != nil) {
        [rn_frostedMenu dismissAnimated:NO completion:nil];
    }
    
    if ([self.delegate respondsToSelector:@selector(sidebar:willShowOnScreenAnimated:)]) {
        [self.delegate sidebar:self willShowOnScreenAnimated:animated];
    }
    
    rn_frostedMenu = self;
    
//    UIImage *blurImage = [controller.view rn_screenshot];
//    blurImage = [blurImage applyBlurWithRadius:5 tintColor:self.tintColor saturationDeltaFactor:1.8 maskImage:nil];
    
    [self rn_addToParentViewController:controller callingAppearanceMethods:YES];
    self.view.frame = controller.view.bounds;
    
    CGFloat parentWidth = self.view.bounds.size.width;
    
    CGRect contentFrame = self.view.bounds;
    contentFrame.origin.x = _showFromRight ? parentWidth : -_width;
    contentFrame.size.width = _width;
    self.contentView.frame = contentFrame;
    
   // [self layoutItems];
    
    CGRect blurFrame = CGRectMake(_showFromRight ? self.view.bounds.size.width : 0, 0, 0, self.view.bounds.size.height);
    
//    self.blurView = [[UIImageView alloc] initWithImage:blurImage];
//    self.blurView.frame = blurFrame;
    self.blurView.contentMode = _showFromRight ? UIViewContentModeTopRight : UIViewContentModeTopLeft;
    self.blurView.clipsToBounds = YES;
//    [self.view insertSubview:self.blurView belowSubview:self.contentView];
    
    
    _nativeBlurView = [[UIToolbar alloc] initWithFrame:contentFrame];
    _nativeBlurView.alpha=0.95f;
    [self.view insertSubview:_nativeBlurView atIndex:0];
    
    
    
   // [[[[UIApplication sharedApplication] windows] objectAtIndex:[[[UIApplication sharedApplication]windows]count]-1]addSubview:self.view];
    
    contentFrame.origin.x = _showFromRight ? parentWidth - _width : 0;
    blurFrame.origin.x = contentFrame.origin.x;
    blurFrame.size.width = _width;
    
    void (^animations)() = ^{
        self.contentView.frame = contentFrame;
        self.blurView.frame = blurFrame;
        _nativeBlurView.frame=blurFrame;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished && [self.delegate respondsToSelector:@selector(sidebar:didShowOnScreenAnimated:)]) {
            [self.delegate sidebar:self didShowOnScreenAnimated:animated];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                              delay:0
                            options:kNilOptions
                         animations:animations
                         completion:completion];
    }
    else{
        animations();
        completion(YES);
    }
    
#if 0 
    CGFloat initDelay = 0.1f;
    SEL sdkSpringSelector = NSSelectorFromString(@"animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:");
    BOOL sdkHasSpringAnimation = [UIView respondsToSelector:sdkSpringSelector];
    
    [self.itemViews enumerateObjectsUsingBlock:^(RNCalloutItemView *view, NSUInteger idx, BOOL *stop) {
        view.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1);
        view.alpha = 0;
        view.originalBackgroundColor = self.itemBackgroundColor;
        view.layer.borderWidth = self.borderWidth;
        
        if (sdkHasSpringAnimation) {
            [self animateSpringWithView:view idx:idx initDelay:initDelay];
        }
        else {
            [self animateFauxBounceWithView:view idx:idx initDelay:initDelay];
        }
    }];
    
#endif
}

- (void)showAnimated:(BOOL)animated {
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (controller.presentedViewController != nil) {
        controller = controller.presentedViewController;
    }
    [self showInViewController:controller animated:animated];
}

- (void)show {
    [self showAnimated:YES];
}

#pragma mark - Dismiss

- (void)dismiss {
    [self dismissAnimated:YES completion:nil];
}

- (void)dismissAnimated:(BOOL)animated {
    [self dismissAnimated:animated completion:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    void (^completionBlock)(BOOL) = ^(BOOL finished){
        [self rn_removeFromParentViewControllerCallingAppearanceMethods:YES];
        
        if ([self.delegate respondsToSelector:@selector(sidebar:didDismissFromScreenAnimated:)]) {
            [self.delegate sidebar:self didDismissFromScreenAnimated:YES];
        }
		if (completion) {
			completion(finished);
		}
    };
    
    if ([self.delegate respondsToSelector:@selector(sidebar:willDismissFromScreenAnimated:)]) {
        [self.delegate sidebar:self willDismissFromScreenAnimated:YES];
    }
    
    if (animated) {
        CGFloat parentWidth = self.view.bounds.size.width;
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.x = self.showFromRight ? parentWidth : -_width;
        
        CGRect blurFrame = _nativeBlurView.frame;
        blurFrame.origin.x = self.showFromRight ? parentWidth : 0;
        blurFrame.size.width = 0;
        
        [UIView animateWithDuration:self.animationDuration
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.contentView.frame = contentFrame;
                             self.blurView.frame = blurFrame;
                             _nativeBlurView.frame=blurFrame;
                         }
                         completion:completionBlock];
    }
    else {
        completionBlock(YES);
    }
}

#pragma mark - Private

- (void)didTapItemAtIndex:(NSUInteger)index {
    BOOL didEnable = ! [self.selectedIndices containsIndex:index];
#if 0
    if (self.borderColors) {
        UIColor *stroke = self.borderColors[index];
        UIView *view = self.itemViews[index];
        
        if (didEnable) {
            if (_isSingleSelect){
                [self.selectedIndices removeAllIndexes];
                [self.itemViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    UIView *aView = (UIView *)obj;
                    [[aView layer] setBorderColor:[[UIColor clearColor] CGColor]];
                }];
            }
            view.layer.borderColor = stroke.CGColor;
            
            CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
            borderAnimation.fromValue = (id)[UIColor clearColor].CGColor;
            borderAnimation.toValue = (id)stroke.CGColor;
            borderAnimation.duration = 0.5f;
            [view.layer addAnimation:borderAnimation forKey:nil];
            
            [self.selectedIndices addIndex:index];
        }
        else {
            if (!_isSingleSelect){
                view.layer.borderColor = [UIColor clearColor].CGColor;
                [self.selectedIndices removeIndex:index];
            }
        }
        
        CGRect pathFrame = CGRectMake(-CGRectGetMidX(view.bounds), -CGRectGetMidY(view.bounds), view.bounds.size.width, view.bounds.size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:view.layer.cornerRadius];
        
        // accounts for left/right offset and contentOffset of scroll view
        CGPoint shapePosition = [self.view convertPoint:view.center fromView:self.contentView];
        
        CAShapeLayer *circleShape = [CAShapeLayer layer];
        circleShape.path = path.CGPath;
        circleShape.position = shapePosition;
        circleShape.fillColor = [UIColor clearColor].CGColor;
        circleShape.opacity = 0;
        circleShape.strokeColor = stroke.CGColor;
        circleShape.lineWidth = self.borderWidth;
        
        [self.view.layer addSublayer:circleShape];
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];
        
        CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        alphaAnimation.fromValue = @1;
        alphaAnimation.toValue = @0;
        
        CAAnimationGroup *animation = [CAAnimationGroup animation];
        animation.animations = @[scaleAnimation, alphaAnimation];
        animation.duration = 0.5f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [circleShape addAnimation:animation forKey:nil];
    }
#endif
    if ([self.delegate respondsToSelector:@selector(sidebar:didTapItemAtIndex:)]) {
        [self.delegate sidebar:self didTapItemAtIndex:index];
    }
    if ([self.delegate respondsToSelector:@selector(sidebar:didEnable:itemAtIndex:)]) {
        [self.delegate sidebar:self didEnable:didEnable itemAtIndex:index];
    }
}

- (void)layoutSubviews {
    CGFloat x = self.showFromRight ? self.parentViewController.view.bounds.size.width - _width : 0;
    self.contentView.frame = CGRectMake(x, 0, _width, self.parentViewController.view.bounds.size.height);
    self.blurView.frame = self.contentView.frame;
    _nativeBlurView.frame=self.contentView.frame;
    //[self layoutItems];
}
- (void)rn_addToParentViewController:(UIViewController *)parentViewController callingAppearanceMethods:(BOOL)callAppearanceMethods {
    if (self.parentViewController != nil) {
        [self rn_removeFromParentViewControllerCallingAppearanceMethods:callAppearanceMethods];
    }
    
    if (callAppearanceMethods) [self beginAppearanceTransition:YES animated:NO];
    [parentViewController addChildViewController:self];
    [parentViewController.view addSubview:self.view];
    [self didMoveToParentViewController:self];
    if (callAppearanceMethods) [self endAppearanceTransition];
}

- (void)rn_removeFromParentViewControllerCallingAppearanceMethods:(BOOL)callAppearanceMethods {
    if (callAppearanceMethods) [self beginAppearanceTransition:NO animated:NO];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    if (callAppearanceMethods) [self endAppearanceTransition];
}

@end
