//
//  EvernoteProtocol.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    EvernoteAuthTypeOAuthConsumer,
    EvernoteAuthTypeMPOAuth
} EvernoteAuthType;

@protocol EvernoteAuthDelegate <NSObject>
- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
- (void)evernoteDidLogout;
@end

@protocol EvernoteAuthProtocol <NSObject>
- (id)initWithConsumerKey:(NSString*)consumerKey
           consumerSecret:(NSString*)consumerSecret
           callbackScheme:(NSString*)callbackScheme
               useSandBox:(BOOL)useSandBox
              andDelegate:(id<EvernoteAuthDelegate>)delegate;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)login;
- (void)logout;
- (BOOL)isSessionValid;
@end

static NSString *kEvernoteOAuthRequestURL = @"https://www.evernote.com/oauth";
static NSString *kEvernoteOAuthAuthenticationURL = @"https://www.evernote.com/OAuth.action";
static NSString *kEvernoteOAuthSandboxRequestURL = @"https://sandbox.evernote.com/oauth";
static NSString *kEvernoteOAuthSandboxAuthenticationURL = @"https://sandbox.evernote.com/OAuth.action";