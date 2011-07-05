//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSSerializable.h"

@class DSCall;
@class DSConnection;

@interface DSRequest : NSObject <NSFastEnumeration, DSDictSerializable> {

  NSMutableArray *calls;
  NSString *fromDrone;
  NSString *toDrone;
  NSDate *date;
}

@property (retain) NSMutableArray *calls;
@property (copy) NSString *fromDrone;
@property (copy) NSString *toDrone;

@property (nonatomic, retain) NSDate *date;

- (void) addCall:(DSCall *) call;
- (int) count;

+ (NSDate *) dateFromSerialTime:(NSNumber *)serialized;
+ (NSNumber *) serialTimeFromDate:(NSDate *)date;

+ (DSRequest *) requestFromDict:(NSDictionary *)dict;
+ (DSRequest *) requestWithConnection:(DSConnection *)conn;
+ (DSRequest *) requestWithConnection:(DSConnection *)conn
                             andCalls:(NSArray *)calls;

@end



