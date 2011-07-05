//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <YAJL/YAJL.h>

@protocol DSSerializable

@end

@protocol DSDictSerializable <DSSerializable, YAJLCoding>

- (void) loadDict:(NSDictionary *)dict;
- (NSMutableDictionary *) toDict;

@end

@protocol DSArraySerializable <DSSerializable, YAJLCoding>

- (void) loadArray:(NSArray *)array;
- (NSMutableArray *) toArray;

@end

@protocol DSDataSerializable <DSSerializable>

- (void) loadData:(NSData *)data;
- (NSData *) data;

@end
