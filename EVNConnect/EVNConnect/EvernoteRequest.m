//
//  EvernoteRequest.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import "EvernoteRequest.h"
#import "SBJson.h"

static NSString *kUserAgent = @"EvernoteConnect";
static NSString *kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
static const int kGeneralErrorCode = 10000;

static const NSTimeInterval kTimeoutInterval = 180.0;

@interface EvernoteRequest ()
@property (nonatomic,readwrite) EvernoteRequestState state;
@end

@implementation EvernoteRequest

@synthesize delegate = delegate_,
            url = url_,
            httpMethod = httpMethod_,
            params = params_,
            connection = connection_,
            responseText = responseText_,
            state = state_,
            error = error_;
+ (EvernoteRequest*)getRequestWithParams:(NSMutableDictionary*) params
                         httpMethod:(NSString*) httpMethod
                           delegate:(id<EvernoteRequestDelegate>) delegate
                         requestURL:(NSString*) url {

  EvernoteRequest *request = [[EvernoteRequest alloc] init];
  request.delegate = delegate;
  request.url = url;
  request.httpMethod = httpMethod;
  request.params = params;
  request.connection = nil;
  request.responseText = nil;

  return request;
}

+ (NSString*)serializeURL:(NSString*)baseUrl
                   params:(NSDictionary*)params {
  return [self serializeURL:baseUrl params:params httpMethod:@"GET"];
}
+ (NSString*)serializeURL:(NSString*)baseUrl
                   params:(NSDictionary*)params
               httpMethod:(NSString*)httpMethod {

  NSURL *parsedURL = [NSURL URLWithString:baseUrl];
  NSString *queryPrefix = parsedURL.query ? @"&" : @"?";

  NSMutableArray *pairs = [NSMutableArray array];
  for (NSString *key in [params keyEnumerator]) {
    if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
        ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
      if ([httpMethod isEqualToString:@"GET"]) {
        NSLog(@"can not use GET to upload a file");
      }
      continue;
    }

    NSString *escaped_value = (__bridge NSString*)CFURLCreateStringByAddingPercentEscapes(
                                NULL,                                 (__bridge CFStringRef)[params objectForKey:key],
                                NULL,                                 (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                kCFStringEncodingUTF8);

    [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
  }
  NSString *query = [pairs componentsJoinedByString:@"&"];

  return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}
- (void)utfAppendBody:(NSMutableData*)body data:(NSString*)data {
  [body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}
- (NSMutableData*)generatePostBody {
  NSMutableData *body = [NSMutableData data];
  NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
  NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];

  [self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];

  for (id key in [params_ keyEnumerator]) {

    if (([[params_ valueForKey:key] isKindOfClass:[UIImage class]])
      ||([[params_ valueForKey:key] isKindOfClass:[NSData class]])) {

      [dataDictionary setObject:[params_ valueForKey:key] forKey:key];
      continue;

    }

    [self utfAppendBody:body
                  data:[NSString
                        stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
                        key]];
    [self utfAppendBody:body data:[params_ valueForKey:key]];

    [self utfAppendBody:body data:endLine];
  }

  if ([dataDictionary count] > 0) {
    for (id key in dataDictionary) {
      NSObject *dataParam = [dataDictionary valueForKey:key];
      if ([dataParam isKindOfClass:[UIImage class]]) {
        NSData *imageData = UIImagePNGRepresentation((UIImage*)dataParam);
        [self utfAppendBody:body
                       data:[NSString stringWithFormat:
                             @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
        [self utfAppendBody:body
                       data:[NSString stringWithString:@"Content-Type: image/png\r\n\r\n"]];
        [body appendData:imageData];
      } else {
        NSAssert([dataParam isKindOfClass:[NSData class]],
                 @"dataParam must be a UIImage or NSData");
        [self utfAppendBody:body
                       data:[NSString stringWithFormat:
                             @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
        [self utfAppendBody:body
                       data:[NSString stringWithString:@"Content-Type: content/unknown\r\n\r\n"]];
        [body appendData:(NSData*)dataParam];
      }
      [self utfAppendBody:body data:endLine];

    }
  }

  return body;
}
- (id)formError:(NSInteger)code userInfo:(NSDictionary*) errorData {
   return [NSError errorWithDomain:@"facebookErrDomain" code:code userInfo:errorData];

}
- (id)parseJsonResponse:(NSData*)data error:(NSError **)error {

  NSString *responseString = [[NSString alloc] initWithData:data
                                                    encoding:NSUTF8StringEncoding]
                             ;
  SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
  if ([responseString isEqualToString:@"true"]) {
    return [NSDictionary dictionaryWithObject:@"true" forKey:@"result"];
  } else if ([responseString isEqualToString:@"false"]) {
    if (error != nil) {
      *error = [self formError:kGeneralErrorCode
                      userInfo:[NSDictionary
                                dictionaryWithObject:@"This operation can not be completed"
                                forKey:@"error_msg"]];
    }
    return nil;
  }


  id result = [jsonParser objectWithString:responseString];

  if (![result isKindOfClass:[NSArray class]]) {
    if ([result objectForKey:@"error"] != nil) {
      if (error != nil) {
        *error = [self formError:kGeneralErrorCode
                        userInfo:result];
      }
      return nil;
    }

    if ([result objectForKey:@"error_code"] != nil) {
      if (error != nil) {
        *error = [self formError:[[result objectForKey:@"error_code"] intValue] userInfo:result];
      }
      return nil;
    }

    if ([result objectForKey:@"error_msg"] != nil) {
      if (error != nil) {
        *error = [self formError:kGeneralErrorCode userInfo:result];
      }
    }

    if ([result objectForKey:@"error_reason"] != nil) {
      if (error != nil) {
        *error = [self formError:kGeneralErrorCode userInfo:result];
      }
    }
  }

  return result;

}
- (void)failWithError:(NSError*)error {
  if ([delegate_ respondsToSelector:@selector(request:didFailWithError:)]) {
    [delegate_ request:self didFailWithError:error];
  }
  self.state = kEvernoteRequestStateError;
}
- (void)handleResponseData:(NSData*)data {
  if ([delegate_ respondsToSelector:
      @selector(request:didLoadRawResponse:)]) {
    [delegate_ request:self didLoadRawResponse:data];
  }
    
  NSError *error = nil;
  id result = [self parseJsonResponse:data error:&error];
  self.error = error;  

  if ([delegate_ respondsToSelector:@selector(request:didLoad:)] ||
      [delegate_ respondsToSelector:
          @selector(request:didFailWithError:)]) {

    if (error) {
      [self failWithError:error];
    } else if ([delegate_ respondsToSelector:
        @selector(request:didLoad:)]) {
      [delegate_ request:self didLoad:(result == nil ? data : result)];
    }

  }

}



- (BOOL)loading {
  return !!connection_;
}
- (void)connect {

  if ([delegate_ respondsToSelector:@selector(requestLoading:)]) {
    [delegate_ requestLoading:self];
  }

  NSString *url = [[self class] serializeURL:url_ params:params_ httpMethod:httpMethod_];
  NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
  [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];


  [request setHTTPMethod:self.httpMethod];
  if ([self.httpMethod isEqualToString: @"POST"]) {
    NSString *contentType = [NSString
                             stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:[self generatePostBody]];
  }

  connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  self.state = kEvernoteRequestStateLoading;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
  responseText_ = [[NSMutableData alloc] init];

  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
  if ([delegate_ respondsToSelector:
      @selector(request:didReceiveResponse:)]) {
    [delegate_ request:self didReceiveResponse:httpResponse];
  }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
  [responseText_ appendData:data];
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection
    willCacheResponse:(NSCachedURLResponse*)cachedResponse {
  return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
  [self handleResponseData:responseText_];

  self.responseText = nil;
  self.connection = nil;

  if (self.state != kEvernoteRequestStateError) {
    self.state = kEvernoteRequestStateComplete;
  }
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
  [self failWithError:error];

  self.responseText = nil;
  self.connection = nil;

  self.state = kEvernoteRequestStateError;
}

@end
