//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <iDrone/DSModel.h>
@class DSConnection;
@class DSCollection;
@class DSCallback;
@class DSDrone;
@class DSQuery;

@interface DSCall : DSModel {

  NSMutableDictionary *parameters;
  DSConnection *connection;

  NSString *type;
  BOOL isAnnonymous;
  int callbackId;
  DSCallback *callback;
}

@property (retain) NSMutableDictionary *parameters;
@property (retain) DSConnection *connection;

@property (copy, readonly) NSString *type;
@property (assign) BOOL isAnnonymous;
@property (assign) int callbackId;
@property (retain) DSCallback *callback;
@property (copy, readonly) NSString *callbackString;

- (id) initWithType:(NSString *)type;

- (NSString *) handle;
- (NSString *) handleSYN;
- (NSString *) handleWHO;
- (NSString *) handleERR;
- (NSString *) handleGET;
- (NSString *) handleSET;
- (NSString *) handleQRY;

- (void) setValue:(id)object forParameter:(NSString *)param;
- (id) valueForParameter:(NSString *)param;
- (void) requireParameters:(NSArray *)params;

- (void) respondWithCall:(DSCall *)call;

- (id)proxyForJson;
- (NSMutableDictionary *) toDict;
- (void) loadDict:(NSDictionary *)dict;
+ (DSCall *) callFromDict:(NSDictionary *)dict;

+ (DSCall *) callWithType:(NSString *)type;

+ (DSCall *) SYNCallWithLocalDrone:(DSDrone *)ld;
+ (DSCall *) WHOCall;
+ (DSCall *) ERRCallWithMessage:(NSString *)message;

+ (DSCall *) GETCallWithKey:(NSString *)ds_key;
+ (DSCall *) GETCallWithKey:(NSString *)ds_key andClass:(Class)modelClass;
+ (DSCall *) GETCallWithModel:(DSModel *)model;

+ (DSCall *) SETCallWithModel:(DSModel *)model;
+ (DSCall *) SETCallWithCollection:(DSCollection *)models;
+ (DSCall *) QRYCallWithQuery:(DSQuery *)query;

@end



