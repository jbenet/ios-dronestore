//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <pthread.h>
#import <iDrone/DSCollection.h>
#import <iDrone/DSDrone.h>
#import <iDrone/DSModel.h>

@implementation DSCollection

- (id) init
{
  self = [self initWithCapacity:10];
  return self;
}

- (id) initWithCapacity:(int)cap
{
  if ((self = [super init])) {
    models = [[NSMutableDictionary alloc] initWithCapacity: cap];
    ordered = [[NSMutableArray alloc] initWithCapacity: cap];
    delegates = [[NSMutableArray alloc] initWithCapacity: 5];
    pthread_rwlock_init(&rwlock, NULL);
  }
  return self;
}

#pragma mark -- Delegates --

- (void) addDelegate:(id)delegate
{
  if (delegate != nil)
    [delegates addObject:delegate];
}

- (void) removeDelegate:(id)delegate
{
  if (delegate != nil)
    [delegates removeObject:delegate];
}

- (void) updated
{
  for (id delegate in delegates)
    [delegate didUpdateCollection:self];
}

#pragma mark -- Utility --

- (int) count
{
  return [ordered count];
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id *)stackbuf count:(NSUInteger)len
{
  return [ordered countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (BOOL) containsModel:(DSModel *)model
{
  return [models objectForKey:model.ds_key_] != nil;
}

- (NSArray *) ordered
{
  return [[ordered copy] autorelease];
}

- (NSArray *) arrayForMutableEnumeration
{
  return [NSArray arrayWithArray: ordered];
}

- (NSArray *) keys
{
  return [NSArray arrayWithArray: ordered];
}

- (NSArray *) models
{
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
  for (NSString *key in ordered)
    [array addObject:[models objectForKey:key]];
  return array;
}

- (NSData *) data
{
  return [[[self models] yajl_JSONString]
            dataUsingEncoding:NSUTF8StringEncoding];
}

- (DSCollection *) copy {
  DSCollection *coll = [[DSCollection alloc] initWithCapacity:[self count]];
  [coll addCollection:self];
  return coll; // return retained. copy semantics.
}

#pragma mark -- Locking --

- (void) readLock
{
  pthread_rwlock_rdlock( &rwlock );
}

- (void) writeLock
{
  pthread_rwlock_wrlock( &rwlock );
}

- (void) unlock
{
  pthread_rwlock_unlock( &rwlock );
}

#pragma mark -- Inserting --

- (void) addCollection:(DSCollection *)collection
{
  for (DSModel *model in [collection models])
    [self insertModel:model];
}

- (void) addModelsInArray:(NSArray *)array
{
  for (DSModel *model in array)
    [self insertModel:model];
}

- (void) insertModel:(DSModel *)model
{
  if (model.ds_key_ == nil || [model.ds_key_ length] < 1) {
    // NSLog(@"DS_ERROR: Inserted model with bad key into Collection.");
    return;
  }

  if ([self containsModel:model])
    return;

  [models setObject:model forKey:model.ds_key_];
  [ordered addObject:model.ds_key_];
  [self updated];
}

- (void) insertModel:(DSModel *)model atIndex:(int)index
{
  if (model.ds_key_ == nil || [model.ds_key_ length] < 1) {
    // NSLog(@"DS_ERROR: Inserted model with bad key into Collection.");
    return;
  }

  [models setObject:model forKey:model.ds_key_];
  [ordered removeObject:model.ds_key_]; // In case it's already there.
  [ordered insertObject:model.ds_key_ atIndex:index];
  [self updated];
}

#pragma mark -- Removing --

- (void) removeModel:(DSModel *)model
{
  if ([self containsModel:model]) {
    [ordered removeObject:model.ds_key_];
    [models removeObjectForKey:model.ds_key_];
    [self updated];
  }
}

- (void) removeModelAtIndex:(int)index
{
  NSString *key = [ordered objectAtIndex:index];
  if (key != nil && [key length] >= 1) {
    [ordered removeObjectAtIndex:index];
    [models removeObjectForKey:key];
    [self updated];
  }
}

- (void) removeModelForKey:(NSString *)key
{
  DSModel *model = [models objectForKey:key];
  if (model != nil) {
    [ordered removeObject:key];
    [models removeObjectForKey:key];
    [self updated];
  }
}

- (void) removeModelsInArray:(NSArray *)array
{
  for (id object in array) {
    if ([object isKindOfClass:[DSModel class]])
      [self removeModel:object];
    else if ([object isKindOfClass:[NSString class]])
      [self removeModelForKey:object];
  }
}

- (void) removeAllModels
{
  [ordered removeAllObjects];
  [models removeAllObjects];
  [self updated];
}

- (void) clear
{
  [self removeAllModels];
}

#pragma mark -- Getting --

- (id) modelForKey:(NSString *)key
{
  return [models objectForKey:key];
}

- (id) modelAtIndex:(int)index
{
  return [models objectForKey: [ordered objectAtIndex:index]];
}

- (id) randomModel
{
  return [self modelAtIndex: arc4random() % [ordered count]];
}

- (int) indexOfKey:(NSString *)key
{
  return [ordered indexOfObject:key];
}

- (int) indexOfModel:(DSModel *)model
{
  return [ordered indexOfObject:model.ds_key_];
}

- (int) randomIndex
{
  return arc4random() % [ordered count];
}


#pragma mark -- Sorting --

- (void) sortUsingSelector:(SEL)selector
{
  @synchronized(self) {
    NSArray *models_ = [[self models] sortedArrayUsingSelector:selector];
    [ordered removeAllObjects];
    for (DSModel *model in models_)
      [ordered addObject:model.ds_key_];
  }
  [self updated];
}

- (void) dealloc
{
  pthread_rwlock_destroy(&rwlock);
  [delegates release];
  [ordered release];
  [models release];
  [super dealloc];
}

#pragma mark -- Serializing --

- (id) JSON {
  return [self models];
}

- (void) loadArray:(NSArray *)array withDrone:(DSDrone *)drone {
  if (drone == nil)
    drone = [DSDrone mainDrone];

  for (id obj in array) {
    if ([obj isKindOfClass:[NSDictionary class]]) {
      Class modelClass = NSClassFromString([obj objectForKey:@"ds_type_"]);
      obj = [modelClass modelFromDict:obj andDrone:drone];

    } else if ([obj isKindOfClass:[NSString class]]) {
      obj = [drone modelForKey:obj];
    }

    if ([obj isKindOfClass:[DSModel class]])
      [self insertModel:obj];
    // else
      // NSLog(@"DS_ERROR: collection with array, bad element.");
  }
}

- (void) loadArray:(NSArray *)array {
  [self loadArray:array withDrone:nil];
}

- (NSMutableArray *)toArray {
  return [[ordered copy] autorelease];
}

#pragma mark -- Static Construction --

+ (DSCollection *) collection
{
  return [[[DSCollection alloc] init] autorelease];
}

+ (DSCollection *) collectionWithData:(NSData *)data
{
  return [self collectionWithData:data andDrone:nil];
}

+ (DSCollection *) collectionWithData:(NSData *)data andDrone:(DSDrone *)drone
{
  NSString *json;
  DSCollection *coll;
  json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  coll = [DSCollection collectionWithArray:[json yajl_JSON] andDrone:drone];
  [json release];
  return coll;
}

+ (DSCollection *) collectionWithArray:(NSArray *)array {
  return [self collectionWithArray:array andDrone:nil];
}

+ (DSCollection *) collectionWithArray:(NSArray *)array andDrone:(DSDrone *)dr {
  DSCollection *coll = [DSCollection collectionWithCapacity:[array count]];
  [coll loadArray:array withDrone:dr];
  return coll;
}

+ (DSCollection *) collectionWithCapacity:(int)cap {
    return [[[DSCollection alloc] initWithCapacity:cap] autorelease];
}

+ (DSCollection *) collectionWithCollection:(DSCollection *)coll {
  DSCollection *new = [DSCollection collectionWithCapacity:[coll count]];
  [new addCollection:coll];
  return new;
}

@end


