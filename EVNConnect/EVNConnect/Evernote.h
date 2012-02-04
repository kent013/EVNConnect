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

#pragma mark - notebooks
- (NSArray*)notebooks;
- (EDAMNotebook*)notebookNamed:(NSString *)title;
- (NSArray *)findNotebooksWithPattern:(NSString *)pattern;
- (EDAMNotebook*)defaultNotebook;
- (EDAMNotebook*)createNotebookWithTitle:(NSString*)title;

#pragma mark - notes
- (EDAMNoteList*)notesForNotebookGUID:(EDAMGuid)guid;
- (EDAMNote*)noteForNoteGUID:(EDAMGuid)guid;
- (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString*)title andContent:(NSString*)content;
- (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString*)title content:(NSString*)content andResources:(NSArray*)resources;
- (void)removeNoteForGUID:(EDAMGuid)guid;
@end

@protocol EvernoteSessionDelegate <NSObject>
- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
- (void)evernoteDidLogout;

@end
