//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@class DSConnection;

@interface DSTransport : NSObject {

  DSConnection *connection;

}

@property (nonatomic, assign) DSConnection *connection;

+ (DSTransport *) transportWithConnection:(DSConnection *)conn;

- (void) receiveRequest:(NSData *)request;
- (void) sendRequest:(NSData *)request;
@end


//------------------------------------------------------------------------------
@interface HTTPTransport : DSTransport {

  NSString *url;

}

@property (nonatomic, copy) NSString *url;

- (void) sendPost:(NSData *)body;
- (void) sendGet:(NSData *)body;

+ (HTTPTransport *) transportWithConnection:(DSConnection *)conn
                                     andUrl:(NSString *)url;

@end
