
#import <Foundation/Foundation.h>
#import "DSDatastore.h"
#import "DSQuery.h"
#import "DSKey.h"

@implementation DSDatastore

- (id) get:(DSKey *)key {
  [NSException raise:@"DSNotImplemented" format:@"%@ get: not implemented",
    [self class]];
  return nil;
}
- (void) put:(NSObject *)object forKey:(DSKey *)key {
  [NSException raise:@"DSNotImplemented" format:@"%@ put:forKey: not "
    "implemented", [self class]];
}
- (void) delete:(DSKey *)key {
  [NSException raise:@"DSNotImplemented" format:@"%@ delete: not implemented",
    [self class]];
}
- (BOOL) contains:(DSKey *)key {
  [NSException raise:@"DSNotImplemented" format:@"%@ contains: not implemented",
    [self class]];
  return NO;
}
- (NSArray *) query:(DSQuery *)query {
  [NSException raise:@"DSNotImplemented" format:@"%@ query: not implemented",
    [self class]];
  return nil;
}


- (NSObject *) valueForKey:(DSKey *)key {
  return [self get:key];
}

- (void) setValue:(NSObject *)object forKey:(DSKey *)key {
  if (object == nil)
    [self delete:key];
  else
    [self put:object forKey:key];
}

- (NSObject *) objectForKey:(DSKey *)key {
  return [self get:key];
}

- (void) setObject:(NSObject *)object forKey:(DSKey *)key {
  [self put:object forKey:key];
}

- (void) removeObjectForKey:(DSKey *)key {
  [self delete:key];
}

- (BOOL) containsObjectForKey:(DSKey *)key {
  return [self contains:key];
}

@end



@implementation DSDictionaryDatastore

- (id) init {
  if ((self = [super init])) {
    dict = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void) dealloc {
  [dict release];
  [super dealloc];
}

- (long) count {
  return [dict count];
}

- (id) get:(DSKey *)key {
  return [dict valueForKey:key.string];
}
- (void) put:(NSObject *)object forKey:(DSKey *)key {
  [dict setValue:object forKey:key.string];
}
- (void) delete:(DSKey *)key {
  [dict setValue:nil forKey:key.string];
}
- (BOOL) contains:(DSKey *)key {
  return [dict valueForKey:key.string] != nil;
}
- (NSArray *) query:(DSQuery *)query {
  return [query operateOnArray:[dict allValues]];
}
@end

// Abstract interface for collections of datastores
@implementation DSDatastoreCollection

@synthesize stores;

- (id) init {
  if ((self = [super init])) {
    stores = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id) initWithDatastores:(NSArray *)_stores {
  if ((self = [self init])) {
    [stores addObjectsFromArray:_stores];
  }
  return self;
}

- (DSDatastore *) datastoreAtIndex:(int)index {
  return [stores objectAtIndex:index];
}

- (void) addDatastore:(DSDatastore *)store {
  [stores addObject:store];
}

- (void) insertDatastore:(DSDatastore *)store atIndex:(int)index {
  [stores insertObject:store atIndex:index];
}
- (void) removeDatastore:(DSDatastore *)store {
  [stores removeObject:store];
}
@end



@implementation DSTieredDatastore

- (id) get:(DSKey *)key {
  for (DSDatastore *store in stores) {
    NSObject *val = [store get:key];
    if (val)
      return val;
  }
  return nil;
}
- (void) put:(NSObject *)object forKey:(DSKey *)key {
  for (DSDatastore *store in stores) {
    [store put:object forKey:key];
  }
}
- (void) delete:(DSKey *)key {
  for (DSDatastore *store in stores) {
    [store delete:key];
  }
}
- (BOOL) contains:(DSKey *)key {
  for (DSDatastore *store in stores) {
    if ([store contains:key])
      return YES;
  }
  return NO;
}
- (NSArray *) query:(DSQuery *)query {
  DSDatastore *store = [stores objectAtIndex:[stores count] - 1];
  return [store query:query];
}
@end


// WARNING: adding or removing datastores while running may severely affect
//          consistency. Also ensure the order is correct upon initialization.
//          While this is not as important for caches, it is crucial for
//          persistent atastore.
@implementation DSShardedDatastore

- (int) hashForKey:(DSKey *)key {
  //USE murmur here.
  int count = 0;
  for (int i = 0; i < [key.string length]; i++)
    count += [key.string characterAtIndex:i];
  return count;
}

- (int) shardForKey:(DSKey *)key {
  return [self hashForKey:key];
}

- (DSDatastore *) shardDatasourceForKey:(DSKey *)key {
  return [self datastoreAtIndex:[self shardForKey:key] % (int)[stores count]];
}


- (id) get:(DSKey *)key {
  return [[self shardDatasourceForKey:key] get:key];
}
- (void) put:(NSObject *)object forKey:(DSKey *)key {
  [[self shardDatasourceForKey:key] put:object forKey:key];
}
- (void) delete:(DSKey *)key {
  [[self shardDatasourceForKey:key] delete:key];
}
- (BOOL) contains:(DSKey *)key {
  return [[self shardDatasourceForKey:key] contains:key];
}
- (NSArray *) query:(DSQuery *)query {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (DSDatastore *store in stores)
    [array addObjectsFromArray:[store query:query]];
  return [query operateOnArray:[array autorelease]];
}
@end



