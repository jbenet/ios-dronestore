
#import <Foundation/Foundation.h>

// A Datastore represents storage for serialized dronestore versions.
// Datastores are general enough to be backed by all kinds of different storage:
// in-memory caches, databases, a remote cache, flat files on disk, etc.
//
// The general idea is to wrap a more complicated storage facility in a simple,
// uniform interface, keeping the freedom of using the right tools for the job.
// In particular, Datastores can aggregate other datastores in interesting ways,
// like sharded (to distribute load) or tiered access (caches before databases).
//
// While Datastores should be written general enough to accept all sorts of
// values, some implementations will undoubtedly have to be specific (e.g. SQL
// databases where fields should be decomposed into columns), particularly those
// that support Queries.
//
// This interface matches the Drone's well, as it supports each of its calls.
//

// this interface includes both the proper dronestore Datasource interface
// and a more objective-c style interface.


@class DSKey;
@class DSQuery;

// Abstract interface. subclass it.
@interface DSDatastore : NSObject {}

// dronestore datasource interface (override these)
- (id) get:(DSKey *)key;
- (void) put:(NSObject *)object forKey:(DSKey *)key;
- (void) delete:(DSKey *)key;
- (BOOL) contains:(DSKey *)key;
- (NSArray *) query:(DSQuery *)query;

// obj-c interface
- (NSObject *) valueForKey:(DSKey *)key;
- (void) setValue:(NSObject *)object forKey:(DSKey *)key;

- (NSObject *) objectForKey:(DSKey *)key;
- (void) setObject:(NSObject *)object forKey:(DSKey *)key;

- (void) removeObjectForKey:(DSKey *)key;
@end



// Simple straw-man in-memory datastore backed by a dict.
//
// WARNING: it does not evict entries so it will grow indefinitely. use this for
//   testing, short-lived, or small working-set programs.
@interface DSDictionaryDatastore : DSDatastore {
  NSMutableDictionary *dict;
}
- (long) count;
@end


// Slightly better DSDictionaryDatastore
//
// WARNING: unless explicitly called, it only evicts entries on memory warnings.
// and even then, only removes entries whose retainCounts are one.
@interface DSCacheDatastore : DSDictionaryDatastore {
}
- (void) removeUnusedObjects;
@end



// Abstract interface for collections of datastores
@interface DSDatastoreCollection : DSDatastore {
  NSMutableArray *stores;
}

@property (nonatomic, readonly) NSArray *stores;

- (id) initWithDatastores:(NSArray *)stores;

- (DSDatastore *) datastoreAtIndex:(int)index;
- (void) addDatastore:(DSDatastore *)store;
- (void) insertDatastore:(DSDatastore *)store atIndex:(int)index;
- (void) removeDatastore:(DSDatastore *)store;
@end


// Represents a hierarchical collection of datastores.
// Each datastore is queried in order. This is helpful to organize access
// in terms of speed (i.e. hit caches first).
@interface DSTieredDatastore : DSDatastoreCollection {}
@end


// Represents a collection of datastore shards.
// A datastore is selected based on a sharding function.
//
// sharding functions should take a Key and return an integer.
//
// WARNING: adding or removing datastores while running may severely affect
//          consistency. Also ensure the order is correct upon initialization.
//          While this is not as important for caches, it is crucial for
//          persistent atastore.
@interface DSShardedDatastore : DSDatastoreCollection {}
- (int) hashForKey:(DSKey *)key;
@end

