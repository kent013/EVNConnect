//
//  EvernoteNoteStoreClient.m
//  Wrapper class of NoteStoreClient
//
//  Created by conv.php on %s.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "EvernoteNoteStoreClient.h"
#import "EvernoteHTTPClient.h"
#import "NoteStore.h"
#import "EDAMNoteStoreClient+PrivateMethods.h"	
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface EvernoteNoteStoreClient(PrivateImplementation)
@end

@implementation EvernoteNoteStoreClient(PrivateImplementation)
@end
//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation EvernoteNoteStoreClient
/*!
 * get httpclient
 */
- (EvernoteHTTPClient *)httpClient{
	EvernoteHTTPClient *client = (EvernoteHTTPClient *)[outProtocol transport];
	return client;
}

%s
@end
