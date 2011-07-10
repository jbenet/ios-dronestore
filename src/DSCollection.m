//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <pthread.h>
#import "DSCollection.h"
#import "DSModel.h"

@implementation DSCollection

- (id) init
{
  self = [self initWithCapacity:10];
  return self;
}

- (id) initWithCapacity:(NSUInteger)cap
{
  if ((self = [super init])) {
    models = [[NSMutableDictionary alloc] initWithCapacity:cap];
    ordered = [[NSMutableArray alloc] initWithCapacity:cap];
    pthread_rwlock_init(&rwlock, NULL);
  }
  return self;
}


#pragma mark -- Utility --

- (NSUInteger) count
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
  return [models objectForKey:model.key] != nil;
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
  if (model.key == nil || [model.key length] < 1) {
    // NSLog(@"DS_ERROR: Inserted model with bad key into Collection.");
    return;
  }

  if ([self containsModel:model])
    return;

  [models setObject:model forKey:model.key];
  [ordered addObject:model.key];
}

- (void) insertModel:(DSModel *)model atIndex:(NSUInteger)index
{
  if (model.key == nil || [model.key length] < 1) {
    return;
  }

  [models setObject:model forKey:model.key];
  [ordered removeObject:model.key]; // In case it's already there.
  [ordered insertObject:model.key atIndex:index];
}

#pragma mark -- Removing --

- (void) removeModel:(DSModel *)model
{
  if ([self containsModel:model]) {
    [ordered removeObject:model.key];
    [models removeObjectForKey:model.key];
  }
}

- (void) removeModelAtIndex:(NSUInteger)index
{
  NSString *key = [ordered objectAtIndex:index];
  if (key != nil && [key length] >= 1) {
    [ordered removeObjectAtIndex:index];
    [models removeObjectForKey:key];
  }
}

- (void) removeModelForKey:(NSString *)key
{
  DSModel *model = [models objectForKey:key];
  if (model != nil) {
    [ordered removeObject:key];
    [models removeObjectForKey:key];
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

- (id) modelAtIndex:(NSUInteger)index
{
  return [models objectForKey: [ordered objectAtIndex:index]];
}

- (id) randomModel
{
  return [self modelAtIndex: arc4random() % [ordered count]];
}

- (NSUInteger) indexOfKey:(NSString *)key
{
  return [ordered indexOfObject:key];
}

- (NSUInteger) indexOfModel:(DSModel *)model
{
  return [ordered indexOfObject:model.key];
}

- (NSUInteger) randomIndex
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
      [ordered addObject:model.key];
  }
}

- (void) dealloc
{
  pthread_rwlock_destroy(&rwlock);
  [ordered release];
  [models release];
  [super dealloc];
}

#pragma mark -- Static Construction --

+ (DSCollection *) collection
{
  return [[[DSCollection alloc] init] autorelease];
}

+ (DSCollection *) collectionWithArray:(NSArray *)array {
  DSCollection *coll = [DSCollection collectionWithCapacity:[array count]];
  for (DSModel *model in array)
    [coll insertModel:model];
  return coll;
}

+ (DSCollection *) collectionWithCapacity:(NSUInteger)cap {
    return [[[DSCollection alloc] initWithCapacity:cap] autorelease];
}

+ (DSCollection *) collectionWithCollection:(DSCollection *)coll {
  DSCollection *new = [DSCollection collectionWithCapacity:[coll count]];
  [new addCollection:coll];
  return new;
}

@end


