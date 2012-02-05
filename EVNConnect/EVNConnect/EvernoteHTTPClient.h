//
//  EvernoteHTTPClient.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/06.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "THTTPClient.h"

@protocol EvernoteHTTPClientDelegate;

@interface EvernoteHTTPClient : THTTPClient<NSURLConnectionDelegate, NSURLConnectionDataDelegate>{
    NSMutableData *data_;
    NSURLConnection *connection_;
    NSError *error_;
    BOOL isExecuting_;
}

@property(nonatomic, weak) id<EvernoteHTTPClientDelegate> delegate;

- (void) fetchAsync;
- (id)initWithURL:(NSURL *)aURL andDelegate:(id<EvernoteHTTPClientDelegate>)delegate;
- (id)initWithURL:(NSURL *)aURL userAgent:(NSString *)userAgent timeout:(int)timeout andDelegate:(id<EvernoteHTTPClientDelegate>)delegate;
@end

@protocol EvernoteHTTPClientDelegate <NSObject>

@end
