//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@class DSRequest;

@interface DSEncoding : NSObject {

}

- (NSData *) encodeRequest:(DSRequest *)request;
- (DSRequest *) decodeRequest:(NSData *)request;
+ (DSEncoding *) dataEncoding;

@end;

//------------------------------------------------------------------------------

@interface JSONEncoding : DSEncoding {}
+ (JSONEncoding *) jsonEncoding;
@end

