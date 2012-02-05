Evernote API wrapper: EVNConnect
==================================
This library is a wrapper of Evernote API.  
* ARC enabled project.  
* I did not implemented all of evernote API, only what I needed.
check out [EvernoteRequest.h](https://github.com/kent013/EVNConnect/blob/master/EVNConnect/EVNConnect/EvernoteRequest.h). 

Concept
----------------------------------------------
### 1, Authentication with OAuth  
I don't want to store username and password in our app.  
(I don't need dialog, supports only oauth using safari for multitasking ios)

### 2, Request delegate  
I want to know the progress of request, implemented subclass of thrift's THTTPClient, EvernoteHTTPClient to do it. And added EvernoteRequestDelegate.  

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

because of implementation of evernote-api, I could not make request asynchronous.

### 3, Wrapper of NoteStoreClient
Something like below.
    EvernoteRequest *request = [evernote_ requestWithDelegate:self];
    NSArray *notebooks = [evernote_ notebooks];
    EDAMNotebook *notebook = [request notebookNamed:@"test"];

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

    //create instance of evernote
    evernote_ =
        [[Evernote alloc] initWithAuthType:EvernoteAuthTypeOAuthConsumer
                               consumerKey:EVERNOTE_CONSUMER_KEY
                            consumerSecret:EVERNOTE_CONSUMER_SECRET
                            callbackScheme:@"evnconnecttest://authorize"
                                useSandBox:YES
                               andDelegate:self];
    //load creadentials
    [evernote_ loadCredential];
    //…. snip ….
    EvernoteRequest *request = [evernote_ requestWithDelegate:self];
    NSLog(@"%@", [evernote_ notebooks].description);
    EDAMNotebook *notebook = [request notebookNamed:@"test"];
    //…. snip ….
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

If you want to know information about request, use EvernoteSessionDelegate.

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
I could not find out mention of license in there repository. 
   
 * [PDKeychainBindingsController](https://github.com/carlbrown/PDKeychainBindingsController)  
Copyright (C) 2010-2011 by Carl Brown of PDAgent, LLC.  
PDKeychainBindingsController is licensed under MIT license. You can read full text of the license [here](https://github.com/carlbrown/PDKeychainBindingsController/blob/master/LICENSE).
 
 * [RegexKitLite](http://regexkit.sourceforge.net/RegexKitLite/)  
Copyright © 2008-2010, John Engelhart  
RegexKitLite is licensed under BSD License. You can read full text of the license [here](http://regexkit.sourceforge.net/RegexKitLite/#LicenseInformation)