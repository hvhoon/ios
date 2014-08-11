
#import <UIKit/UIKit.h>

@interface CSStickyHeaderFlowLayoutAttributes : UICollectionViewLayoutAttributes

// 0 = minimized, 1 = fully expanded, > 1 = stretched
@property (nonatomic) CGFloat progressiveness;

@end
