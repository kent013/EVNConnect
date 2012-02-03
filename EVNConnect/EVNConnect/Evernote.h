//
//  Evernote.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "EvernoteProtocol.h"
#import "EvernoteRequest.h"
#import "UserStore.h"
#import "NoteStore.h"

@protocol EvernoteSessionDelegate;

@interface Evernote : NSObject<EvernoteRequestDelegate, EvernoteAuthDelegate>{
    __strong NSMutableSet *requests_;
    __strong id<EvernoteAuthProtocol> authConsumer_;
    __weak id<EvernoteSessionDelegate> sessionDelegate_;
    EvernoteAuthType authType_;

	EDAMNoteStoreClient			*noteStoreClient_;
    BOOL useSandbox_;
}
@property(nonatomic, weak) id<EvernoteSessionDelegate> sessionDelegate;

- (id)initWithAuthType:(EvernoteAuthType) authType
           consumerKey:(NSString*)consumerKey
        consumerSecret:(NSString*)consumerSecret
        callbackScheme:(NSString*)callbackScheme
            useSandBox:(BOOL) useSandbox
           andDelegate:(id<EvernoteSessionDelegate>)delegate;

- (BOOL)handleOpenURL:(NSURL *)url;
- (void)login;
- (void)logout;
- (BOOL)isSessionValid;
- (void)saveCredential;
- (void)loadCredential;
- (void)clearCredential;

#pragma mark - Fetch note and notebook

- (EDAMNotebook*)defaultNotebook;
- (EDAMNoteList*)notesWithNotebookGUID:(EDAMGuid)guid;
- (NSArray*)notebooks;
- (EDAMNote*)noteWithNoteGUID:(EDAMGuid)guid;

#pragma mark - Create note and notebook

- (EDAMNotebook*)createNewNotebookWithTitle:(NSString*)title;
- (EDAMNote*)createNote2Notebook:(EDAMGuid)notebookGuid title:(NSString*)title content:(NSString*)content;
- (EDAMNote*)createNote2Notebook:(EDAMGuid)notebookGuid title:(NSString*)title content:(NSString*)content resources:(NSArray*)resources;

#pragma mark - Remove(expunge) note

- (int)removeNote:(EDAMNote*)noteToBeRemoved;	// does not work
@end

@protocol EvernoteSessionDelegate <NSObject>
- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
- (void)evernoteDidLogout;

@end
