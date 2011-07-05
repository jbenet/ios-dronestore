//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@class DSCall;
@class DSDrone;
@class DSLocalDrone;
@class DSTransport;
@class DSCollection;
@class DSEncoding;
@class DSSecurity;
@class DSRequest;
@class DSConnection;
@class DSQuery;

@interface DSConnection : NSObject {

  DSDrone *remoteDrone;
  DSLocalDrone *localDrone;

  DSCollection *outgoing;
  DSCollection *incoming;
  NSOperationQueue *queue;

  NSMutableDictionary *callbacks;
  int callbackId;

  BOOL isSynchronized;

  DSTransport *transport;
  DSEncoding *encoding;
  DSSecurity *security;

}

@property (retain, readonly) DSDrone *remoteDrone;
@property (assign, readonly) DSLocalDrone *localDrone;

@property (retain, readonly) DSCollection *outgoing;
@property (retain, readonly) DSCollection *incoming;

@property (retain, readonly) NSMutableDictionary *callbacks;
@property (assign) int callbackId;

@property (assign) BOOL isSynchronized;

@property (retain) DSTransport *transport;
@property (retain) DSEncoding *encoding;
@property (retain) DSSecurity *security;

- (id) initWithLocalDrone:(DSLocalDrone *)ld andRemoteDrone:(DSDrone *)rd;

- (void) synchronize;
- (void) waitForCall:(DSCall *)call;
- (void) enqueueCall:(DSCall *)call;
- (void) processCall:(DSCall *)call;

- (void) flushCalls;
- (void) processCalls;

- (void) sendRequest:(DSRequest *)request;
- (void) receiveRequest:(NSData *)request;

- (NSData *) packRequest:(DSRequest *)request;
- (DSRequest *) unpackRequest:(NSData *)request;

+ (DSConnection *) connectionFromDrone:(DSDrone *)ld toDrone:(DSDrone *)rd;
+ (DSConnection *) connectionFromDrone:(DSDrone *)ld toDroneID:(NSString *)rid;

@end

