
#import "DSDrone.h"
#import "DSKey.h"
#import "DSModel.h"
#import "DSVersion.h"
#import "DSSerialRep.h"
#import "DSDatastore.h"

@implementation DSDrone

@synthesize datastore, droneid;

- (id) init {
  [NSException raise:@"DSInvalidDroneConstruct" format:@"Drone requires a key "
    "and a Datastore."];
  return nil;
}

- (id) initWithId:(DSKey *)key andDatastore:(DSDatastore *)store {
  if ((self = [super init])) {
    droneid = [key retain];
    datastore = [datastore retain];
  }
  return self;
}

- (void) dealloc {
  [datastore release];
  [droneid release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (NSString *) description {
  return [NSString stringWithFormat:@"<DSDrone %@>", droneid];
}

// Dronestore drone interface. sorry its not more obj-c-like!
- (DSModel *) get:(DSKey *)key {
  NSDictionary *data = [datastore get:key];
  if (data == nil)
    return nil;

  DSSerialRep *rep = [[DSSerialRep alloc] initWithDictionary:data];
  DSVersion *version = [[DSVersion alloc] initWithSerialRep:rep];
  DSModel *instance = [DSModel modelWithVersion:version];
  [version release];
  [rep release];
  return instance;
}

- (DSModel *) put:(DSModel *)instance {
  [self putVersion:instance.version];
  return instance;
}
- (DSModel *) merge:(DSModel *)instance {
  return [self mergeVersion:instance.version];
}

- (void) delete:(DSKey *)key {
  [datastore delete:key];
}

- (BOOL) contains:(DSKey *)key {
  return [datastore contains:key];
}

- (DSVersion *) putVersion:(DSVersion *)version {
  [datastore put:[version.serialRep data] forKey:version.key];
  return version;
}

- (DSModel *) mergeVersion:(DSVersion *)new_version {

  DSModel *curr_instance = [self get:new_version.key];
  if (curr_instance == nil) {
    [self putVersion:new_version];
    return [DSModel modelWithVersion:new_version];
  }

  // NOTE: semantically, we must merge into the current instance in the drone
  //  so that merge strategies favor the incumbent version.
  [curr_instance mergeVersion:new_version];

  // store it back
  return [self put:curr_instance];
}


@end


