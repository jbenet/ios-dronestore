//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSSerializable.h"

@class DSModel;
@class DSCollection;
@class DSDrone;
struct pthread_rwlock_t;

@protocol DSCollectionDelegate

- (void) didUpdateCollection:(DSCollection *)collection;

@end

@interface DSCollection : NSObject <NSFastEnumeration, DSArraySerializable> {

  NSMutableDictionary *models;
  NSMutableArray *ordered;
  NSMutableArray *delegates;
  pthread_rwlock_t rwlock;

}

- (id)initWithCapacity:(int)cap;

- (void) addDelegate:(id)delegate;
- (void) removeDelegate:(id)delegate;

- (void) updated;
- (int) count;
- (BOOL) containsModel:(DSModel *)model;
- (NSArray *) arrayForMutableEnumeration;
- (NSArray *) ordered;
- (NSArray *) keys;
- (NSArray *) models;
- (NSData *) data;
- (DSCollection *) copy;

- (void) readLock;
- (void) writeLock;
- (void) unlock;

- (void) addCollection:(DSCollection *)collection;
- (void) addModelsInArray:(NSArray *)array;

- (void) insertModel:(DSModel *)model;
- (void) insertModel:(DSModel *)model atIndex:(int)index;

- (void) removeModel:(DSModel *)model;
- (void) removeModelAtIndex:(int)index;
- (void) removeModelForKey:(NSString *)key;

- (void) removeModelsInArray:(NSArray *)array;
- (void) removeAllModels;
- (void) clear;

- (id) modelForKey:(NSString *)key;
- (id) modelAtIndex:(int)index;
- (id) randomModel;

- (int) indexOfKey:(NSString *)key;
- (int) indexOfModel:(DSModel *)model;
- (int) randomIndex;

- (void) loadArray:(NSArray *)array withDrone:(DSDrone *)drone;
- (void) loadArray:(NSArray *)array;
- (NSMutableArray *)toArray;

- (void) sortUsingSelector:(SEL)selector;

+ (DSCollection *) collection;
+ (DSCollection *) collectionWithData:(NSData *)data;
+ (DSCollection *) collectionWithData:(NSData *)data andDrone:(DSDrone *)drone;
+ (DSCollection *) collectionWithArray:(NSArray *)array;
+ (DSCollection *) collectionWithArray:(NSArray *)array andDrone:(DSDrone *)dr;
+ (DSCollection *) collectionWithCapacity:(int)cap;
+ (DSCollection *) collectionWithCollection:(DSCollection *)collection;

@end
