#import "EvernoteProtocol.h"
#import "EvernoteRequest.h"

@protocol EvernoteSessionDelegate;

@interface Evernote : NSObject<EvernoteRequestDelegate, EvernoteAuthDelegate>{
    __strong NSMutableSet *requests_;
    __strong id<EvernoteAuthProtocol> authConsumer_;
    __weak id<EvernoteSessionDelegate> sessionDelegate_;
    EvernoteAuthType authType_;
}
@property(nonatomic, weak) id<EvernoteSessionDelegate> sessionDelegate;

- (id)initWithAuthType:(EvernoteAuthType) authType
           consumerKey:(NSString*)consumerKey
        consumerSecret:(NSString*)consumerSecret
        callbackScheme:(NSString*)callbackScheme
            useSandBox:(BOOL) useSandbox
           andDelegate:(id<EvernoteSessionDelegate>)delegate;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)login;
- (void)logout;
- (BOOL)isSessionValid;

@end

@protocol EvernoteSessionDelegate <NSObject>
- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
- (void)evernoteDidLogout;

@end
