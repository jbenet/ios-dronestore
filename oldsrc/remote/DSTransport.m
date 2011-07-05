//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSTransport.h"
#import "DSConnection.h"
#import "NSData+Base64.h"

@implementation DSTransport

@synthesize connection;

- (void) receiveRequest:(NSData *)request {
  [connection receiveRequest:request];
}

- (void) sendRequest:(NSData *)request {
  // NSLog(@"%@", request);
}

+ (DSTransport *) transportWithConnection:(DSConnection *)conn
{
  DSTransport *transport = [[DSTransport alloc] init];
  transport.connection = conn;
  return [transport autorelease];
}

@end

@implementation HTTPTransport

@synthesize url;

- (void) receiveRequest:(NSData *)request {
  [connection receiveRequest:[request base64DecodedData]];
}

- (void) sendRequest:(NSData *)request {
  request = [request base64EncodedData];
  if ([request length] < 400)
    [self sendGet:request];
  else
    [self sendPost:request];
}

- (void) sendPost:(NSData *)body {
  // NSLog(@"DS Sending POST");

  NSString *length = [NSString stringWithFormat:@"%d", [body length]];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:url]];
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:body];
  [request setValue:length forHTTPHeaderField:@"Content-Length"];
  [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];

  NSURLResponse *response;
  NSError *error = nil;
  NSData *result = [NSURLConnection sendSynchronousRequest:request
                         returningResponse:&response error:&error];
  [request release];

  if (result == nil) {
    // NSLog(@"DS_TRANSPORT: no result.");
  } else if (error != nil) { // crashes...
    // NSLog(@"DS_TRANSPORT: Error: %@", [error localizedDescription]);
  } else {
    [self receiveRequest:result];
  }
}

- (void) sendGet:(NSData *)body {

  NSString *query;
  query = [[NSString alloc] initWithData:body encoding:NSASCIIStringEncoding];
  [query autorelease];
  if ([query length] < 1)
    return;

  NSString *esc = [NSString stringWithFormat:@"%@?r=%@", url, query];

  // NSLog(@"DS Sending GET %@", esc);

  NSURL *turl = [NSURL URLWithString:esc];
  NSData *result = [NSData dataWithContentsOfURL:turl];
  if ([result length] > 10)
    [self receiveRequest:result];
}

+ (HTTPTransport *) transportWithConnection:(DSConnection *)conn
                                     andUrl:(NSString *)url
{
  HTTPTransport *transport = [[HTTPTransport alloc] init];
  transport.connection = conn;
  transport.url = url;
  return [transport autorelease];
}


@end


