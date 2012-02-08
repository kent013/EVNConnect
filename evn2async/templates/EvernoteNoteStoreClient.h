//
//  EvernoteNoteStoreClient.m
//  Wrapper class of NoteStoreClient
//
//  Created by conv.php on %s.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//


#import "NoteStore.h"
#import "EvernoteProtocol.h"

@interface EvernoteNoteStoreClient : EDAMNoteStoreClient{
    __weak id<EvernoteHTTPClientDelegate> delegate_;
}
@property (nonatomic, readonly) EvernoteHTTPClient *httpClient;
%s
@end
