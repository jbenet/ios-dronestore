//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@class DSCollection;
@class DSModel;

@interface DSCache : NSObject {

  DSCollection *objects;
}

- (DSModel *) modelForKey:(NSString *)dskey;
- (void) insertModel:(DSModel *)object;
- (int) count;
- (void) collectGarbage;

@end
