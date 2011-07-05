//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSConnection.h"
#import <iDrone/DSDrone.h>
#import <iDrone/DSLocalDrone.h>
#import <iDrone/DSCollection.h>
#import <iDrone/DSCallback.h>
#import "DSSecurity.h"
#import "DSEncoding.h"
#import "DSTransport.h"
#import "DSRequest.h"
#import "DSCall.h"

@implementation DSConnection

@synthesize localDrone, remoteDrone, outgoing, incoming, callbacks, callbackId;
@synthesize isSynchronized, transport, encoding, security;

- (id) initWithLocalDrone:(DSLocalDrone *)ld andRemoteDrone:(DSDrone *)rd {
  if ((self = [super init])) {
    localDrone = ld; // Do not retain. Its our parent.
    remoteDrone = [rd retain];

    outgoing = [[DSCollection alloc] initWithCapacity: 10]; // threadsafe
    incoming = [[DSCollection alloc] initWithCapacity: 10]; // threadsafe

    callbacks = [[NSMutableDictionary alloc] initWithCapacity: 10];
    self.callbackId = 1;

    isSynchronized = NO;
    self.transport = [DSTransport transportWithConnection:self];
    self.encoding = [JSONEncoding jsonEncoding];
    self.security = [AESSecurity securityWithSecret:ld.secret];
  }
  return self;
}

- (void) dealloc {
  [remoteDrone release];
  // [localDrone release]; // Do not release. not retained.
  [outgoing release];
  [incoming release];
  [callbacks release];
  self.transport = nil;
  self.encoding = nil;
  self.security = nil;
  [super dealloc];
}

//------------------------------------------------------------------------------

- (void) synchronize {
  if (self.isSynchronized)
    return;

  [self enqueueCall:[DSCall SYNCallWithLocalDrone:localDrone]];
}

- (void) waitForCall:(DSCall *)call {
  [self enqueueCall:call];

  // if ([NSThread isMainThread])
  //   NSLog(@"Waiting on the Main Thread!? shouldn't do that.");

  [self flushCalls];
}

- (void) enqueueCall:(DSCall *)call {
  call.connection = self;
  if (call.callback != nil) {
    call.callbackId = self.callbackId++;
    [callbacks setObject:call.callback forKey:call.callbackString];
  }

  [outgoing writeLock];
  [outgoing insertModel:call];
  [outgoing unlock];
}

- (void) processCall:(DSCall *)call {
  // NSLog(@"Processing %@", call.type);
  call.connection = self;

  if (call.callbackId > 0)
    call.callback = [self.callbacks objectForKey:call.callbackString];

  NSString *error = [call handle];
  bool success = error == nil;

  if (!success)
    [self enqueueCall:[DSCall ERRCallWithMessage:error]];

  if (call.callback != nil)
    [call.callback callSucceeded:success];
}

//------------------------------------------------------------------------------

- (void) processCalls {
  [incoming writeLock];
  while ([incoming count] > 0) {
    DSCall *call = [[incoming modelAtIndex:0] retain];
    [incoming removeModelAtIndex:0];
    [incoming unlock];

    [self processCall:call];
    [call release];

    [incoming writeLock];
  }
  [incoming unlock];
}

- (void) flushCalls {
  NSMutableArray *calls = [[NSMutableArray alloc] initWithCapacity:10];
  NSMutableArray *unsafeCalls = [[NSMutableArray alloc] initWithCapacity:10];

  [outgoing writeLock];
//  int total = [outgoing count];
  while ([outgoing count] > 0) {
    DSCall *call = [outgoing modelAtIndex:0];

    if ([call isAnnonymous] || [security isSecure])
      [calls addObject:call];
    else
      [unsafeCalls addObject:call];

    [outgoing removeModelAtIndex:0];
  }

  [outgoing addModelsInArray:unsafeCalls];
  [outgoing unlock];

  // NSLog(@"flushing %i/%i/%i calls", [calls count], [unsafeCalls count], total);

  [self sendRequest:[DSRequest requestWithConnection:self andCalls:calls]];

  [unsafeCalls release];
  [calls release];
}


//------------------------------------------------------------------------------

- (void) sendRequest:(DSRequest *)request {
  if ([request count] < 1)
    return;

  [transport sendRequest:[self packRequest:request]];
}

- (void) receiveRequest:(NSData *)requestData {
  if ([requestData length] < 2)
    return;

  DSRequest *request = [self unpackRequest:requestData];
  if (request == nil)
    return;

  if (request.date)
    localDrone.systemDate = request.date;

  for (DSCall *call in request)
    [self processCall:call];
    //[incoming addObject:call];
}

- (NSData *) packRequest:(DSRequest *)request {
  return [security encryptMessage: [encoding encodeRequest:request]];
}

- (DSRequest *) unpackRequest:(NSData *)request {
  return [encoding decodeRequest:[security decryptMessage:request]];
}


//------------------------------------------------------------------------------

+ (id) connectionFromDrone:(DSDrone *)ld toDrone:(DSDrone *)rd {
  DSConnection *conn;
  conn = [[DSConnection alloc] initWithLocalDrone:(DSLocalDrone *)ld
                                   andRemoteDrone:rd];
  return [conn autorelease];
}

+ (id) connectionFromDrone:(DSDrone *)ld toDroneID:(NSString *)rid {
  DSDrone *drone = [DSDrone remoteDroneWithDroneID:rid andDrone:ld];
  return [self connectionFromDrone:ld toDrone:drone];
}

@end