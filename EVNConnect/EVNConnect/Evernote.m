#import "Evernote.h"
#import "EvernoteRequest.h"
#import "OAPlaintextSignatureProvider.h"

static NSString *kOAuthRequestURL = @"https://www.evernote.com/oauth";
static NSString *kOAuthAuthenticationURL = @"https://www.evernote.com/OAuth.action";
static NSString *kOAuthSandboxRequestURL = @"https://sandbox.evernote.com/oauth";
static NSString *kOAuthSandboxAuthenticationURL = @"https://sandbox.evernote.com/OAuth.action";

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface Evernote(PrivateImplementation)
- (NSURL *) requestTokenURL;
- (NSURL *) authenticationURL;
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishGetRequestToken:(NSData *)data;
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error;
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishFetchAccessToken:(NSData *)data;
- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
@end

@implementation Evernote(PrivateImplementation)
#pragma mark -
#pragma mark private implementations

- (NSURL *) authenticationURL{
    NSString *baseurl = kOAuthAuthenticationURL;
    if(self.useSandbox){
        baseurl = kOAuthSandboxAuthenticationURL;
    }
    NSString *address = [NSString stringWithFormat:
                         @"%@?oauth_token=%@&format=mobile",
                         baseurl,
                         accessToken_.key];
    NSLog(@"auth: %@", baseurl);
    return [NSURL URLWithString:address];    
}

- (NSURL *)requestTokenURL{
    NSString *baseurl = kOAuthRequestURL;
    if(self.useSandbox){
        baseurl = kOAuthSandboxRequestURL;
    }
    NSLog(@"token: %@", baseurl);
    return [NSURL URLWithString:baseurl];    
}

/*!
 * server responds request token
 */
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishGetRequestToken:(NSData *)data {
    if (ticket.didSucceed){        
        NSString *responseBody = 
        [[NSString alloc] initWithData:data 
                              encoding:NSUTF8StringEncoding];
		
        self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[[UIApplication sharedApplication] openURL:[self authenticationURL]];
    } else {
        NSLog(@"%s,%@", __PRETTY_FUNCTION__, ticket.body);
        [self evernoteDidNotLogin];
	}
}

- (void) requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    [self evernoteDidNotLogin];
}

/*!
 * after authentication
 */
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishFetchAccessToken:(NSData *)data {
    if (ticket.didSucceed){
        NSString *responseBody = 
        [[NSString alloc] initWithData:data 
                              encoding:NSUTF8StringEncoding];
		
        self.accessToken = [self.accessToken initWithHTTPResponseBody:responseBody];
        [self evernoteDidLogin];
    } else {
        NSLog(@"%s,%@", __PRETTY_FUNCTION__, ticket.body);
        [self evernoteDidNotLogin];
	}
}

- (void)evernoteDidLogin{
    if ([self.sessionDelegate respondsToSelector:@selector(evernoteDidLogin)]) {
        [self.sessionDelegate evernoteDidLogin];
    }
    
}
- (void)evernoteDidNotLogin{
    if ([self.sessionDelegate respondsToSelector:@selector(evernoteDidNotLogin:)]) {
        [self.sessionDelegate evernoteDidNotLogin];
    }
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation Evernote
@synthesize accessToken = accessToken_;
@synthesize sessionDelegate = sessionDelegate_;
@synthesize useSandbox;

- (id)initWithConsumerKey:(NSString *)consumerKey andConsumerSecret:(NSString *)consumerSecret andCallBackScheme:(NSString *)callbackScheme andDelegate:(id<EvernoteSessionDelegate>)delegate{
    self = [super init];
    if (self) {
        requests_ = [[NSMutableSet alloc] init];
        consumerKey_ = consumerKey;
        consumerSecret_ = consumerSecret;
        callbackScheme_ = callbackScheme;
        self.sessionDelegate = delegate;
    }
    return self;
}

/*!
 * login to evernote, obtain request token
 */
-(void)login {
	consumer_ = [[OAConsumer alloc] initWithKey:consumerKey_
                                         secret:consumerSecret_];
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:[self requestTokenURL]
                                    consumer:consumer_
                                       token:nil
                                       realm:nil
                           signatureProvider:[[OAPlaintextSignatureProvider alloc] init]];
    
	[request setHTTPMethod:@"POST"];

    NSMutableArray *params = [NSMutableArray arrayWithCapacity:3];
    [params addObject:[OARequestParameter requestParameter:@"oauth_callback" value:callbackScheme_]];
    [request setParameters:params];
	
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishGetRequestToken:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
}

/*!
 * user login finished
 */
- (BOOL) handleOpenURL:(NSURL *)url {
    NSLog(@"url:%@", url);
	accessToken_ = [accessToken_ initWithHTTPResponseBody:[url query]];
    
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:[self requestTokenURL]
                                    consumer:consumer_
                                       token:accessToken_
                                       realm:nil
                           signatureProvider:[[OAPlaintextSignatureProvider alloc] init]];
    
    [request setHTTPMethod:@"POST"];
    
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishFetchAccessToken:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
    return YES;
}

- (void)logout {
    if ([self.sessionDelegate respondsToSelector:@selector(evernoteDidLogout)]) {
        [self.sessionDelegate evernoteDidLogout];
    }
}

- (BOOL)isSessionValid {
    return self.accessToken != nil;
    
}
@end
