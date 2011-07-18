//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSModel.h"

@class DSKey;
@class DSCollection;

struct pthread_rwlock_t;

@interface DSCollection : NSObject <NSFastEnumeration, DSModelContainer> {

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

// alias for insertModel:, complies with DSModelContainer
- (void) addModel:(DSModel *)model;
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
- (BOOL) isEqualToCollection:(DSCollection *)collection;

+ (DSCollection *) collection;
+ (DSCollection *) collectionWithArray:(NSArray *)array;
+ (DSCollection *) collectionWithCapacity:(NSUInteger)cap;
+ (DSCollection *) collectionWithCollection:(DSCollection *)collection;

@end
