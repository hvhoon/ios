//
// ObjectiveFlickr.m
//

#import "ObjectiveFlickr.h"
#import "OFUtilities.h"
#import "OFXMLMapper.h"

NSString *const OFFlickrSmallSquareSize = @"s";
NSString *const OFFlickrThumbnailSize = @"t";
NSString *const OFFlickrSmallSize = @"m";
NSString *const OFFlickrMediumSize = nil;
NSString *const OFFlickrSmall320Size = @"n";
NSString *const OFFlickrMedium640Size = @"z";
NSString *const OFFlickrMedium800Size = @"c";

NSString *const OFFlickrLargeSize = @"b";

NSString *const OFFlickrReadPermission = @"read";
NSString *const OFFlickrWritePermission = @"write";
NSString *const OFFlickrDeletePermission = @"delete";

NSString *const OFFlickrUploadTempFilenamePrefix = @"org.lukhnos.ObjectiveFlickr.upload";
NSString *const OFFlickrAPIReturnedErrorDomain = @"com.flickr";
NSString *const OFFlickrAPIRequestErrorDomain = @"org.lukhnos.ObjectiveFlickr";

NSString *const OFFlickrAPIRequestOAuthErrorUserInfoKey = @"OAuthError";
NSString *const OFFetchOAuthRequestTokenSession = @"FetchOAuthRequestToken";
NSString *const OFFetchOAuthAccessTokenSession = @"FetchOAuthAccessToken";

static NSString *const kEscapeChars = @"`~!@#$^&*()=+[]\\{}|;':\",/<>?";


// compatibility typedefs
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
typedef unsigned int NSUInteger;
#endif

@interface OFFlickrAPIContext (PrivateMethods)
- (NSArray *)signedArgumentComponentsFromArguments:(NSDictionary *)inArguments useURIEscape:(BOOL)inUseEscape;
- (NSString *)signedQueryFromArguments:(NSDictionary *)inArguments tagType:(NSInteger)tagType;
@end

#define kDefaultFlickrRESTAPIEndpoint		@"https://api.flickr.com/services/rest/"
#define kDefaultFlickrPhotoSource			@"https://static.flickr.com/"
#define kDefaultFlickrPhotoWebPageSource	@"https://www.flickr.com/photos/"
#define kDefaultFlickrAuthEndpoint			@"https://flickr.com/services/auth/"
#define kDefaultFlickrUploadEndpoint		@"https://api.flickr.com/services/upload/"

@implementation OFFlickrAPIContext
- (void)dealloc
{
    [key release];
    [sharedSecret release];
    [authToken release];
    
    [RESTAPIEndpoint release];
	[photoSource release];
	[photoWebPageSource release];
	[authEndpoint release];
    [uploadEndpoint release];
    
    [oauthToken release];
    [oauthTokenSecret release];
    
    [super dealloc];
}

- (id)initWithAPIKey:(NSString *)inKey sharedSecret:(NSString *)inSharedSecret
{
    if ((self = [super init])) {
        key = [inKey copy];
        sharedSecret = [inSharedSecret copy];
        
        RESTAPIEndpoint = kDefaultFlickrRESTAPIEndpoint;
		photoSource = kDefaultFlickrPhotoSource;
		photoWebPageSource = kDefaultFlickrPhotoWebPageSource;
		authEndpoint = kDefaultFlickrAuthEndpoint;
        uploadEndpoint = kDefaultFlickrUploadEndpoint;
    }
    return self;
}

- (void)setAuthToken:(NSString *)inAuthToken
{
    NSString *tmp = authToken;
    authToken = [inAuthToken copy];
    [tmp release];
}

- (NSString *)authToken
{
    return authToken;
}

- (NSURL *)userAuthorizationURLWithRequestToken:(NSString *)inRequestToken requestedPermission:(NSString *)inPermission
{
    NSString *perms = @"";
    
    if ([inPermission length] > 0) {
        perms = [NSString stringWithFormat:@"&perms=%@", inPermission];
    }
    
    NSString *URLString = [NSString stringWithFormat:@"https://www.flickr.com/services/oauth/authorize?oauth_token=%@%@", inRequestToken, perms];
    return [NSURL URLWithString:URLString];
}

- (NSURL *)photoSourceURLFromDictionary:(NSDictionary *)inDictionary size:(NSString *)inSizeModifier
{
	// https://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}_[mstb].jpg
	// https://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg
	
	NSString *farm = [inDictionary objectForKey:@"farm"];
	NSString *photoID = [inDictionary objectForKey:@"id"];
	NSString *secret = [inDictionary objectForKey:@"secret"];
	NSString *server = [inDictionary objectForKey:@"server"];
	
	NSMutableString *URLString = [NSMutableString stringWithString:@"https://"];
	if ([farm length]) {
		[URLString appendFormat:@"farm%@.", farm];
	}
	
	// skips "https://"
	NSAssert([server length], @"Must have server attribute");
	NSAssert([photoID length], @"Must have id attribute");
	NSAssert([secret length], @"Must have secret attribute");
	[URLString appendString:[photoSource substringFromIndex:8]];
	[URLString appendFormat:@"%@/%@_%@", server, photoID, secret];
	
	if ([inSizeModifier length]) {
		[URLString appendFormat:@"_%@.jpg", inSizeModifier];
	}
	else {
		[URLString appendString:@".jpg"];
	}
	
	return [NSURL URLWithString:URLString];
}

- (NSURL *)photoWebPageURLFromDictionary:(NSDictionary *)inDictionary
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@", photoWebPageSource, [inDictionary objectForKey:@"owner"], [inDictionary objectForKey:@"id"]]];
}

- (NSURL *)loginURLFromFrobDictionary:(NSDictionary *)inFrob requestedPermission:(NSString *)inPermission
{
	NSString *frob = [[inFrob objectForKey:@"frob"] objectForKey:OFXMLTextContentKey];
    NSDictionary *argDict = [frob length] ? [NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", inPermission, @"perms", nil] : [NSDictionary dictionaryWithObjectsAndKeys:inPermission, @"perms", nil];
	NSString *URLString = [NSString stringWithFormat:@"%@?%@", authEndpoint, [self signedQueryFromArguments:argDict tagType:1]];
	return [NSURL URLWithString:URLString];
}

- (void)setRESTAPIEndpoint:(NSString *)inEndpoint
{
    NSString *tmp = RESTAPIEndpoint;
    RESTAPIEndpoint = [inEndpoint copy];
    [tmp release];
}

- (NSString *)RESTAPIEndpoint
{
    return RESTAPIEndpoint;
}

- (void)setPhotoSource:(NSString *)inSource
{
	if (![inSource hasPrefix:@"https://"]) {
		return;
	}
	
	NSString *tmp = photoSource;
	photoSource = [inSource copy];
	[tmp release];
}

- (NSString *)photoSource
{
	return photoSource;
}

- (void)setPhotoWebPageSource:(NSString *)inSource
{
	if (![inSource hasPrefix:@"https://"]) {
		return;
	}
	
	NSString *tmp = photoWebPageSource;
	photoWebPageSource = [inSource copy];
	[tmp release];
}

- (NSString *)photoWebPageSource
{
	return photoWebPageSource;
}

- (void)setAuthEndpoint:(NSString *)inEndpoint
{
	NSString *tmp = authEndpoint;
	authEndpoint = [inEndpoint copy];
	[tmp release];
}

- (NSString *)authEndpoint
{
	return authEndpoint;
}

- (void)setUploadEndpoint:(NSString *)inEndpoint
{
    NSString *tmp = uploadEndpoint;
    uploadEndpoint = [inEndpoint copy];
    [tmp release];
}

- (NSString *)uploadEndpoint
{
    return uploadEndpoint;
}

- (void)setOAuthToken:(NSString *)inToken
{
    NSString *tmp = oauthToken;
    oauthToken = [inToken copy];
    [tmp release];    
}

- (NSString *)OAuthToken
{
    return oauthToken;
}

- (void)setOAuthTokenSecret:(NSString *)inSecret;
{
    NSString *tmp = oauthTokenSecret;
    oauthTokenSecret = [inSecret copy];
    [tmp release];    
}

- (NSString *)OAuthTokenSecret
{
    return oauthTokenSecret;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
@synthesize key;
@synthesize sharedSecret;
#endif
@end

@implementation OFFlickrAPIContext (PrivateMethods)
- (NSArray *)signedArgumentComponentsFromArguments:(NSDictionary *)inArguments useURIEscape:(BOOL)inUseEscape
{
    NSMutableDictionary *newArgs = [NSMutableDictionary dictionaryWithDictionary:inArguments];
	if ([key length]) {
		[newArgs setObject:key forKey:@"api_key"];
	}
	
	if ([authToken length]) {
		[newArgs setObject:authToken forKey:@"auth_token"];
	}
	
	// combine the args
	NSMutableArray *argArray = [NSMutableArray array];
	NSMutableString *sigString = [NSMutableString stringWithString:[sharedSecret length] ? sharedSecret : @""];
	NSArray *sortedArgs = [[newArgs allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSEnumerator *argEnumerator = [sortedArgs objectEnumerator];
	NSString *nextKey;
	while ((nextKey = [argEnumerator nextObject])) {
		NSString *value = [newArgs objectForKey:nextKey];
		[sigString appendFormat:@"%@%@", nextKey, value];
		[argArray addObject:[NSArray arrayWithObjects:nextKey, (inUseEscape ? OFEscapedURLStringFromNSString(value) : value), nil]];
	}
	
	NSString *signature = OFMD5HexStringFromNSString(sigString);    
    [argArray addObject:[NSArray arrayWithObjects:@"api_sig", signature, nil]];
	return argArray;
}


- (NSString *)signedQueryFromArguments:(NSDictionary *)inArguments tagType:(NSInteger)tagType
{
    NSArray *argComponents = [self signedArgumentComponentsFromArguments:inArguments useURIEscape:YES];
    if(tagType==0){
    NSMutableArray *testArray=[NSMutableArray arrayWithArray:argComponents];
    [testArray removeLastObject];
    argComponents=[NSArray arrayWithArray:testArray];
    }
    NSMutableArray *args = [NSMutableArray array];
    NSEnumerator *componentEnumerator = [argComponents objectEnumerator];
    NSArray *nextArg;
    while ((nextArg = [componentEnumerator nextObject])) {
        [args addObject:[nextArg componentsJoinedByString:@"="]];
    }
    
    return [args componentsJoinedByString:@"&"];
}

- (NSDictionary *)signedOAuthHTTPQueryArguments:(NSDictionary *)inArguments baseURL:(NSURL *)inURL method:(NSString *)inMethod
{
    NSMutableDictionary *newArgs = [NSMutableDictionary dictionaryWithDictionary:inArguments];
    [newArgs setObject:[OFGenerateUUIDString() substringToIndex:8] forKey:@"oauth_nonce"];
    [newArgs setObject:[NSString stringWithFormat:@"%lu", (long)[[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [newArgs setObject:@"1.0" forKey:@"oauth_version"];
    [newArgs setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [newArgs setObject:key forKey:@"oauth_consumer_key"];
    
    if (![inArguments objectForKey:@"oauth_token"] && oauthToken) {
        [newArgs setObject:oauthToken forKey:@"oauth_token"];
    }
    
    NSString *signatureKey = nil;
    if (oauthTokenSecret) {
        signatureKey = [NSString stringWithFormat:@"%@&%@", sharedSecret, oauthTokenSecret];
    }
    else {
        signatureKey = [NSString stringWithFormat:@"%@&", sharedSecret];
    }
    
    NSMutableString *baseString = [NSMutableString string];
    [baseString appendString:inMethod];
    [baseString appendString:@"&"];
    [baseString appendString:OFEscapedURLStringFromNSStringWithExtraEscapedChars([inURL absoluteString], kEscapeChars)];
    
    NSArray *sortedArgKeys = [[newArgs allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [baseString appendString:@"&"];
    
    NSMutableArray *baseStrArgs = [NSMutableArray array];
    NSEnumerator *kenum = [sortedArgKeys objectEnumerator];
    NSString *k;
    while ((k = [kenum nextObject]) != nil) {
        [baseStrArgs addObject:[NSString stringWithFormat:@"%@=%@", k, OFEscapedURLStringFromNSStringWithExtraEscapedChars([newArgs objectForKey:k], kEscapeChars)]];
    }
    
    [baseString appendString:OFEscapedURLStringFromNSStringWithExtraEscapedChars([baseStrArgs componentsJoinedByString:@"&"], kEscapeChars)];
    
    NSString *signature = OFHMACSha1Base64(signatureKey, baseString);
    
    [newArgs setObject:signature forKey:@"oauth_signature"];
    return newArgs;
}

- (NSURL *)oauthURLFromBaseURL:(NSURL *)inURL method:(NSString *)inMethod arguments:(NSDictionary *)inArguments
{
    NSDictionary *newArgs = [self signedOAuthHTTPQueryArguments:inArguments baseURL:inURL method:inMethod];
    NSMutableArray *queryArray = [NSMutableArray array];

    NSEnumerator *kenum = [newArgs keyEnumerator];
    NSString *k;
    while ((k = [kenum nextObject]) != nil) {
        [queryArray addObject:[NSString stringWithFormat:@"%@=%@", k, OFEscapedURLStringFromNSStringWithExtraEscapedChars([newArgs objectForKey:k], kEscapeChars)]];
    }
    
    
    NSString *newURLStringWithQuery = [NSString stringWithFormat:@"%@?%@", [inURL absoluteString], [queryArray componentsJoinedByString:@"&"]];
    
    return [NSURL URLWithString:newURLStringWithQuery];
}
@end

@interface OFFlickrAPIRequest (PrivateMethods)
- (void)cleanUpTempFile;
@end            

@implementation OFFlickrAPIRequest
- (void)dealloc
{
    [context release];
    HTTPRequest.delegate = nil;
    [HTTPRequest release];
    [sessionInfo release];
    
    [self cleanUpTempFile];
    
    [super dealloc];
}

- (id)initWithAPIContext:(OFFlickrAPIContext *)inContext
{
    if ((self = [super init])) {
        context = [inContext retain];
        
        HTTPRequest = [[LFHTTPRequest alloc] init];
        [HTTPRequest setDelegate:self];
    }
    
    return self;
}

- (OFFlickrAPIContext *)context
{
	return context;
}

- (OFFlickrAPIRequestDelegateType)delegate
{
    return delegate;
}

- (void)setDelegate:(OFFlickrAPIRequestDelegateType)inDelegate
{
    delegate = inDelegate;
}

- (id)sessionInfo
{
    return [[sessionInfo retain] autorelease];
}

- (void)setSessionInfo:(id)inInfo
{
    id tmp = sessionInfo;
    sessionInfo = [inInfo retain];
    [tmp release];
}

- (NSTimeInterval)requestTimeoutInterval
{
    return [HTTPRequest timeoutInterval];
}

- (void)setRequestTimeoutInterval:(NSTimeInterval)inTimeInterval
{
    [HTTPRequest setTimeoutInterval:inTimeInterval];
}

- (BOOL)isRunning
{
    return [HTTPRequest isRunning];
}

- (void)cancel
{
    [HTTPRequest cancelWithoutDelegateMessage];
    [self cleanUpTempFile];
}

- (BOOL)fetchOAuthRequestTokenWithCallbackURL:(NSURL *)inCallbackURL
{
    if ([HTTPRequest isRunning]) {
        return NO;
    }

    NSDictionary *paramsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[inCallbackURL absoluteString], @"oauth_callback", nil];
    NSURL *requestURL = [context oauthURLFromBaseURL:[NSURL URLWithString:@"https://www.flickr.com/services/oauth/request_token"] method:LFHTTPRequestGETMethod arguments:paramsDictionary];
    [HTTPRequest setSessionInfo:OFFetchOAuthRequestTokenSession];
    [HTTPRequest setContentType:nil];
    return [HTTPRequest performMethod:LFHTTPRequestGETMethod onURL:requestURL withData:nil];
}

- (BOOL)fetchOAuthAccessTokenWithRequestToken:(NSString *)inRequestToken verifier:(NSString *)inVerifier
{
    if ([HTTPRequest isRunning]) {
        return NO;
    }
    NSDictionary *paramsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:inRequestToken, @"oauth_token", inVerifier, @"oauth_verifier", nil];
    NSURL *requestURL = [context oauthURLFromBaseURL:[NSURL URLWithString:@"https://www.flickr.com/services/oauth/access_token"] method:LFHTTPRequestGETMethod arguments:paramsDictionary];
    [HTTPRequest setSessionInfo:OFFetchOAuthAccessTokenSession];
    [HTTPRequest setContentType:nil];
    return [HTTPRequest performMethod:LFHTTPRequestGETMethod onURL:requestURL withData:nil];
}

- (BOOL)callAPIMethodWithGET:(NSString *)inMethodName arguments:(NSDictionary *)inArguments tag:(NSInteger)tag
{
    if ([HTTPRequest isRunning]) {
        return NO;
    }
    
    // combine the parameters 
	NSMutableDictionary *newArgs = inArguments ? [NSMutableDictionary dictionaryWithDictionary:inArguments] : [NSMutableDictionary dictionary];
	[newArgs setObject:inMethodName forKey:@"method"];	

    NSURL *requestURL = nil;
    if ([context OAuthToken] && [context OAuthTokenSecret]) {
        requestURL = [context oauthURLFromBaseURL:[NSURL URLWithString:[context RESTAPIEndpoint]] method:LFHTTPRequestGETMethod arguments:newArgs];
    }
    else {
        NSString *query = [context signedQueryFromArguments:newArgs tagType:tag];
        NSString *URLString = [NSString stringWithFormat:@"%@?%@", [context RESTAPIEndpoint], query];
        requestURL = [NSURL URLWithString:URLString];
    }
    
    NSLog(@"requestUrl=%@",requestURL);
    if (requestURL) {
        [HTTPRequest setContentType:nil];
        return [HTTPRequest performMethod:LFHTTPRequestGETMethod onURL:requestURL withData:nil];        
    }
    return NO;
}

static NSData *NSDataFromOAuthPreferredWebForm(NSDictionary *formDictionary)
{
    NSMutableString *combinedDataString = [NSMutableString string];
    NSEnumerator *enumerator = [formDictionary keyEnumerator];
    
    id key = [enumerator nextObject];
    if (key) {
        id value = [formDictionary objectForKey:key];
        [combinedDataString appendString:[NSString stringWithFormat:@"%@=%@", 
                                          [(NSString*)key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                          OFEscapedURLStringFromNSStringWithExtraEscapedChars(value, kEscapeChars)]];
        
		while ((key = [enumerator nextObject])) {
			value = [formDictionary objectForKey:key];
			[combinedDataString appendString:[NSString stringWithFormat:@"&%@=%@", [(NSString*)key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], OFEscapedURLStringFromNSStringWithExtraEscapedChars(value, kEscapeChars)]];
		}
	}
    
    return [combinedDataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];    
}

- (BOOL)callAPIMethodWithPOST:(NSString *)inMethodName arguments:(NSDictionary *)inArguments
{
    if ([HTTPRequest isRunning]) {
        return NO;
    }
    
    // combine the parameters 
	NSMutableDictionary *newArgs = inArguments ? [NSMutableDictionary dictionaryWithDictionary:inArguments] : [NSMutableDictionary dictionary];
	[newArgs setObject:inMethodName forKey:@"method"];	
    
    
    NSData *postData = nil;
    
    if ([context OAuthToken] && [context OAuthTokenSecret]) {
        NSDictionary *signedArgs = [context signedOAuthHTTPQueryArguments:newArgs baseURL:[NSURL URLWithString:[context RESTAPIEndpoint]] method:LFHTTPRequestPOSTMethod];
        
        postData = NSDataFromOAuthPreferredWebForm(signedArgs);
    }
    else {    
        NSString *arguments = [context signedQueryFromArguments:newArgs tagType:1];
        postData = [arguments dataUsingEncoding:NSUTF8StringEncoding];
    }
    
	[HTTPRequest setContentType:LFHTTPRequestWWWFormURLEncodedContentType];
	return [HTTPRequest performMethod:LFHTTPRequestPOSTMethod onURL:[NSURL URLWithString:[context RESTAPIEndpoint]] withData:postData];
}

- (BOOL)uploadImageStream:(NSInputStream *)inImageStream suggestedFilename:(NSString *)inFilename MIMEType:(NSString *)inType arguments:(NSDictionary *)inArguments
{
    if ([HTTPRequest isRunning]) {
        return NO;
    }
    
    // get the api_sig
    NSArray *argComponents = nil;
    
    if ([context OAuthToken] && [context OAuthTokenSecret]) {
        NSMutableArray *newArgsComps = [NSMutableArray array];
        NSDictionary *signedArgs = [context signedOAuthHTTPQueryArguments:(inArguments ? inArguments : [NSDictionary dictionary]) baseURL:[NSURL URLWithString:[context uploadEndpoint]] method:LFHTTPRequestPOSTMethod];
        
        NSEnumerator *keyEnum = [signedArgs keyEnumerator];
        NSString *key;
        while ((key = [keyEnum nextObject]) != nil) {
            NSString *value = [signedArgs valueForKey:key];
            [newArgsComps addObject:[NSArray arrayWithObjects:key, value, nil]];
        }
        
        argComponents = newArgsComps;
    }
    else if ([[context authToken] length] > 0) {
        argComponents = [[self context] signedArgumentComponentsFromArguments:(inArguments ? inArguments : [NSDictionary dictionary]) useURIEscape:NO];
    }
    else {
        return NO;
    }
    
    NSString *separator = OFGenerateUUIDString();
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", separator];
    
    // build the multipart form
    NSMutableString *multipartBegin = [NSMutableString string];
    NSMutableString *multipartEnd = [NSMutableString string];
    
    NSEnumerator *componentEnumerator = [argComponents objectEnumerator];
    NSArray *nextArgComponent;
    while ((nextArgComponent = [componentEnumerator nextObject])) {        
        [multipartBegin appendFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", separator, [nextArgComponent objectAtIndex:0], [nextArgComponent objectAtIndex:1]];
    }

    // add filename, if nil, generate a UUID
    [multipartBegin appendFormat:@"--%@\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"%@\"\r\n", separator, [inFilename length] ? inFilename : OFGenerateUUIDString()];
    [multipartBegin appendFormat:@"Content-Type: %@\r\n\r\n", inType];
        
    [multipartEnd appendFormat:@"\r\n--%@--", separator];
    
    
    // now we have everything, create a temp file for this purpose; although UUID is inferior to 
    [self cleanUpTempFile];
	
    uploadTempFilename = [[NSTemporaryDirectory() stringByAppendingFormat:@"%@.%@", OFFlickrUploadTempFilenamePrefix, OFGenerateUUIDString()] retain];
    
    // create the write stream
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:uploadTempFilename append:NO];
    [outputStream open];
    
    const char *UTF8String;
    size_t writeLength;
    UTF8String = [multipartBegin UTF8String];
    writeLength = strlen(UTF8String);
	
	size_t __unused actualWrittenLength;
	actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
    NSAssert(actualWrittenLength == writeLength, @"Must write multipartBegin");
	
    // open the input stream
    const size_t bufferSize = 65536;
    size_t readSize = 0;
    uint8_t *buffer = (uint8_t *)calloc(1, bufferSize);
    NSAssert(buffer, @"Must have enough memory for copy buffer");

    [inImageStream open];
    while ([inImageStream hasBytesAvailable]) {
        if (!(readSize = [inImageStream read:buffer maxLength:bufferSize])) {
            break;
        }
        
		
		size_t __unused actualWrittenLength;
		actualWrittenLength = [outputStream write:buffer maxLength:readSize];
        NSAssert (actualWrittenLength == readSize, @"Must completes the writing");
    }
    
    [inImageStream close];
    free(buffer);
    
    
    UTF8String = [multipartEnd UTF8String];
    writeLength = strlen(UTF8String);
	actualWrittenLength = [outputStream write:(uint8_t *)UTF8String maxLength:writeLength];
    NSAssert(actualWrittenLength == writeLength, @"Must write multipartBegin");
    [outputStream close];
    
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4                
    NSDictionary *fileInfo = [[NSFileManager defaultManager] fileAttributesAtPath:uploadTempFilename traverseLink:YES];
    NSAssert(fileInfo, @"Must have upload temp file");
#else
    NSError *error = nil;
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:uploadTempFilename error:&error];
    NSAssert(fileInfo && !error, @"Must have upload temp file");
#endif
    NSNumber *fileSizeNumber = [fileInfo objectForKey:NSFileSize];
    NSUInteger fileSize = 0;

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4                
    fileSize = [fileSizeNumber intValue];
#else
    if ([fileSizeNumber respondsToSelector:@selector(integerValue)]) {
        fileSize = [fileSizeNumber integerValue];                    
    }
    else {
        fileSize = [fileSizeNumber intValue];                    
    }                
#endif
    
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	
    [HTTPRequest setContentType:contentType];
    return [HTTPRequest performMethod:LFHTTPRequestPOSTMethod onURL:[NSURL URLWithString:[context uploadEndpoint]] withInputStream:inputStream knownContentSize:fileSize];
}

#pragma mark LFHTTPRequest delegate methods
- (void)httpRequestDidComplete:(LFHTTPRequest *)request
{
    if ([request sessionInfo] == OFFetchOAuthRequestTokenSession) {
        [request setSessionInfo:nil];
        
        NSString *response = [[[NSString alloc] initWithData:[request receivedData] encoding:NSUTF8StringEncoding] autorelease];

        NSDictionary *params = OFExtractURLQueryParameter(response);
        NSString *oat = [params objectForKey:@"oauth_token"];
        NSString *oats = [params objectForKey:@"oauth_token_secret"];
        if (!oat || !oats) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:response, OFFlickrAPIRequestOAuthErrorUserInfoKey, nil];
            NSError *error = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestOAuthError userInfo:userInfo];            
            [delegate flickrAPIRequest:self didFailWithError:error];                
        }
        else {
            NSAssert([delegate respondsToSelector:@selector(flickrAPIRequest:didObtainOAuthRequestToken:secret:)], @"Delegate must implement the method -flickrAPIRequest:didObtainOAuthRequestToken:secret: to handle OAuth request token callback");
            
            [delegate flickrAPIRequest:self didObtainOAuthRequestToken:oat secret:oats];
        }
    }
    else if ([request sessionInfo] == OFFetchOAuthAccessTokenSession) {
        [request setSessionInfo:nil];

        NSString *response = [[[NSString alloc] initWithData:[request receivedData] encoding:NSUTF8StringEncoding] autorelease];
        NSDictionary *params = OFExtractURLQueryParameter(response);
        
        NSString *fn = [params objectForKey:@"fullname"];
        NSString *oat = [params objectForKey:@"oauth_token"];
        NSString *oats = [params objectForKey:@"oauth_token_secret"];
        NSString *nsid = [params objectForKey:@"user_nsid"];
        NSString *un = [params objectForKey:@"username"];
        if (!fn || !oat || !oats || !nsid || !un) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:response, OFFlickrAPIRequestOAuthErrorUserInfoKey, nil];
            NSError *error = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestOAuthError userInfo:userInfo];            
            [delegate flickrAPIRequest:self didFailWithError:error];            
        }
        
        else {
            NSAssert([delegate respondsToSelector:@selector(flickrAPIRequest:didObtainOAuthAccessToken:secret:userFullName:userName:userNSID:)], @"Delegate must implement -flickrAPIRequest:didObtainOAuthAccessToken:secret:userFullName:userName:userNSID: to handle the obtained access token");
            
            [delegate flickrAPIRequest:self didObtainOAuthAccessToken:oat secret:oats userFullName:fn userName:un userNSID:nsid];
        }
    }
    else {
        NSDictionary *responseDictionary = [OFXMLMapper dictionaryMappedFromXMLData:[request receivedData]];	
        NSDictionary *rsp = [responseDictionary objectForKey:@"rsp"];
        NSString *stat = [rsp objectForKey:@"stat"];
        
        // this also fails when (responseDictionary, rsp, stat) == nil, so it's a guranteed way of checking the result
        if (![stat isEqualToString:@"ok"]) {
            NSDictionary *err = [rsp objectForKey:@"err"];
            NSString *code = [err objectForKey:@"code"];
            NSString *msg = [err objectForKey:@"msg"];
        
            NSError *toDelegateError;
            if ([code length]) {
                // intValue for 10.4-compatibility
                toDelegateError = [NSError errorWithDomain:OFFlickrAPIReturnedErrorDomain code:[code intValue] userInfo:[msg length] ? [NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedFailureReasonErrorKey, nil] : nil];				
            }
            else {
                toDelegateError = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestFaultyXMLResponseError userInfo:nil];
            }
                
            if ([delegate respondsToSelector:@selector(flickrAPIRequest:didFailWithError:)]) {
                [delegate flickrAPIRequest:self didFailWithError:toDelegateError];        
            }
            return;
        }

        [self cleanUpTempFile];
        if ([delegate respondsToSelector:@selector(flickrAPIRequest:didCompleteWithResponse:)]) {
            [delegate flickrAPIRequest:self didCompleteWithResponse:rsp];
        }    
    }
}

- (void)httpRequest:(LFHTTPRequest *)request didFailWithError:(NSString *)error
{
    NSError *toDelegateError = nil;
    if ([error isEqualToString:LFHTTPRequestConnectionError]) {
		toDelegateError = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestConnectionError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Network connection error", NSLocalizedFailureReasonErrorKey, nil]];
    }
    else if ([error isEqualToString:LFHTTPRequestTimeoutError]) {
		toDelegateError = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestTimeoutError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Request timeout", NSLocalizedFailureReasonErrorKey, nil]];
    }
    else {
		toDelegateError = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unknown error", NSLocalizedFailureReasonErrorKey, nil]];
    }
    
    [self cleanUpTempFile];
    if ([delegate respondsToSelector:@selector(flickrAPIRequest:didFailWithError:)]) {
        [delegate flickrAPIRequest:self didFailWithError:toDelegateError];        
    }
}

- (void)httpRequest:(LFHTTPRequest *)request sentBytes:(NSUInteger)bytesSent total:(NSUInteger)total
{
    if (uploadTempFilename && [delegate respondsToSelector:@selector(flickrAPIRequest:imageUploadSentBytes:totalBytes:)]) {
        [delegate flickrAPIRequest:self imageUploadSentBytes:bytesSent totalBytes:total];
    }
}
@end

@implementation OFFlickrAPIRequest (PrivateMethods)
- (void)cleanUpTempFile

{
    if (uploadTempFilename) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:uploadTempFilename]) {
			BOOL __unused removeResult = NO;
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4                
			removeResult = [fileManager removeFileAtPath:uploadTempFilename handler:nil];
#else
			NSError *error = nil;
			removeResult = [fileManager removeItemAtPath:uploadTempFilename error:&error];
#endif
			
			NSAssert(removeResult, @"Should be able to remove temp file");
        }
        
        [uploadTempFilename release];
        uploadTempFilename = nil;
    }
}
@end
