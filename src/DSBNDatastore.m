#import "DSBNDatastore.h"
#import "DSKey.h"

@implementation DSBNDatastore

@synthesize timeoutTimeInterval;

- (id) init {
  return [self initWithRemoteService:nil];
}

- (id) initWithRemoteService:(BNRemoteService *)_service {
  if (_service == nil) {
    [NSException raise:@"DSBNDatastoreInit" format:@"DSBNDatastore inited "
      "with nil service."];
  }

  if ((self = [super init])) {
    service_ = [_service retain];
    service_.delegate = self;
    responsesByToken_ = [[NSMutableDictionary alloc] init];
    lastToken_ = 0;
    timeoutTimeInterval = 5.000;
  }
  return self;
}

- (void) dealloc {
  [service_ release];
  [responsesByToken_ release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (NSObject *) runCommand:(NSString *)command withValue:(NSObject *)value {

  // Get the message ready
  NSString *token = [NSString stringWithFormat:@"%d", ++lastToken_];
  [token retain];

  BNMessage *message = [[BNMessage alloc] init];
  [message.contents setValue:command forKey:@"command"];
  [message.contents setValue:value forKey:@"value"];
  [message.contents setValue:token forKey:@"token"];

  // Put this as the placeholder response to check against.
  // When the response returns, it will replace it.
  @synchronized(responsesByToken_) {
    [responsesByToken_ setValue:message forKey:token];
  }

  // Send the actual message
  [service_ sendMessage:message];

  BNMessage *response = nil;
  NSTimeInterval busyWaitInterval = 0.025;
  NSTimeInterval totalWaitTimeout = self.timeoutTimeInterval;
  int maxBusyWaitIterations = (int)(totalWaitTimeout / busyWaitInterval);

  NSRunLoop *loop = [NSRunLoop currentRunLoop];
  for (int i = 0; response == nil && i < maxBusyWaitIterations; i++) {

    NSDate *date = [NSDate date];
    [loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:busyWaitInterval]];
    NSTimeInterval remW = busyWaitInterval - fabs([date timeIntervalSinceNow]);
    [NSThread sleepForTimeInterval:remW];

    @synchronized(responsesByToken_) {
      response = [responsesByToken_ valueForKey:token];
    }

    if (response == message) // hasn't received it yet.
      response = nil;
  }

  [message autorelease];
  [token autorelease];

  [response retain];
  // Pcikup our garbage... Delete the entry.
  @synchronized(responsesByToken_) {
    [responsesByToken_ setValue:nil forKey:token];
  }

  if (!response) { // timed out.
    DebugLog(@"DSBNDatastore %@ %@ timed out", command, value);
    return nil;
  }

  [response autorelease];
  // errored out at our response.
  if ([response.contents valueForKey:@"error"]) {
    DebugLog(@"DSBNDatastore %@ %@ received error %@", command, value,
      [response.contents valueForKey:@"error"]);
    return nil;
  }

  NSObject *responseValue = [response.contents valueForKey:@"value"];

  // no error and no value? malformed...
  if (!responseValue) {
    DebugLog(@"DSBNDatastore %@ %@ invalid response", command, value);
    return nil;
  }

  if ([responseValue isKindOfClass:[NSDictionary class]]
     && [responseValue valueForKey:@"error"]) {
    DebugLog(@"DSBNDatastore %@ %@ received error %@", command, value,
      [responseValue valueForKey:@"error"]);
    return nil;
  }

  return responseValue; // could still be error.
}


//------------------------------------------------------------------------------
#pragma mark RemoteService Delegation

- (void) remoteService:(BNRemoteService *)serv receivedMessage:(BNMessage *)ms {

  NSString *token = [ms.contents valueForKey:@"token"];
  if (!token) {
    DebugLog(@"DSBNDatastore received message with no token. %@", ms.contents);
    return;
  }

  if (![token isKindOfClass:[NSString class]]) {
    DebugLog(@"DSBNDatastore received message with invalid token. %@", token);
    return;
  }

  BOOL alreadyTimedOut = NO;
  @synchronized(responsesByToken_) {
    if ([responsesByToken_ valueForKey:token])
      [responsesByToken_ setValue:ms forKey:token];
    else
      alreadyTimedOut = YES;
  }

  if (alreadyTimedOut) {
    DebugLog(@"DSBNDatastore received message %@ after timeout!", ms.contents);
  }
}

- (void) remoteService:(BNRemoteService *)serv error:(NSError *)error {
  DebugLog(@"DSBNDatastore remote service error: %@", error);
}

- (void) remoteService:(BNRemoteService *)serv sentMessage:(BNMessage *)msg {

}

//------------------------------------------------------------------------------
#pragma mark Datastore API

- (id) get:(DSKey *)key {

  id object = [self runCommand:@"get" withValue:key.string];

  // if number, probably return 0 (not found)
  if (object && [object isKindOfClass:[NSNumber class]]) {
    DebugLog(@"DSBNDatastore get %@ received %@", key, object);
    return nil;
  }

  // NSLog(@"GET %@: %@", key, object);

  return object;
}

- (void) put:(NSObject *)object forKey:(DSKey *)key {
  if (![object valueForKey:@"key"]) {
    [NSException raise:@"DSBNInvalidValue" format:@"DSBNDatastore only stores "
      "valued with keys"];
  }
  [self runCommand:@"put" withValue:object];
}

- (void) delete:(DSKey *)key {
  [self runCommand:@"delete" withValue:key.string];
}

- (BOOL) contains:(DSKey *)key {
  NSObject *ret = [self runCommand:@"contains" withValue:key.string];
  if (![ret isKindOfClass:[NSNumber class]]) {
    DebugLog(@"DSBNDatastore contains %@ received %@", key, ret);
    return NO;
  }

  return [(NSNumber *)ret boolValue];
}

- (NSArray *) query:(DSQuery *)query {
  NSObject *ret = [self runCommand:@"query" withValue:[query dictionary]];
  if (![ret isKindOfClass:[NSArray class]]) {
    DebugLog(@"DSBNDatastore query %@ received %@", query, ret);
    return nil;
  }
  return (NSArray *)ret;
}


@end
