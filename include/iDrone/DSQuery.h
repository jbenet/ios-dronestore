//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSSerializable.h"

@class DSDrone;
@class DSCallback;
@class DSCollection;
@class DSLocalDrone;

@interface DSQuery : NSObject <DSDictSerializable> {

  // query
  BOOL keysOnly;
  int offset;
  int limit;
  NSString *ds_type_;
  NSMutableArray *order;
  NSMutableArray *filter;

  // query extra
  NSString *droneid;
  DSCallback *callback;

  // result
  int count;
  BOOL didRun;
  BOOL didSucceed;
  NSMutableArray *keys;
  DSCollection *models;
}

@property (nonatomic, assign) BOOL keysOnly;
@property (nonatomic, assign) int limit;
@property (nonatomic, assign) int offset;
@property (nonatomic, copy) NSString *ds_type_;
@property (nonatomic, copy) NSMutableArray *order;
@property (nonatomic, copy) NSMutableArray *filters;

@property (nonatomic, retain) NSString *droneid;
@property (nonatomic, retain) DSCallback *callback;

@property (nonatomic, readonly) int count;
@property (nonatomic, readonly) BOOL didRun;
@property (nonatomic, readonly) BOOL didSucceed;
@property (nonatomic, readonly) NSMutableArray *keys;
@property (nonatomic, readonly) DSCollection *models;

- (void) filterByField:(NSString *)field value:(NSObject *)value;

- (void) orderByField:(NSString *)field ascending:(BOOL)ascending;
- (void) ascendingOrderByField:(NSString *)field;
- (void) descendingOrderByField:(NSString *)field;

- (int) count;

- (void) runWithLocalDrone:(DSLocalDrone *)local wait:(BOOL)wait;
- (void) queryRanWithCallback:(DSCallback *)callback;

- (NSString *) SQLWhereWithArguments:(NSMutableArray *)arguments;

+ (DSQuery *) queryDroneID:(NSString *)droneid;
+ (DSQuery *) queryDroneID:(NSString *)droneid ForType:(NSString *)type;

@end


