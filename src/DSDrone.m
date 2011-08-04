
#import "DSDrone.h"
#import "DSKey.h"
#import "DSModel.h"
#import "DSVersion.h"
#import "DSSerialRep.h"
#import "DSDatastore.h"
#import "DSQuery.h"
#import "DSCollection.h"

#import <bson-objc/bson-objc.h>

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
    datastore = [store retain];
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


- (DSModel *) instanceFromDatastoreData:(NSDictionary *)data {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict addEntriesFromDictionary:data];
  return [DSModel modelWithDictionary:dict];
}

//------------------------------------------------------------------------------

// Dronestore drone interface. sorry its not more obj-c-like!
- (DSModel *) get:(DSKey *)key {
  if (key == nil)
    return nil;

  NSDictionary *data = [datastore get:key];
  if (data == nil)
    return nil;

  return [self instanceFromDatastoreData:data];
}

- (DSModel *) put:(DSModel *)instance {
  [self putVersion:instance.version];
  return instance;
}
- (DSModel *) merge:(DSModel *)instance {
  return [self mergeVersion:instance.version];
}

- (void) delete:(DSKey *)key {
  if (key != nil)
    [datastore delete:key];
}

- (BOOL) contains:(DSKey *)key {
  if (key == nil)
    return NO;

  return [datastore contains:key];
}

- (DSCollection *) query:(DSQuery *)query {
  if (query == nil)
    return nil;

  NSArray *array = [datastore query:query];
  DSCollection *collection = [[DSCollection alloc] init];
  for (NSDictionary *data in array)
    [collection insertModel:[self instanceFromDatastoreData:data]];

  return [collection autorelease];
}


- (DSVersion *) putVersion:(DSVersion *)version {
  if (version == nil)
    return nil;

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict addEntriesFromDictionary:version.serialRep.contents];

  [datastore put:dict forKey:version.key];
  return version;
}

- (DSModel *) mergeVersion:(DSVersion *)new_version {
  if (new_version == nil)
    return nil;

  [new_version retain];

  DSModel *curr_instance = [self get:new_version.key];
  if (curr_instance == nil) {

    [self putVersion:new_version];
    curr_instance = [DSModel modelWithVersion:new_version];

  } else {

    // NOTE: semantically, we must merge into the current instance in the drone
    //  so that merge strategies favor the incumbent version.
    [curr_instance mergeVersion:new_version];

    // store it back
    curr_instance = [self put:curr_instance];
  }

  [new_version release];
  return curr_instance;
}


#pragma mark Model Container

- (void) addModel:(DSModel *)model {
  [self merge:model];
}

- (DSModel *) modelForKey:(DSKey *)key {
  return [self get:key];
}

- (void) removeModel:(DSModel *)model {
  [self delete:model.key];
}

@end


