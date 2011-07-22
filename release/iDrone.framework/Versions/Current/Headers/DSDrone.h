
#import <Foundation/Foundation.h>
#import "DSModel.h"

// Drone represents the logical unit of storage in dronestore.
// Each drone consists of a datastore (or set of datastores) and an id.
//

@class DSKey;
@class DSModel;
@class DSVersion;
@class DSSerialRep;
@class DSDatastore;
@class DSQuery;
@class DSCollection;
@protocol DSModel;

@interface DSDrone : NSObject <DSModelContainer> {
  DSKey *droneid;
  DSDatastore *datastore;
}

@property (nonatomic, readonly) DSDatastore *datastore;
@property (nonatomic, readonly) DSKey *droneid;


- (id) initWithId:(DSKey *)key andDatastore:(DSDatastore *)store;

// Dronestore drone interface. sorry its not more obj-c-like!
- (id<DSModel>) get:(DSKey *)key;
- (id<DSModel>) put:(DSModel *)instance;
- (id<DSModel>) merge:(DSModel *)instance;
- (void) delete:(DSKey *)key;
- (BOOL) contains:(DSKey *)key;
- (DSCollection *) query:(DSQuery *)query;

- (DSVersion *) putVersion:(DSVersion *)version;
- (DSModel *) mergeVersion:(DSVersion *)version;

@end


