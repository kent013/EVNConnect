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
	if (noteStoreClient_ && [authConsumer_ isSessionValid] == NO) {
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

- (EDAMNotebook*)defaultNotebook {
	NSArray *notebooks = [self notebooks];
    
	if ([notebooks count] == 0)
		return nil;
	
	EDAMNotebook *defaultNotebook = [notebooks objectAtIndex:0];
	
	if ([notebooks count] == 0)
		return defaultNotebook;
	
	for (int i = 0; i < [notebooks count]; i++) {
		EDAMNotebook* notebook = (EDAMNotebook*)[notebooks objectAtIndex:i];
		if ([notebook defaultNotebook]) {
			return notebook;
		}
	}
	return defaultNotebook;
}

-  (EDAMNoteList*)notesWithNotebookGUID:(EDAMGuid)guid {
	EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] initWithOrder:NoteSortOrder_CREATED ascending:YES words:nil notebookGuid:guid tagGuids:nil timeZone:nil inactive:NO];	
	if (noteStoreClient_) {
		@try {
			return [self.noteStoreClient findNotes:authConsumer_.authToken :filter :0 :[EDAMLimitsConstants EDAM_USER_NOTES_MAX]];
		}
		@catch (NSException *exception) {
			NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
			[self logout];
			return nil;
		}
		@finally {
		}
	}
	return nil;
}

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
        return nil;
    }
    @finally {
    }
	return [NSArray array];
}

- (EDAMNote*)noteWithNoteGUID:(EDAMGuid)guid {
	if (self.noteStoreClient) {
		@try {
			return [self.noteStoreClient getNote:authConsumer_.authToken :guid :YES :YES :YES :YES];
		}
		@catch (NSException *exception) {
			NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
			[self logout];
			return nil;
		}
		@finally {
		}
	}
	return nil;
}

#pragma mark - Create note and notebook

- (EDAMNotebook*)createNewNotebookWithTitle:(NSString*)title {
	EDAMNotebook *createdNewNotebook = nil;
	if (self.noteStoreClient) {
		@try {
			EDAMNotebook *newNotebook = [[EDAMNotebook alloc] init];
			[newNotebook setName:title];
			createdNewNotebook = [self.noteStoreClient createNotebook:authConsumer_.authToken :newNotebook];
		}
		@catch (NSException *exception) {
			NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
			[self logout];
			return nil;
		}
		@finally {
			if (createdNewNotebook)
				return createdNewNotebook;
		}
	}
	return nil;
}

- (EDAMNote*)createNote2Notebook:(EDAMGuid)notebookGuid title:(NSString*)title content:(NSString*)content {
	EDAMNote *createdNewNote = nil;
	if (self.noteStoreClient) {
		@try {
			EDAMNote *newNote = [[EDAMNote alloc] init];
			[newNote setNotebookGuid:notebookGuid];
			[newNote setTitle:title];
			[newNote setContent:content];
			[newNote setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
			createdNewNote = [self.noteStoreClient createNote:authConsumer_.authToken :newNote];
		}
		@catch (NSException *exception) {
			NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
			[self logout];
			return nil;
		}
		@finally {
			if (createdNewNote)
				return createdNewNote;
		}
	}
	return nil;
}

- (EDAMNote*)createNote2Notebook:(EDAMGuid)notebookGuid title:(NSString*)title content:(NSString*)content resources:(NSArray*)resources {
	EDAMNote *createdNewNote = nil;
	if (self.noteStoreClient) {
		@try {
			EDAMNote *newNote = [[EDAMNote alloc] init];
			[newNote setNotebookGuid:notebookGuid];
			[newNote setTitle:title];
			[newNote setContent:content];
			[newNote setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
			[newNote setResources:[NSMutableArray arrayWithArray: resources]];
			createdNewNote = [self.noteStoreClient createNote:authConsumer_.authToken :newNote];
		}
		@catch (NSException *exception) {
			NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
			[self logout];
			return nil;
		}
		@finally {
			if (createdNewNote)
				return createdNewNote;
		}
	}
	return nil;
}

#pragma mark - Remove(expunge) note, but not supported?

// currently not supported to remove notes with API....?

- (int)removeNote:(EDAMNote*)noteToBeRemoved {
	int result = 0;
	if (self.noteStoreClient) {
		@try {
			result = [self.noteStoreClient expungeNote:authConsumer_.authToken :[noteToBeRemoved guid]];
		}
		@catch (NSException *exception) {
			NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
			[self logout];
			return result;
		}
		@finally {
			return result;
		}
	}
	return result;
}
@end
