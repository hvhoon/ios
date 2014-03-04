//
// OFUtilities.h
//

#import <Foundation/Foundation.h>

NSString *OFMD5HexStringFromNSString(NSString *inStr);
NSString *OFEscapedURLStringFromNSString(NSString *inStr);
NSString *OFEscapedURLStringFromNSStringWithExtraEscapedChars(NSString *inStr, NSString *inEscChars);

NSString *OFGenerateUUIDString(void);

NSString *OFHMACSha1Base64(NSString *inKey, NSString *inMessage);
NSDictionary *OFExtractURLQueryParameter(NSString *inQuery);
BOOL OFExtractOAuthCallback(NSURL *inReceivedURL, NSURL *inBaseURL, NSString **outRequestToken, NSString **outVerifier);

