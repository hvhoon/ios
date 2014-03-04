//
// LFSiteReachability.h
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "LFHTTPRequest.h"

extern NSString *const LFSiteReachabilityConnectionTypeWiFi;
extern NSString *const LFSiteReachabilityConnectionTypeWWAN;

@class LFSiteReachability;

@protocol LFSiteReachabilityDelegate <NSObject>
- (void)reachability:(LFSiteReachability *)inReachability site:(NSURL *)inURL isAvailableOverConnectionType:(NSString *)inConnectionType;
- (void)reachability:(LFSiteReachability *)inReachability siteIsNotAvailable:(NSURL *)inURL;
@end

@interface LFSiteReachability : NSObject
{
    id<LFSiteReachabilityDelegate> delegate;    
    NSURL *siteURL;
    SCNetworkReachabilityRef reachability;
    LFHTTPRequest *siteRequest;
    NSTimer *timeoutTimer;	
	id lastCheckStatus;
}
- (void)startChecking;
- (void)stopChecking;
- (BOOL)isChecking;

// When networkConnectivityExists returns YES, it simply means network interface is available
// (e.g. WiFi not disabled, has 3G, etc.); that is, the device has the "potential" to connect,
// but that does not mean that an HTTP request will succeed, for various reasons--such as 
// the IP is not yet obtained; the interface is not yet fully "up", base station or WiFi hasn't
// assigned a valid IP yet, etc. To read this way: If this method returns NO, it means
// "forget about network, it doesn't exist at all"
- (BOOL)networkConnectivityExists;	

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4 
- (id<LFSiteReachabilityDelegate>)delegate;
- (NSURL*)siteURL;
- (NSTimeInterval)timeoutInterval;
#else
@property (assign, nonatomic) id<LFSiteReachabilityDelegate> delegate;
@property (retain, nonatomic) NSURL *siteURL;
@property (nonatomic) NSTimeInterval timeoutInterval;
#endif
@end
