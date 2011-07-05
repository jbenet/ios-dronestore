//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//


#import <iDrone/DSLocalDrone.h>
#import <iDrone/DSModel.h>
#import <iDrone/DSQuery.h>
#import <iDrone/DSCallback.h>
#import "DSDatabase.h"
#import "DSCache.h"
#import <UIKit/UIKit.h>
#import "DSConnection.h"
#import "DSCall.h"
#import "DSTransport.h"

#define kJANITOR_SLEEP_TIME 5

@implementation DSLocalDrone

@synthesize systemid, deviceid, userid, database;

- (void) initializeDrone {
   // DSModel init
  self.ds_key_ = droneid;

  database = [[DSDatabase alloc] initWithName:droneid andDrone:self];
  connections = [[NSMutableDictionary alloc] initWithCapacity: 10];

  janitor = [[NSThread alloc] initWithTarget:self
                                    selector:@selector(janitorLoop)
                                      object:nil];
  [janitor start];
}

- (id) initWithSystemID:(NSString *)system userID:(NSString *)user
{
  if (self = [super init])
  {
    if (user == nil)
      user = @"";

    self.userid = user;
    self.systemid = system;
    self.deviceid = [[UIDevice currentDevice] uniqueIdentifier];
    self.droneid = [self generateKeyHash];

    [self initializeDrone];
  }

  [DSDrone setLastDrone: self];

  return self;
}

- (id) initWithDroneID:(NSString *)droneid_
{
  if (self = [super init])
  {
    self.userid = @"";
    self.systemid = @"";
    self.deviceid = [[UIDevice currentDevice] uniqueIdentifier];
    self.droneid = droneid_;

    [self initializeDrone];
  }

  [DSDrone setLastDrone: self];

  return self;
}

- (void) dealloc
{
  self.systemid = nil;
  self.deviceid = nil;
  self.userid = nil;
  [janitor cancel];
  [janitor release];
  [connections release];
  [database release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (void) janitorLoop
{
  if ([NSThread isMainThread]) {
    NSLog(@"DS_ERROR: DSLocalDrone janitorLoop called on the Main Thread.");
    return;
  }

  // NSLog(@"Janitor spawning...");
  while ([self retainCount] > 1 && [self isKindOfClass:[DSLocalDrone class]])
  {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [self flushConnections];
    [database upkeep];

    // NSLog(@"Janitor sleeping...");
    [pool drain];

    [NSThread sleepForTimeInterval:kJANITOR_SLEEP_TIME];
  }
  // NSLog(@"Janitor dying...");
}

//------------------------------------------------------------------------------

- (void) _synchFlushConnections {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSArray *conns = [connections allValues];
  for (DSConnection *conn in conns)
    [conn flushCalls];

  [pool release];
}

- (void) flushConnectionsAndWait:(BOOL)wait {

  if (wait) {
    NSArray *conns = [connections allValues];
    for (DSConnection *conn in conns)
      [conn flushCalls];

    return;
  }

  [NSThread detachNewThreadSelector:@selector(_synchFlushConnections)
                           toTarget:self withObject:nil];
}

- (void) flushConnections {
  [self flushConnectionsAndWait:NO];
}


//------------------------------------------------------------------------------


- (BOOL) saveModel:(DSModel *)model
{
  return [self saveModel:model local:YES remote:YES];
}

- (BOOL) loadModel:(DSModel *)model
{
  return [self loadModel:model local:YES remote:YES];
}


- (BOOL) saveModel:(DSModel *)model local:(BOOL)local remote:(BOOL)remote
{
  if (![model invariantsHold])
    return NO;

  BOOL saved = NO;
  BOOL locallyOwned = [model.ds_owner_ isEqualToString:droneid];

  if (local || (remote && locallyOwned))
    saved = [database saveModel:model];

  // If not remote, or we own it, just save it to our db.
  if (!remote || locallyOwned)
    return saved;

  DSConnection *conn = [connections valueForKey:model.ds_owner_];

  if (conn == nil)
    return NO;

  [conn enqueueCall:[DSCall SETCallWithModel:model]];
  return saved;
}

- (BOOL) loadModel:(DSModel *)model local:(BOOL)local remote:(BOOL)remote
{
  BOOL loaded = NO;
  BOOL locallyOwned = [model.ds_owner_ isEqualToString:droneid];

  if (local || (remote && locallyOwned))
    loaded = [database loadModel:model];

  // if not remote, or we are the owner, done.
  if (!remote || locallyOwned)
    return loaded;

  // are we still within our lease? (and not forcing remote)
  if (![model hasExpired] && local)
    return loaded;

  DSConnection *conn = [connections objectForKey:model.ds_owner_];
  [conn enqueueCall:[DSCall GETCallWithModel:model]];
  return loaded;
}

- (BOOL) cacheModel:(DSModel *)model
{
  return [database cacheModel:model];
}

//------------------------------------------------------------------------------

- (id) modelForKey: (NSString *)key
{
  return [self modelForKey:key local:YES remote:YES];
}

- (id) modelForKey: (NSString *)key local:(BOOL)local remote:(BOOL)remote
{
  DSModel *model = [database modelForKey:key];
  if (!remote)
    return model;

  if (model)
    return [self modelForKey:key andOwner:[model ds_owner_]
                    andClass:[model class] local:local remote:remote];

  return nil;
}

- (id) modelForKey: (NSString *)key withClass:(Class) modelClass
{
  return [database modelForKey:key withClass:modelClass];
}

- (id) modelForKey: (NSString *)key andOwner:(NSString *)owner
  andClass:(Class)class local:(BOOL)local remote:(BOOL)remote
{
  DSModel *model = [database modelForKey:key];
  BOOL locallyOwned = [model.ds_owner_ isEqualToString:droneid];

  // if it is locally owned, (or forcing local) return it.
  if ((model != nil && locallyOwned) || !remote)
    return model;

  // have the model and it's valid? (not forcing remote) we're good!
  if (model != nil && ![model hasExpired] && local)
    return model;

  if (!local) // if forcing remote, forget local.
    model = nil;

  DSConnection *conn = [connections valueForKey:owner];
  if (conn != nil) {

    DSCall *call = [DSCall GETCallWithKey:key andClass:class];
    call.callback = [DSCallback callback];
    [conn waitForCall:call];
    model = [call.callback.object modelForKey:key];
  }
  return model;
}

- (id) modelForKey:(NSString *)key andOwner:(NSString *)ownr andClass:(Class)cls
{
  return [self modelForKey:key andOwner:ownr andClass:cls local:YES remote:YES];
}

//------------------------------------------------------------------------------

- (void) addRemoteDroneID:(NSString *)droneid_ withURL:(NSString *)url {

  DSConnection *conn;
  conn = [DSConnection connectionFromDrone:self toDroneID:droneid_];
  conn.transport = [HTTPTransport transportWithConnection:conn andUrl:url];
  [connections setValue:conn forKey:droneid_];

}

- (BOOL) knowsRemoteDroneID:(NSString *)droneid_ {
  return [connections valueForKey:droneid_] != nil;
}

//------------------------------------------------------------------------------

- (void) runQuery:(DSQuery *)query wait:(BOOL)wait {
  if ([query.droneid isEqualToString:self.droneid]) {
    [database runQuery:query];
    return;
  }

  DSConnection *conn = [connections valueForKey:query.droneid];
  if (conn == nil)
    [NSException raise:@"Run Query" format:@"Unknown droneid in query."];

  SEL sel = @selector(queryRanWithCallback:);
  DSCall *call = [DSCall QRYCallWithQuery:query];
  call.callback = [DSCallback callback:query selector:sel];
  [conn enqueueCall:call];
  if (wait)
    [conn waitForCall: call];
}

//------------------------------------------------------------------------------

- (NSString *) generateKeyHash
{
  return [DSDrone sha256HexDigestFrom:[NSString stringWithFormat:@"%@%@%@",
                                self.systemid, self.deviceid, self.userid]];
}

//------------------------------------------------------------------------------

+ (NSString *) device
{
  //FIXME iPod, iSim
  return @"iPhone";
}

+ (DSLocalDrone *)localDroneWithSystemID:(NSString*)sys userID:(NSString *)user
{
  return [[[self alloc] initWithSystemID:sys userID:user] autorelease];
}

+ (DSLocalDrone *)localDroneWithDroneID:(NSString*)droneid
{
  return [[[self alloc] initWithDroneID:droneid] autorelease];
}
//------------------------------------------------------------------------------

@end