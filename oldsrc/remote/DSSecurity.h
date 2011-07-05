//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSConnection.h"

@interface DSSecurity : NSObject {

}

- (BOOL) isSecure;
- (NSData *) encryptMessage:(NSData *)message;
- (NSData *) decryptMessage:(NSData *)message;
+ (DSSecurity *) noSecurity;

@end

//------------------------------------------------------------------------------

@interface AESSecurity : DSSecurity {
  NSString *secret;
}
@property (nonatomic, copy) NSString *secret;
+ (AESSecurity *) securityWithSecret:(NSString *)secret;
@end


