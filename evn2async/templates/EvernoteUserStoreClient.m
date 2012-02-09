//
//  EvernoteUserStoreClient.m
//  Wrapper class of EDAMUserStoreClient
//
//  Created by conv.php on %s.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "EvernoteUserStoreClient.h"
#import "EvernoteHTTPClient.h"
#import "UserStore.h"
#import "EDAMUserStoreClient+PrivateMethods.h"	
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface EvernoteUserStoreClient(PrivateImplementation)
@end

@implementation EvernoteUserStoreClient(PrivateImplementation)
@end
//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation EvernoteUserStoreClient
/*!
 * get httpclient
 */
- (EvernoteHTTPClient *)httpClient{
  EvernoteHTTPClient *client = (EvernoteHTTPClient *)[outProtocol transport];
  return client;
}

%s
@end
