#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol EvernoteRequestDelegate;

enum {
  kEvernoteRequestStateReady,
  kEvernoteRequestStateLoading,
  kEvernoteRequestStateComplete,
  kEvernoteRequestStateError
};
typedef NSUInteger EvernoteRequestState;
@interface EvernoteRequest : NSObject {
  __weak id<EvernoteRequestDelegate> delegate_;
  NSString *            url_;
  NSString *            httpMethod_;
  NSMutableDictionary * params_;
  NSURLConnection *     connection_;
  NSMutableData *       responseText_;
  EvernoteRequestState        state_;
  NSError *             error_;
}


@property(nonatomic,weak) id<EvernoteRequestDelegate> delegate;
@property(nonatomic,strong) NSString *url;
@property(nonatomic,strong) NSString *httpMethod;
@property(nonatomic,strong) NSMutableDictionary *params;
@property(nonatomic,strong) NSURLConnection * connection;
@property(nonatomic,strong) NSMutableData *responseText;
@property(nonatomic,readonly) EvernoteRequestState state;
@property(nonatomic,strong) NSError *error;


+ (NSString*)serializeURL:(NSString*)baseUrl
                   params:(NSDictionary*)params;

+ (NSString*)serializeURL:(NSString*)baseUrl
                   params:(NSDictionary*)params
               httpMethod:(NSString*)httpMethod;

+ (EvernoteRequest*)getRequestWithParams:(NSMutableDictionary*) params
                        httpMethod:(NSString*) httpMethod
                          delegate:(id<EvernoteRequestDelegate>)delegate
                        requestURL:(NSString*) url;
- (BOOL) loading;

- (void) connect;

@end

@protocol EvernoteRequestDelegate <NSObject>

@optional
- (void)requestLoading:(EvernoteRequest*)request;
- (void)request:(EvernoteRequest*)request didReceiveResponse:(NSURLResponse*)response;
- (void)request:(EvernoteRequest*)request didFailWithError:(NSError*)error;
- (void)request:(EvernoteRequest*)request didLoad:(id)result;
- (void)request:(EvernoteRequest*)request didLoadRawResponse:(NSData*)data;

@end

