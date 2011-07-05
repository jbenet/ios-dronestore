//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//


#import "DSSerializable.h"

@class DSDrone;

@interface DSModel : NSObject <DSDictSerializable, DSDataSerializable> {


  NSString *ds_key_; // standard UUID on create
  NSString *ds_owner_; // ds_key_ of owner dronw
  // NSString *ds_type_; // name of the model.

  // Times
  NSDate *ds_created_; // Time of creation
  NSDate *ds_updated_; // Time of last modification
  NSDate *ds_expire_; // Time of expiration from current drone.

  NSNumber *ds_access_;  // permissions awarded (read, lease, write)

// Owner Only
  NSNumber *dso_lease_; // Time to lease out to others. in seconds. (=1000)
  NSArray *dso_backup_; // [droneid, ...] (backed up in all drones)
  NSArray *dso_backupx_; // [droneid, ...] (backed up in any drone (one))

  DSDrone *drone;
  BOOL dirty;
}

@property (nonatomic, copy) NSString *ds_key_;
@property (nonatomic, copy) NSString *ds_owner_;
@property (nonatomic, copy, readonly) NSString *ds_type_;

@property (nonatomic, retain) NSDate *ds_created_;
@property (nonatomic, retain) NSDate *ds_updated_;
@property (nonatomic, retain) NSDate *ds_expire_;
@property (nonatomic, copy) NSNumber *ds_access_;
@property (nonatomic, copy) NSNumber *dso_lease_;
@property (nonatomic, retain) NSArray *dso_backup_;
@property (nonatomic, retain) NSArray *dso_backupx_;

@property (nonatomic, assign, readonly) DSDrone *drone;
@property (nonatomic, assign) BOOL dirty;

- (id) initWithDrone:(DSDrone *)drone;

- (id) initNew;
- (id) initNewWithDrone:(DSDrone *)drone;

- (id) initWithKey:(NSString *)key;
- (id) initWithKey:(NSString *)key andDrone:(DSDrone *)drone;

- (void) modelInit;

- (BOOL) isEqual:(DSModel *)other;
- (BOOL) hasExpired;

- (BOOL) invariantsHold;

- (BOOL) load;
- (BOOL) save;
- (BOOL) cache;
- (BOOL) delete;

- (BOOL) loadRemote;
- (BOOL) saveRemote;

- (BOOL) loadLocal;
- (BOOL) saveLocal;

- (int) createdCompare:(DSModel *)other;
- (int) updatedCompare:(DSModel *)other;

- (void) loadDict:(NSDictionary *)dict;
+ (id) modelFromDict:(NSDictionary *)dict;
+ (id) modelFromDict:(NSDictionary *)dict andDrone:(DSDrone *)drone;
- (NSMutableDictionary *) toDict;

- (void) loadData:(NSData *)data;
+ (id) modelFromData:(NSData *)data;
+ (id) modelFromData:(NSData *)data andDrone:(DSDrone *)drone;
- (NSData *) data;

+ (NSDictionary *) otherQueriableProperties;

+ (id) modelForKey:(NSString *)key;
+ (id) modelForKey:(NSString *)key andDrone:(DSDrone *)drone;

+ (NSString *) ds_type_;
+ (Class) classFromType:(NSString *)ds_type_;

@end

