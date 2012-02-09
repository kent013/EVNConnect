//
//  EvernoteUserStoreClient.m
//  Wrapper class of EDAMUserStoreClient
//
//  Created by conv.php on %s.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//


#import "UserStore.h"
#import "EvernoteProtocol.h"

@interface EvernoteUserStoreClient : EDAMUserStoreClient{
    __weak id<EvernoteHTTPClientDelegate> delegate_;
}
@property (nonatomic, readonly) EvernoteHTTPClient *httpClient;
%s
@end
