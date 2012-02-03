//
//  EvernoteAuthOAuthConsumer.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EvernoteProtocol.h"
#import "OAConsumer.h"
#import "OADataFetcher.h"
#import "OAMutableURLRequest.h"

@interface EvernoteAuthOAuthConsumer : NSObject<EvernoteAuthProtocol>{
    __strong NSString *callbackScheme_;
    __strong NSString *consumerKey_;
    __strong NSString *consumerSecret_;
    __strong OAConsumer *consumer_;
	__strong OAToken *accessToken_;
    __weak id<EvernoteAuthDelegate> delegate_;
    BOOL useSandBox_;
}
@property(nonatomic, readonly) OAToken *accessToken;
@end
