//
//  EvernoteHTTPClient.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/06.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "EvernoteHTTPClient.h"
#import "TTransportException.h"
#import "TObjective-C.h"

@implementation EvernoteHTTPClient
@synthesize delegate;

/*!
 * initialize
 */
- (id)initWithURL:(NSURL *)aURL andDelegate:(id<EvernoteHTTPClientDelegate>)inDelegate{
    return [self initWithURL:aURL userAgent:nil timeout:0 andDelegate:inDelegate];
}

/*!
 * initialize
 */
- (id)initWithURL:(NSURL *)aURL userAgent:(NSString *)userAgent timeout:(int)timeout andDelegate:(id<EvernoteHTTPClientDelegate>)inDelegate{
    self = [super initWithURL:aURL userAgent:userAgent timeout:timeout];
    if(self){
        self.delegate = inDelegate;
    }
    return self;
}

/*!
 * flush
 */
- (void)flush{
    [mRequest setHTTPBody: mRequestData];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchAsync) object:nil];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
    [queue waitUntilAllOperationsAreFinished];
    
    // phew!
    [mRequestData setLength: 0];
    mResponseDataOffset = 0;
    mResponseData = data_;
    data_ = nil;
    if (mResponseData == nil) {
        @throw [TTransportException exceptionWithName: @"TTransportException"
                                               reason: @"Could not make HTTP request"
                                                error: error_];
    }
}

- (void)fetchAsync{
    // make the HTTP request
    connection_ = [[NSURLConnection alloc] initWithRequest:mRequest delegate:self];
    if(connection_ == nil){
        isExecuting_ = NO;
        return;
    }
    isExecuting_ = YES;
    while(isExecuting_){
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
}

#pragma - NSURLConnection delegates

-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    data_ = [[NSMutableData alloc] init]; // _data being an ivar
    
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
    if ([httpResponse statusCode] != 200) {
        @throw [TTransportException exceptionWithName: @"TTransportException"
                                               reason: [NSString stringWithFormat: @"Bad response from HTTP server: %d",
                                                        [httpResponse statusCode]]];
    }
}
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [data_ appendData:data];
}
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    error_ = error;
    isExecuting_ = NO;
}
-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    isExecuting_ = NO;
}

@end
