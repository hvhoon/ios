
#import <UIKit/UIKit.h>

extern NSString *const CSStickyHeaderParallaxHeader;

@interface CSStickyHeaderFlowLayout : UICollectionViewFlowLayout

@property (nonatomic) CGSize parallaxHeaderReferenceSize;
@property (nonatomic) CGSize parallaxHeaderMinimumReferenceSize;
@property (nonatomic) BOOL parallaxHeaderAlwaysOnTop;
@property (nonatomic) BOOL disableStickyHeaders;

@end
