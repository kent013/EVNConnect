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
#import "UIImage+Digest.h"
#import "NSData+Digest.h"
#import "DDXML.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface Evernote(PrivateImplementation)
- (NSURL *)baseURL;
- (EDAMNoteStoreClient *)noteStoreClient;
- (NSString *) clearTextToENMLString:(NSString *)text;
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

/*!
 * convert clear text to ENML
 */
- (NSString *)clearTextToENMLString:(NSString *)text{
    text = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">\n<en-note>%@</en-note>", text];
    return text;
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

#pragma mark - tags
/*!
 * list tags
 */
- (NSArray *)tags{
	if (self.noteStoreClient == nil) {
        return nil;
    }
    @try {
        NSArray *tags = [self.noteStoreClient listTags:authConsumer_.authToken];
        return [NSArray arrayWithArray:tags];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

/*!
 * get tag for title
 */
- (EDAMNotebook *)tagNamed:(NSString *)name{
    NSString *pattern = [NSString stringWithFormat:@"^%@$", name];
    NSArray *tags = [self findTagsWithPattern:pattern];
    if(tags.count == 0){
        return nil;
    }
    return [tags objectAtIndex:0];
}

/*!
 * note book with pattern
 */
- (NSArray *)findTagsWithPattern:(NSString *)pattern{
    NSArray *tags = [self tags];
    NSMutableArray *foundTags = [[NSMutableArray alloc] init];
    for(EDAMNotebook *tag in tags){
        if(tag.nameIsSet && [tag.name isMatchedByRegex:pattern]){
            [foundTags addObject:tag];
        }
    }
    return foundTags;
}



/*!
 * create tag
 * when a same title tag is already exist, it throws exception.
 * so you might have check before creating it.
 */
- (EDAMTag*)createTagWithName:(NSString *)name{
	if (self.noteStoreClient == nil) {
        return nil;
    }
    @try {
        EDAMTag *tag = [[EDAMTag alloc] init];
        tag.name = name;
        return [self.noteStoreClient createTag: authConsumer_.authToken :tag];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

/*!
 * remove tag for name
 */
- (void)removeTagForName: (NSString *)tagName{
    EDAMTag *tag = [self tagNamed:tagName];
    if(tag == nil){
        return;
    }
    [self removeTag: tag];
}

/*!
 * rename tag
 */
- (EDAMTag *)renameTag:(EDAMTag *)tag toName:(NSString *)name{
	if (self.noteStoreClient == nil) {
        return tag;
    }
    @try {
        tag.name = name;
        [self.noteStoreClient updateTag:authConsumer_.authToken :tag];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }    
    return tag;
}

/*!
 * remove tag
 */
- (void)removeTag:(EDAMTag *)tag{
	if (self.noteStoreClient == nil) {
        return;
    }
    @try {
        [self.noteStoreClient expungeTag:authConsumer_.authToken :tag.guid];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
}


#pragma mark - notebooks
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

#pragma mark - resource
/*!
 * create resource
 */
- (EDAMResource *) createResourceFromUIImage:(UIImage *)image{
    NSData * imageNSData = UIImageJPEGRepresentation(image, 1.0);
    return [self createResourceFromImageData:imageNSData andMime:@"image/jpeg"];
}

/*!
 * create resource from NSData
 */
- (EDAMResource *)createResourceFromImageData:(NSData *)imageNSData andMime:(NSString *)mime{
    NSString * hash = imageNSData.MD5DigestString;
    EDAMResource * imageResource = nil;
    
    EDAMData * imageData = [[EDAMData alloc] initWithBodyHash:[hash dataUsingEncoding: NSASCIIStringEncoding] size:[imageNSData length] body:imageNSData];
    EDAMResourceAttributes * imageAttributes = [[EDAMResourceAttributes alloc] init];    
    imageResource  = [[EDAMResource alloc]init];
    [imageResource setMime:mime];
    [imageResource setData:imageData];
    [imageResource setAttributes:imageAttributes];
    return imageResource;    
}

#pragma mark - notes
/*!
 * get notes in notebook
 */
- (EDAMNoteList *)notesForNotebook:(EDAMNotebook *)notebook{
    return [self notesForNotebookGUID:notebook.guid];
}

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
- (EDAMNote *)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString *)title andContent:(NSString *)content{
        return [self createNoteInNotebook:notebook title:title content:content tags:nil andResources:nil];
}

/*!
 * create note in notebook with tags
 */
- (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString *)title content:(NSString *)content andTags:(NSArray *)tags{
	return [self createNoteInNotebook:notebook title:title content:content tags:tags andResources:nil];
}

/*!
 * add(append at end of note) resource to note
 */
- (void)addResourceToNote:(EDAMNote *)note resource:(EDAMResource *)resource{
    NSString *content = note.content;
    
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:content options:0 error:&error];
    
    DDXMLElement *element = [[DDXMLElement alloc] initWithName:@"en-media"];
    [element addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:resource.mime]];
    [element addAttribute:[DDXMLNode attributeWithName:@"hash" stringValue:[[NSString alloc] initWithData:resource.data.bodyHash encoding:NSASCIIStringEncoding]]];
    [document.rootElement addChild:element];
    note.content = document.XMLString;
    if(note.resources == nil){
        note.resources = [[NSMutableArray alloc] init];
    }
    [note.resources addObject:resource];
}

/*!
 * create note in notebook with resource
 * @param target notebook
 * @param title of note
 * @param content of note
 * @param array of tag, can be EDAMTag or NSString
 * @param array of resource, each item must be instance of EDAMResource.
 */
- (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString *)title content:(NSString *)content tags:(NSArray *)tags andResources:(NSArray *)resources{
	if (self.noteStoreClient == nil) {
        return nil;
    }
    @try {
        EDAMNote *newNote = [[EDAMNote alloc] init];
        [newNote setNotebookGuid:notebook.guid];
        [newNote setTitle:title];
        newNote.tagGuids = [[NSMutableArray alloc] init];
        newNote.tagNames = [[NSMutableArray alloc] init];
        for(id tag in tags){
            if([tag isKindOfClass:[EDAMTag class]]){
                [newNote.tagGuids addObject:tag];
            }else if([tag isKindOfClass:[NSString class]]){
                [newNote.tagNames addObject:tag];
            }
        }
        
        for(id resource in resources){
            if([resource isKindOfClass:[EDAMResource class]] == NO){
                @throw [NSException exceptionWithName: @"IllegalArgument"
                                               reason: @"resource must be EDAMResource"
                                             userInfo: nil];
            }
        }
        
        if([content isMatchedByRegex:@"^<?xml"] == NO){
            newNote.content = [self clearTextToENMLString:content];
        }
        for(EDAMResource *resource in resources){
            [self addResourceToNote:newNote resource:resource];
        }
        
        [newNote setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
        EDAMNote *createdNote = 
        [self.noteStoreClient createNote:authConsumer_.authToken :newNote];
        createdNote.content = newNote.content;
        return createdNote;
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
	return nil;
}

/*!
 * update note
 */
-(void)updateNote:(EDAMNote *)note{
	if (self.noteStoreClient == nil) {
        return;
    }
    @try {
        [self.noteStoreClient updateNote:authConsumer_.authToken :note];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }    
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
        [self.noteStoreClient deleteNote:authConsumer_.authToken :guid];
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        [self logout];
    }
}
@end
