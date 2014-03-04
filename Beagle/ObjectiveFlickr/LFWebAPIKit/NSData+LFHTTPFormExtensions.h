//
// NSData+LFHTTPFormExtensions.h
//

#import <Foundation/Foundation.h>

@interface NSData (LFHTTPFormExtensions)
+ (id)dataAsWWWURLEncodedFormFromDictionary:(NSDictionary *)formDictionary;
@end
