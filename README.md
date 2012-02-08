Evernote API wrapper: EVNConnect
==================================
[日本語の説明はこちら](http://d.hatena.ne.jp/kent013/20120206/1328503033)

This library is a wrapper of Evernote API.  
* ARC enabled project.  
* I did not implemented all of evernote API, only what I needed.
check out [EvernoteRequest.h](https://github.com/kent013/EVNConnect/blob/master/EVNConnect/EVNConnect/EvernoteRequest.h). 

Concept
----------------------------------------------
### 1, Authentication with OAuth  
I don't want to store username and password in our app.  
(I don't need dialog, supports only oauth using safari for multitasking ios)

### 2, Synchronous/Asynchronous API wrapper  
	//synchronous
    - (EDAMNote*)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString*)title content:(NSString*)content tags:(NSArray *)tags andResources:(NSArray*)resources;
    //asynchronous
    - (EvernoteRequest *)createNoteInNotebook:(EDAMNotebook *)notebook title:(NSString*)title content:(NSString*)content tags:(NSArray *)tags resources:(NSArray*)resources andDelegate:(id<EvernoteRequestDelegate>)delegate;
(I haven't implemented other wrapper methods yet, but asynchronous request implementation is already in [EvernoteNoteStoreClient.h](https://github.com/kent013/EVNConnect/blob/master/EVNConnect/EVNConnect/EvernoteNoteStoreClient.h)) 

### 3, Request delegate  
I want to know the progress of request, implemented subclass of thrift's THTTPClient, EvernoteHTTPClient to do it. And added EvernoteRequestDelegate. Currently this feature works with asynchronous request only. 

    @protocol EvernoteRequestDelegate <NSObject>
    @optional
    - (void)requestLoading:(EvernoteRequest*)request;
    - (void)request:(EvernoteRequest*)request didReceiveResponse:(NSURLResponse*)response;
    - (void)request:(EvernoteRequest*)request didFailWithError:(NSError*)error;
    - (void)request:(EvernoteRequest*)request didLoad:(id)result;
    - (void)request:(EvernoteRequest*)request didLoadRawResponse:(NSData*)data;
    - (void)request:(EvernoteRequest*)client 
        didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten 
        totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
    @end


Usage
---------------------------------
### 1, Copy source files in [EVNConnect](https://github.com/kent013/EVNConnect/tree/master/EVNConnect/EVNConnect) into your project.


### 2, Put 3rd party libraries into your project and configure them.
Libraries are stored in [Libraries](https://github.com/kent013/EVNConnect/tree/master/Libraries)

 * Evernote  
[ARC enable version of evernote api 1.20](http://stackoverflow.com/questions/8684039/evernote-cocoa-sdk-not-compiling-for-ios5). 

 * [KissXML](https://github.com/ddeville/KissXML)  
To handle ENML. To use it, please follow instruction in [Getting Started](https://github.com/robbiehanson/KissXML/wiki/GettingStarted)
   
 * [PDKeychainBindingsController](https://github.com/carlbrown/PDKeychainBindingsController)  
To save/load credential.
 
 * [RegexKitLite](http://regexkit.sourceforge.net/RegexKitLite/)  
To search note/notebooks/tags with pattern.   
You need to add libicucore.dylib to your project.

 * [OAuthConsumer](https://github.com/jdg/oauthconsumer)  
To use OAuth, Security.framework and libxml2.dylib are needed.

 * DigestAddition  
To generate md5 hash, I forget where it comes. 


### 3, Code.  

[MainViewController.h](https://github.com/kent013/EVNConnect/blob/master/EVNConnect/MainViewController.h)

    #import "EVNConnect.h"
    @interface MainViewController : UIViewController<EvernoteSessionDelegate, EvernoteRequestDelegate>{
        __strong Evernote *evernote_;
    }
    @property (nonatomic, readonly) Evernote *evernote; 
    @end

[MainViewController.m](https://github.com/kent013/EVNConnect/blob/master/EVNConnect/MainViewController.m)

#### 3.1, initialize evernote wrapper
Initialize `Evernote` class as below. Where `EVERNOTE_CONSUMER_KEY` and `EVERNOTE_CONSUMER_SECRET` are provided by evernote. And `callbackScheme` is url scheme which you configured in your project. `useSandBox` is flag to select `http://www.evernote.com` or `http://sandbox.evernote.com` for API endpoint.
    //create instance of evernote
    evernote_ =
        [[Evernote alloc] initWithAuthType:EvernoteAuthTypeOAuthConsumer
                               consumerKey:EVERNOTE_CONSUMER_KEY
                            consumerSecret:EVERNOTE_CONSUMER_SECRET
                            callbackScheme:@"evnconnecttest://authorize"
                                useSandBox:YES
                               andDelegate:self];

#### 3.2, load credential
If you call `[evernote_ saveCredential]` when previous authentication succeeded, you can load credential via calling `loadCredential` method. If valid credential loaded, you can call noteStore method without switching to safari to authenticate user. 
    [evernote_ loadCredential];

#### 3.3, login to evernote
Now you can call `[evernote_ login]` method to login to Evernote with oauth. When there is no valid authToken saved, this method will switch to safari to authenticate user. 
    [evernote_ login];

#### 3.4, EvernoteSessionDelegate
You may save credential when user did login, or clear credential when login failed. 
    #pragma mark - EvernoteSessionDelegate
    -(void)evernoteDidLogin{
        [evernote_ saveCredential];
    }
    - (void)evernoteDidLogout{
        [evernote_ clearCredential];
    }
    - (void)evernoteDidNotLogin{
        [evernote_ clearCredential];
    }

#### 3.5, send request 
Now you can request to Evernote API. If you call asynchronous requests, you may implement EvernoteRequestDelegate to handle response from server.
    //sync request
    EDAMNotebook *notebook = [evernote_ notebookNamed:@"test"];

    if(notebook == nil){
        notebook = [evernote_ createNotebookWithTitle:@"test"];
    }
    
    EDAMResource *resource1 = 
    [evernote_ createResourceFromUIImage:[UIImage imageNamed:@"sample1.jpg"]];
    
    //async request
    [evernote_ createNoteInNotebook:notebook 
                              title:@"testnote" 
                            content:@"testnotemogemoge" 
                               tags:[NSArray arrayWithObjects:@"Photo", @"Bear", nil]
                          resources:[NSArray arrayWithObject:resource1]
                        andDelegate:self];


License
-------------------------------------
Copyright (c) 2011, ISHITOYA Kentaro. 

New BSD License. See [LICENSE](https://github.com/kent013/EVNConnect/blob/master/LICENSE) file. 

3rd Party Library Licenses
------------------------------------
 * [Evernote API](http://www.evernote.com/about/developer/api/)  
Copyright (c) 2007-2011 by Evernote Corporation, All rights reserved.  
Evernote API's License is [here](https://github.com/kent013/EVNConnect/blob/master/Libraries/Evernote/evernote/LICENSE.txt)
 
 * [Apache Thrift](http://thrift.apache.org/)  
Apache thrift is Licensed under Apache License 2.0. You can read full text of the license [here](https://github.com/kent013/EVNConnect/blob/master/Libraries/Evernote/thrift/APACHE-LICENSE-2.0.txt)  

 * [OAuthConsumer](http://code.google.com/p/oauthconsumer/)  
OAuthConsumer is Licensed under [MIT License](http://www.opensource.org/licenses/mit-license.php).

 * [KissXML](https://github.com/ddeville/KissXML)  
I could not find out mention of license in their repository. 
   
 * [PDKeychainBindingsController](https://github.com/carlbrown/PDKeychainBindingsController)  
Copyright (C) 2010-2011 by Carl Brown of PDAgent, LLC.  
PDKeychainBindingsController is licensed under MIT license. You can read full text of the license [here](https://github.com/carlbrown/PDKeychainBindingsController/blob/master/LICENSE).
 
 * [RegexKitLite](http://regexkit.sourceforge.net/RegexKitLite/)  
Copyright © 2008-2010, John Engelhart  
RegexKitLite is licensed under BSD License. You can read full text of the license [here](http://regexkit.sourceforge.net/RegexKitLite/#LicenseInformation)