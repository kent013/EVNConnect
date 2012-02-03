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
        [loginButton setFrame:CGRectMake(self.view.frame.size.width / 2 - 40, self.view.frame.size.height / 2 - 15, 80, 30)];
        [loginButton addTarget:self action:@selector(handleLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:loginButton];
        evernote_ = [[Evernote alloc] initWithConsumerKey:EVERNOTE_CONSUMER_KEY andConsumerSecret:EVERNOTE_CONSUMER_SECRET andCallBackScheme:@"evnconnecttest://authorize" andDelegate:self];
        evernote_.useSandbox = YES;
    }
    return self;
}
         
- (void) handleLoginButtonTapped:(UIButton *)sender{
    [evernote_ login];
}

-(void)evernoteDidLogin{
    
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
