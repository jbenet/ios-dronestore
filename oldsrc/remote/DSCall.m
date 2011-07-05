//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSCall.h"
#import "DSConnection.h"
#import <iDrone/DSDrone.h>
#import <iDrone/DSModel.h>
#import <iDrone/DSQuery.h>
#import <iDrone/DSCallback.h>
#import <iDrone/DSLocalDrone.h>
#import <iDrone/DSCollection.h>


static NSString *DSCallTypeSYN = @"SYN";
static NSString *DSCallTypeWHO = @"WHO";
static NSString *DSCallTypeERR = @"ERR";
static NSString *DSCallTypeGET = @"GET";
static NSString *DSCallTypeSET = @"SET";
static NSString *DSCallTypeQRY = @"QRY";

@implementation DSCall

@synthesize parameters, connection, type, isAnnonymous, callbackId, callback;

- (id) initWithType:(NSString *)type_ {
  if ((self = [super initNew])) {
    type = type_;

    parameters = [[NSMutableDictionary alloc] initWithCapacity:4];
    isAnnonymous = NO;
    callbackId = 0;
    callback = nil;
  }
  return self;
}

- (void) dealloc {
  self.parameters = nil;
  self.connection = nil;
  self.callback = nil;
  [super dealloc];
}

- (BOOL) save {
  if (connection.localDrone != nil)
    drone = connection.localDrone;
  return [super save];
}

+ (DSCall *) callWithType:(NSString *)type_ {
  return [[[DSCall alloc] initWithType:type_] autorelease];
}

//------------------------------------------------------------------------------

- (NSString *) handle {

  if ([type isEqualToString:DSCallTypeSYN]) return [self handleSYN];
  if ([type isEqualToString:DSCallTypeWHO]) return [self handleWHO];
  if ([type isEqualToString:DSCallTypeERR]) return [self handleERR];
  if ([type isEqualToString:DSCallTypeGET]) return [self handleGET];
  if ([type isEqualToString:DSCallTypeSET]) return [self handleSET];
  if ([type isEqualToString:DSCallTypeQRY]) return [self handleQRY];

  return @"Unknwon Call";
}

- (void) respondWithCall:(DSCall *)call {
  call.callbackId = callbackId;
  [self.connection enqueueCall:call];
}

- (NSString *) callbackString {
  return [NSString stringWithFormat:@"%i", callbackId];
}

//------------------------------------------------------------------------------
#pragma mark Parameters

- (void) setValue:(id)object forParameter:(NSString *)param {
  [self.parameters setValue:object forKey:param];
}

- (id) valueForParameter:(NSString *)param {
  return [self.parameters valueForKey:param];
}

- (void) requireParameters:(NSArray *)params {
  for (NSString *param in params)
    if ([self.parameters objectForKey:param] == nil)
      [NSException raise:@"DSProtocolError" format:@"Param %@ required", param];
}

//------------------------------------------------------------------------------
#pragma mark Serializing

- (id)proxyForJson {
  return [self toDict];
}

- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict;
  dict = [NSMutableDictionary dictionaryWithDictionary:parameters];

  [dict setValue:type forKey:@"c"];
  if (callbackId > 0)
    [dict setValue:[NSNumber numberWithInt:callbackId] forKey:@"z"];
  return dict;
}

- (void) loadDict:(NSDictionary *)dict {
  type = [dict valueForKey:@"c"];
  if ([dict valueForKey:@"z"] != nil)
    callbackId = [[dict valueForKey:@"z"] intValue];
  self.parameters = [[dict copy] autorelease];
}

+ (DSCall *) callFromDict:(NSDictionary *)dict {
  DSCall *call = [DSCall callWithType:[dict valueForKey:@"c"]];
  [call loadDict:dict];
  return call;
}

//------------------------------------------------------------------------------
#pragma mark SYN

- (NSString *) handleSYN {
  DSLocalDrone *local = (DSLocalDrone *)connection.localDrone;
  NSString *serviceToMatch = local.systemid;

  if (![[self valueForParameter:@"s"] isEqualToString:serviceToMatch])
    return @"System ID Mismatch";

  connection.isSynchronized = YES;
  return nil;
}

+ (DSCall *) SYNCallWithLocalDrone:(DSLocalDrone *)ld {
  DSCall *call = [DSCall callWithType:DSCallTypeSYN];
  call.isAnnonymous = YES;
  [call setValue:ld.droneid forParameter:@"i"];
  [call setValue:ld.systemid forParameter:@"s"];
  return call;
}

//------------------------------------------------------------------------------
#pragma mark WHO

- (NSString *) handleWHO {
  [self respondWithCall:[DSCall SYNCallWithLocalDrone:connection.localDrone]];
  return nil;
}

+ (DSCall *) WHOCall {
  DSCall *call = [DSCall callWithType:DSCallTypeWHO];
  call.isAnnonymous = YES;
  return call;
}

//------------------------------------------------------------------------------
#pragma mark GET

- (NSString *) handleGET {

  if ([self valueForParameter:@"k"] == nil)
    return @"No Key Provided";

  Class modelClass = [DSModel class];
  if ([self valueForParameter:@"t"] != nil)
    modelClass = NSClassFromString([self valueForParameter:@"t"]);

  id model = [modelClass modelForKey:[self valueForParameter:@"t"]];

  if (model == nil)
    return @"No Entity for Key";

  [self respondWithCall:[DSCall SETCallWithModel:model]];
  return nil;
}

+ (DSCall *) GETCallWithKey:(NSString *)key {
  DSCall *call = [DSCall callWithType:DSCallTypeGET];
  [call setValue:key forParameter:@"k"];
  return call;
}

+ (DSCall *) GETCallWithKey:(NSString *)key andClass:(Class)modelClass {
  DSCall *call = [DSCall callWithType:DSCallTypeGET];
  [call setValue:key forParameter:@"k"];
  [call setValue:NSStringFromClass(modelClass) forParameter:@"t"];
  return call;
}

+ (DSCall *) GETCallWithModel:(DSModel *)model {
  return [self GETCallWithKey:model.ds_key_ andClass:[model class]];
}


//------------------------------------------------------------------------------
#pragma mark SET

- (NSString *) handleSET {

  id<NSObject> obj = [self valueForParameter:@"o"];

  if (obj == nil)
    return @"SET -- No Object Provided";

  if ([obj isKindOfClass:[NSDictionary class]])
    obj = [NSArray arrayWithObject:obj];

  if (![obj isKindOfClass:[NSArray class]])
    return @"SET -- Incorrect Format";

  // Ok so far so good.
  NSArray *arr = (NSArray *)obj;
  DSCollection *coll = nil;
  DSModel *model;
  int errors = 0;

  if (callback != nil)
    coll = [DSCollection collectionWithCapacity:[arr count]];

  for (NSDictionary *dict in arr) {
    model = [DSModel modelFromDict:dict andDrone:connection.localDrone];
    if (model == nil) {
      errors++;
    } else {
      [connection.localDrone saveModel:model local:YES remote:NO];
      [coll insertModel:model];
    }
  }

  if (callback != nil)
    callback.object = coll;

  if (errors > 0 && errors >= [(NSArray *)obj count])
    return @"SET -- Error parsing objects";

  return nil;
}

+ (DSCall *) SETCallWithModel:(DSModel *)model {
  DSCall *call = [DSCall callWithType:DSCallTypeSET];
  [call setValue:model forParameter:@"o"];
  return call;
}

+ (DSCall *) SETCallWithCollection:(DSCollection *)coll {
  DSCall *call = [DSCall callWithType:DSCallTypeSET];
  [call setValue:[coll models] forParameter:@"o"];
  return call;
}

//------------------------------------------------------------------------------
#pragma mark ERR

- (NSString *) handleERR {

  // NSLog(@"ERR -- Error: %@", [self valueForParameter:@"m"]);
  return nil;
}

+ (DSCall *) ERRCallWithMessage:(NSString *)message {
  DSCall *call = [DSCall callWithType:DSCallTypeERR];
  [call setValue:message forParameter:@"m"];
  return call;
}

//------------------------------------------------------------------------------
#pragma mark QRY

- (NSString *) handleQRY {

  id<NSObject> q = [self valueForParameter:@"q"];
  if (q == nil)
    return @"No Query Provided";

  else if (![q isKindOfClass:[NSDictionary class]])
    return @"Bad Query Format";

  DSQuery *query = [[[DSQuery alloc] init] autorelease];
  [query loadDict:(NSDictionary *)q];

  if (query.keysOnly) // FIXME
    return @"Keys Only query not supported yet.";

  [query runWithLocalDrone:connection.localDrone wait:YES];

  if (!query.didSucceed)
    return @"Query Failed";


  [self respondWithCall:[DSCall SETCallWithCollection:query.models]];
  return nil;
}

+ (DSCall *) QRYCallWithQuery:(DSQuery *)query {
  DSCall *call = [DSCall callWithType:DSCallTypeQRY];
  [call setValue:query forParameter:@"q"];
  return call;
}

//------------------------------------------------------------------------------

@end