//
//  Evernote.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "Evernote.h"
#import "EvernoteRequest.h"
#import "EvernoteAuthOAuthConsumer.h"
#import "THTTPClient.h"
#import "TBinaryProtocol.h"
#import "PDKeychainBindings.h"
#import "RegexKitLite.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface Evernote(PrivateImplementation)
- (NSURL *)baseURL;
- (EDAMNoteStoreClient *)noteStoreClient;
@end

@implementation Evernote(PrivateImplementation)
#pragma mark - private implementations
/*!
 * get base url
 */
- (NSURL *)baseURL{
    NSString *url = kEvernoteBaseURL;
    if(useSandbox_){
        url = kEvernoteSandboxBaseURL;
    }
    return [NSURL URLWithString:url];
}
/*!
 * get note Store Client
 */
- (EDAMNoteStoreClient *)noteStoreClient {
	if (noteStoreClient_ && [authConsumer_ isSessionValid]) {
        return noteStoreClient_;
    }
            
    @try {
        NSURL *noteStoreUri =  [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@note/%@", [self baseURL].absoluteURL, authConsumer_.shardId]];
        THTTPClient *noteStoreHttpClient = [[THTTPClient alloc] initWithURL:noteStoreUri];
        TBinaryProtocol *noteStoreProtocol = [[TBinaryProtocol alloc] initWithTransport:noteStoreHttpClient];
        EDAMNoteStoreClient *noteStore = [[EDAMNoteStoreClient alloc] initWithProtocol:noteStoreProtocol];
        
        if (noteStore) {
            noteStoreClient_ = noteStore;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
        return nil;
    }
    @finally {
    }
    return noteStoreClient_;
}

@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation Evernote
#pragma mark - public implementations
@synthesize sessionDelegate = sessionDelegate_;
/*!
 * initialize
 */
- (id)initWithAuthType:(EvernoteAuthType)authType consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callbackScheme:(NSString *)callbackScheme useSandBox:(BOOL)useSandBox andDelegate:(id<EvernoteSessionDelegate>)delegate{
    self = [super init];
    if (self) {
        useSandbox_ = useSandBox;
        requests_ = [[NSMutableSet alloc] init];
        authType_ = authType;
        switch (authType) {
            case EvernoteAuthTypeOAuthConsumer:
                authConsumer_ = [[EvernoteAuthOAuthConsumer alloc] initWithConsumerKey:consumerKey consumerSecret:consumerSecret callbackScheme:callbackScheme useSandBox:useSandBox andDelegate:self];
                break;
            default:
                break;
        }
        self.sessionDelegate = delegate;
    }
    return self;
}

#pragma mark - oauth, authentication
/*!
 * login to evernote, obtain request token
 */
-(void)login {
    [authConsumer_ login];
}

/*!
 * user login finished
 */
- (BOOL) handleOpenURL:(NSURL *)url {
    return [authConsumer_ handleOpenURL:url];
}

- (void)logout {
    [authConsumer_ logout];
    [self clearCredential];
}

- (BOOL)isSessionValid {
    return [authConsumer_ isSessionValid];
    
}

- (void)evernoteDidLogin{
    if ([sessionDelegate_ respondsToSelector:@selector(evernoteDidLogin)]) {
        [sessionDelegate_ evernoteDidLogin];
    }
}

- (void)evernoteDidLogout{
    if ([sessionDelegate_ respondsToSelector:@selector(evernoteDidLogout)]) {
        [sessionDelegate_ evernoteDidLogout];
    }    
}

- (void)evernoteDidNotLogin{
    if ([sessionDelegate_ respondsToSelector:@selector(evernoteDidNotLogin:)]) {
        [sessionDelegate_ evernoteDidNotLogin];
    }    
}

/*!
 * save credential
 */
- (void)saveCredential{
    PDKeychainBindings *keychain = [PDKeychainBindings sharedKeychainBindings];
    [keychain setObject:authConsumer_.authToken forKey:kEvernoteAuthToken];
    [keychain setObject:authConsumer_.userId forKey:kEvernoteUserId];
    [keychain setObject:authConsumer_.shardId forKey:kEvernoteShardId];
}

/*!
 * load credential
 */
- (void)loadCredential{
    PDKeychainBindings *keychain = [PDKeychainBindings sharedKeychainBindings];
    [authConsumer_ setAuthToken:[keychain objectForKey:kEvernoteAuthToken] 
                         userId:[keychain objectForKey:kEvernoteUserId] 
                     andShardId:[keychain objectForKey:kEvernoteShardId]];
}

/*!
 * clear credential
 */
- (void)clearCredential{
    PDKeychainBindings *keychain = [PDKeychainBindings sharedKeychainBindings];
    [keychain removeObjectForKey:kEvernoteAuthToken];
    [keychain removeObjectForKey:kEvernoteUserId];
    [keychain removeObjectForKey:kEvernoteShardId];
    [authConsumer_ clearCredential];
}
#pragma mark - Fetch note and notebook
/*!
 * list all notebooks
 */
- (NSArray*)notebooks {
	if (self.noteStoreClient == nil) {
        return nil;
    }
    @try {
        NSArray *notebooks = [self.noteStoreClient listNotebooks:authConsumer_.authToken];
        return [NSArray arrayWithArray:notebooks];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

/*!
 * get notebook for title
 */
- (EDAMNotebook *)notebookNamed:(NSString *)title{
    NSString *pattern = [NSString stringWithFormat:@"^%@$", title];
    NSArray *notebooks = [self findNotebooksWithPattern:pattern];
    if(notebooks.count == 0){
        return nil;
    }
    return [notebooks objectAtIndex:0];
}

/*!
 * note book with pattern
 */
- (NSArray *)findNotebooksWithPattern:(NSString *)pattern{
    NSArray *notebooks = [self notebooks];
    NSMutableArray *foundNotebooks = [[NSMutableArray alloc] init];
    for(EDAMNotebook *notebook in notebooks){
        if(notebook.nameIsSet && [notebook.name isMatchedByRegex:pattern]){
            [foundNotebooks addObject:notebook];
        }
    }
    return foundNotebooks;
}

/*!
 * get default notebook
 */
- (EDAMNotebook*)defaultNotebook {
	if (noteStoreClient_ == nil) {
        return nil;
    }    
    @try {
        return [noteStoreClient_ getDefaultNotebook:authConsumer_.authToken];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
    return nil;
}

/*!
 * create notebook
 * when a same title notebook is already exist, it throws exception.
 * so you might have check before creating it.
 */
- (EDAMNotebook*)createNotebookWithTitle:(NSString *)title{
	if (self.noteStoreClient == nil) {
        return nil;
    }
    @try {
        EDAMNotebook *newNotebook = [[EDAMNotebook alloc] init];
        [newNotebook setName:title];
        return [self.noteStoreClient createNotebook:authConsumer_.authToken :newNotebook];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

#pragma mark - notes
/*!
 * get notes in notebook
 */
-  (EDAMNoteList*)notesForNotebookGUID:(EDAMGuid)guid{
	if (noteStoreClient_ == nil) {
        return nil;
    }
    EDAMNoteList *notelist = nil;
	EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] initWithOrder:NoteSortOrder_CREATED ascending:YES words:nil notebookGuid:guid tagGuids:nil timeZone:nil inactive:NO];	
    @try {
        notelist = [self.noteStoreClient findNotes:authConsumer_.authToken :filter :0 :[EDAMLimitsConstants EDAM_USER_NOTES_MAX]];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return notelist;
}

/*!
 * note for note guid
 */
- (EDAMNote*)noteForNoteGUID:(EDAMGuid)guid{
	if (self.noteStoreClient == nil) {
        return nil;
    }
    
    @try {
        return [self.noteStoreClient getNote:authConsumer_.authToken :guid :YES :YES :YES :YES];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

/*!
 * create note in notebook
 */
- (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString *)title andContent:(NSString *)content{
	return [self createNoteInNotebook:notebook title:title content:content andResources:nil];
}

/*!
 * create note in notebook with resource
 */
- (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString *)title content:(NSString *)content andResources:(NSArray *)resources{
	if (self.noteStoreClient == nil) {
        return nil;
    }
    @try {
        EDAMNote *newNote = [[EDAMNote alloc] init];
        [newNote setNotebookGuid:notebook.guid];
        [newNote setTitle:title];
        
        
        if([content isMatchedByRegex:@"^<?xml"] == NO){
            content = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">\n<en-note>%@", content];
            for(EDAMResource *resource in resources){
                NSString * imageENML = [NSString stringWithFormat:@"<en-media type=\"%@\" hash=\"%@\"/>", resource.mime, resource.data.hash];
                content = [NSString stringWithFormat:@"%@%@", content, imageENML];
            }
            content = [NSString stringWithFormat:@"%@%@", content, @"</en-note>"];
        }
        
        [newNote setContent:content];
        [newNote setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
        if(resources != nil){
            [newNote setResources:[NSMutableArray arrayWithArray: resources]];
        }
        return [self.noteStoreClient createNote:authConsumer_.authToken :newNote];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

#pragma mark - Remove(expunge) note
/*!
 * remove note
 */
- (void)removeNoteForGUID:(EDAMGuid)guid{
	if (self.noteStoreClient == nil) {
        return;
    }
    @try {
        [self.noteStoreClient expungeNote:authConsumer_.authToken :guid];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
}
@end
