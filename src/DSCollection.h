//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@class DSKey;
@class DSModel;
@class DSCollection;

struct pthread_rwlock_t;

@interface DSCollection : NSObject <NSFastEnumeration> {

  NSMutableDictionary *models;
  NSMutableArray *ordered;
  pthread_rwlock_t rwlock;

}

- (id)initWithCapacity:(NSUInteger)cap;

- (NSUInteger) count;

- (BOOL) containsModel:(DSModel *)model;

- (NSArray *) arrayForMutableEnumeration;

- (NSArray *) keys;
- (NSArray *) models;

- (DSCollection *) copy;

- (void) readLock;
- (void) writeLock;
- (void) unlock;

- (void) addCollection:(DSCollection *)collection;
- (void) addModelsInArray:(NSArray *)array;

- (void) insertModel:(DSModel *)model;
- (void) insertModel:(DSModel *)model atIndex:(NSUInteger)index;

- (void) removeModel:(DSModel *)model;
- (void) removeModelAtIndex:(NSUInteger)index;
- (void) removeModelForKey:(DSKey *)key;

- (void) removeModelsInArray:(NSArray *)array;
- (void) removeAllModels;
- (void) clear;

- (id) modelForKey:(DSKey *)key;
- (id) modelAtIndex:(NSUInteger)index;
- (id) randomModel;

- (NSUInteger) indexOfKey:(DSKey *)key;
- (NSUInteger) indexOfModel:(DSModel *)model;
- (NSUInteger) randomIndex;

- (void) sortUsingSelector:(SEL)selector;

+ (DSCollection *) collection;
+ (DSCollection *) collectionWithArray:(NSArray *)array;
+ (DSCollection *) collectionWithCapacity:(NSUInteger)cap;
+ (DSCollection *) collectionWithCollection:(DSCollection *)collection;

@end
