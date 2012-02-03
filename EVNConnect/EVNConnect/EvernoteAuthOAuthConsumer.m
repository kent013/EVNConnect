//
//  EvernoteAuthOAuthConsumer.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "EvernoteAuthOAuthConsumer.h"
#import "OAPlaintextSignatureProvider.h"
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface EvernoteAuthOAuthConsumer(PrivateImplementation)
- (NSURL *) requestTokenURL;
- (NSURL *) authenticationURL;
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishGetRequestToken:(NSData *)data;
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error;
- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishFetchAccessToken:(NSData *)data;- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
@end

@implementation EvernoteAuthOAuthConsumer(PrivateImplementation)
- (NSURL *) authenticationURL{
    NSString *baseurl = kEvernoteOAuthAuthenticationURL;
    if(useSandBox_){
        baseurl = kEvernoteOAuthSandboxAuthenticationURL;
    }
    NSString *address = [NSString stringWithFormat:
                         @"%@?oauth_token=%@&format=mobile",
                         baseurl,
                         accessToken_.key];
    NSLog(@"auth: %@", baseurl);
    return [NSURL URLWithString:address];    
}

- (NSURL *)requestTokenURL{
    NSString *baseurl = kEvernoteOAuthRequestURL;
    if(useSandBox_){
        baseurl = kEvernoteOAuthSandboxRequestURL;
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
		
        accessToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
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
		
        accessToken_ = [self.accessToken initWithHTTPResponseBody:responseBody];
        [self evernoteDidLogin];
    } else {
        NSLog(@"%s,%@", __PRETTY_FUNCTION__, ticket.body);
        [self evernoteDidNotLogin];
	}
}

- (void)evernoteDidLogin{
    if ([delegate_ respondsToSelector:@selector(evernoteDidLogin)]) {
        [delegate_ evernoteDidLogin];
    }
    
}
- (void)evernoteDidNotLogin{
    if ([delegate_ respondsToSelector:@selector(evernoteDidNotLogin:)]) {
        [delegate_ evernoteDidNotLogin];
    }
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation EvernoteAuthOAuthConsumer
@synthesize accessToken = accessToken_;

- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callbackScheme:(NSString *)callbackScheme useSandBox:(BOOL)useSandBox andDelegate:(id<EvernoteAuthDelegate>)delegate{
    self = [super init];
    if (self) {
        consumerKey_ = consumerKey;
        consumerSecret_ = consumerSecret;
        callbackScheme_ = callbackScheme;
        delegate_ = delegate;
        useSandBox_ = useSandBox;
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
    if ([delegate_ respondsToSelector:@selector(evernoteDidLogout)]) {
        [delegate_ evernoteDidLogout];
    }
}

- (BOOL)isSessionValid {
    return self.accessToken != nil;
    
}

@end
