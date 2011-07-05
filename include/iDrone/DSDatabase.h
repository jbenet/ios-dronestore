//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

//@class DSCall;
@class DSModel;
@class DSCache;
@class FMDatabase;
@class DSDrone;
@class DSQuery;
struct pthread_mutex_t;

@interface DSDatabase : NSObject {

  DSCache *cache;
  NSString *name;

  FMDatabase *fmdb;
  pthread_mutex_t fmdb_lock;

  DSDrone *drone; // parent.
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign, readonly) DSDrone *drone;


- (id) initWithName:(NSString *)name_ andDrone:(DSDrone *)drone_;

- (void) initializeDatabase;

- (void) upkeep;

- (id) modelForKey: (NSString *)key;
- (id) modelForKey: (NSString *)key withClass:(Class) modelClass;

- (BOOL) loadModel:(DSModel *)model;
- (BOOL) saveModel:(DSModel *)model;
- (BOOL) cacheModel:(DSModel *)model;
- (BOOL) insertModel:(DSModel *)model;


- (void) runQuery:(DSQuery *)query;

+ (NSString *) pathForName:(NSString *)name;
+ (void) deleteDatabaseNamed:(NSString *)name;

+ (DSDatabase *) databaseWithName:(NSString *)name_ andDrone:(DSDrone *)drone_;

@end

