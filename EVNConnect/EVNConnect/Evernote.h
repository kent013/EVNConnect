#import "EvernoteRequest.h"
#import "OAConsumer.h"
#import "OADataFetcher.h"
#import "OAMutableURLRequest.h"

@protocol EvernoteSessionDelegate;
@interface Evernote : NSObject<EvernoteRequestDelegate>{
    __strong NSString *callbackScheme_;
    __strong NSString *consumerKey_;
    __strong NSString *consumerSecret_;
    __strong NSMutableSet *requests_;
    __strong OAConsumer *consumer_;
	__strong OAToken *accessToken_;
    __weak id<EvernoteSessionDelegate> sessionDelegate_;
}
@property(nonatomic, strong) OAToken *accessToken;
@property(nonatomic, weak) id<EvernoteSessionDelegate> sessionDelegate;
@property(nonatomic, assign) BOOL useSandbox;

- (id)initWithConsumerKey:(NSString*)consumerKey
        andConsumerSecret:(NSString*)consumerSecret
        andCallBackScheme:(NSString*)callbackScheme
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
