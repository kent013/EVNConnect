//
//  MainViewController.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/02.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
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
    EDAMNotebook *notebook = [evernote_ notebookNamed:@"test3"];
    if(notebook == nil){
        notebook = [evernote_ createNotebookWithTitle:@"test3"];
    }
    
    UIImage *image = [UIImage imageNamed:@"sample1.jpg"];
    EDAMResource *resource = [evernote_ createResourceFromUIImage:image];
    EDAMNote *note = 
    [evernote_ createNoteInNotebook:notebook 
                              title:@"testnote" 
                            content:@"testnotemogemoge" 
                               tags:[NSArray arrayWithObjects:@"Photo", @"Bear", nil]
                       andResources:[NSArray arrayWithObject:resource]];
    
    //NSLog(@"%@", [evernote_ findNotebooksWithPattern:@"test.*"].description);
}

- (void) handleLogoutButtonTapped:(UIButton *)sender{
    [evernote_ logout];
}

-(void)evernoteDidLogin{
    [evernote_ saveCredential];
}

- (void)evernoteDidLogout{
    
}

- (void)evernoteDidNotLogin{
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
