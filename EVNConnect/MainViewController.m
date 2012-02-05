//
//  MainViewController.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/02.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "MainViewController.h"
#import "APIKey.h"

@implementation MainViewController
@synthesize evernote = evernote_;

- (id)init{
    self = [super init];
    if(self){
        UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [loginButton setTitle:@"Login" forState:UIControlStateNormal];
        [loginButton setFrame:CGRectMake(self.view.frame.size.width / 2 - 40, self.view.frame.size.height / 2 - 70, 80, 30)];
        [loginButton addTarget:self action:@selector(handleLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:loginButton];
        
        UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
        [logoutButton setFrame:CGRectMake(self.view.frame.size.width / 2 - 40, self.view.frame.size.height / 2 - 35, 80, 30)];
        [logoutButton addTarget:self action:@selector(handleLogoutButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:logoutButton];
        
        UIButton *testButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [testButton setTitle:@"Test" forState:UIControlStateNormal];
        [testButton setFrame:CGRectMake(self.view.frame.size.width / 2 - 40, self.view.frame.size.height / 2 + 5, 80, 30)];
        [testButton addTarget:self action:@selector(handleTestButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:testButton];
        
        evernote_ = 
        [[Evernote alloc] initWithAuthType:EvernoteAuthTypeOAuthConsumer
                               consumerKey:EVERNOTE_CONSUMER_KEY 
                            consumerSecret:EVERNOTE_CONSUMER_SECRET
                            callbackScheme:@"evnconnecttest://authorize" 
                                useSandBox:YES 
                               andDelegate:self];
        [evernote_ loadCredential];
    }
    return self;
}

- (void) handleLoginButtonTapped:(UIButton *)sender{
    [evernote_ login];
}

- (void) handleTestButtonTapped:(UIButton *)sender{
    //NSLog(@"%@", [evernote_ notebooks].description);
    EvernoteRequest *request = [evernote_ requestWithDelegate:self];
    EDAMNotebook *notebook = [request notebookNamed:@"test"];

    if(notebook == nil){
        notebook = [request createNotebookWithTitle:@"test"];
    }
    
    EDAMResource *resource1 = 
    [request createResourceFromUIImage:[UIImage imageNamed:@"sample1.jpg"]];
    EDAMNote *note = 
    [request createNoteInNotebook:notebook 
                              title:@"testnote" 
                            content:@"testnotemogemoge" 
                               tags:[NSArray arrayWithObjects:@"Photo", @"Bear", nil]
                       andResources:[NSArray arrayWithObject:resource1]];
    
    EDAMTag *tag = [request tagNamed:@"Cat"];
    if(tag == nil){
        tag = [request createTagWithName:@"Cat"];
    }
    
    EDAMResource *resource2 = 
    [request createResourceFromUIImage:[UIImage imageNamed:@"sample2.jpg"]];
    [note.tagGuids addObject:tag.guid];
    [request addResourceToNote:note resource:resource2];
    [request updateNote:note];
    
    //NSLog(@"%@", [evernote_ findNotebooksWithPattern:@"test.*"].description);
}

- (void) handleLogoutButtonTapped:(UIButton *)sender{
    [evernote_ logout];
}

#pragma mark - EvernoteRequestDelegate
-(void)requestLoading:(EvernoteRequest *)request{
    NSLog(@"start request");
}

- (void)request:(EvernoteRequest *)request didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"did received response");
}

- (void)request:(EvernoteRequest *)client didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    NSLog(@"progress:%f", (float)totalBytesWritten / (float)totalBytesExpectedToWrite);
}

- (void)request:(EvernoteRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"request failed with error:%@", error.description);
}

- (void)request:(EvernoteRequest *)request didLoad:(id)result{
    NSLog(@"did request loaded");
}

- (void)request:(EvernoteRequest *)request didLoadRawResponse:(NSData *)data{
    NSLog(@"did request loaded(raw)");    
}

#pragma mark - EvernoteSessionDelegate
/*!
 * did login to evernote
 */
-(void)evernoteDidLogin{
    [evernote_ saveCredential];
}

/*!
 * did logout from evernote
 */
- (void)evernoteDidLogout{
    
}

/*!
 * attempt to login, but not logined
 */
- (void)evernoteDidNotLogin{
    
}

#pragma mark - View lifecycle
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
