
#import <Foundation/Foundation.h>

// Drone represents the logical unit of storage in dronestore.
// Each drone consists of a datastore (or set of datastores) and an id.
//

@class DSKey;
@class DSModel;
@class DSVersion;
@class DSSerialRep;
@class DSDatastore;

@interface DSDrone : NSObject {
  DSKey *droneid;
  DSDatastore *datastore;
}

@property (nonatomic, readonly) DSDatastore *datastore;
@property (nonatomic, readonly) DSKey *droneid;


- (id) initWithId:(DSKey *)key andDatastore:(DSDatastore *)store;

// Dronestore drone interface. sorry its not more obj-c-like!
- (DSModel *) get:(DSKey *)key;
- (DSModel *) put:(DSModel *)instance;
- (DSModel *) merge:(DSModel *)instance;
- (void) delete:(DSKey *)key;
- (BOOL) contains:(DSKey *)key;

- (DSVersion *) putVersion:(DSVersion *)version;
- (DSModel *) mergeVersion:(DSVersion *)version;


@end


