//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSModel.h"

@class DSConnection;
@class DSDatabase;

@interface DSDrone : DSModel {

  NSString *droneid;

  NSDateFormatter *dateFormatter;
  NSTimeInterval systemTimeOffset;
}

@property (nonatomic, copy) NSString *droneid;

@property (nonatomic, assign) NSTimeInterval systemTimeOffset;
@property (nonatomic, retain) NSDate *systemDate;

@property (retain) NSDateFormatter *dateFormatter;


- (id) get:(DSKey *)key;
- (id) put:(DSVersion *)version;
- (id) merge:(DSVersion *)version;
- (id) contains:(DSKey *)key;
- (id) delete:(DSKey *)key;


- (id) modelForKey:(DSKey *)key;


- (NSString *) stringFromDate:(NSDate *)date;
- (NSDate *) dateFromString:(NSString *)string;

@end
