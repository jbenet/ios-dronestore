//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <iDrone/DSDrone.h>

@class DSQuery;

@interface DSLocalDrone : DSDrone {

  NSString *systemid;
  NSString *deviceid;
  NSString *userid;

  NSMutableDictionary *connections;
  DSDatabase *database;

  NSThread *janitor;
}

@property (nonatomic, copy) NSString *systemid;
@property (nonatomic, copy) NSString *deviceid;
@property (nonatomic, copy) NSString *userid;

@property (nonatomic, readonly) DSDatabase *database;

- (id) initWithSystemID:(NSString *)system userID:(NSString *)user;
- (id) initWithDroneID:(NSString *)droneid;

- (void) addRemoteDroneID:(NSString *)droneid withURL:(NSString *)url;
- (BOOL) knowsRemoteDroneID:(NSString *)droneid;

- (void) flushConnections;
- (void) flushConnectionsAndWait:(BOOL)wait;

- (void) runQuery:(DSQuery *)query wait:(BOOL)wait;

- (NSString *) generateKeyHash;

+ (NSString *) device;

+ (DSLocalDrone *)localDroneWithSystemID:(NSString*)sys userID:(NSString*)user;
+ (DSLocalDrone *)localDroneWithDroneID:(NSString *)droneid;
@end
