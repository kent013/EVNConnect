//
//  MainViewController.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/02.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVNConnect.h"

@interface MainViewController : UIViewController<EvernoteSessionDelegate>{
    __strong Evernote *evernote_;
}
@property (nonatomic, readonly) Evernote *evernote;
@end
