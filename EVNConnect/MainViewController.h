//
//  MainViewController.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/02.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVNConnect.h"

@interface MainViewController : UIViewController<EvernoteSessionDelegate, EvernoteRequestDelegate>{
    __strong Evernote *evernote_;
}
@property (nonatomic, readonly) Evernote *evernote;
@end
