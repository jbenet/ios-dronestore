//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSSecurity.h"
#import "NSData+AES256.h"

@implementation DSSecurity

- (BOOL) isSecure {
  return NO;
}

- (NSData *) encryptMessage:(NSData *)message {
  return message;
}
- (NSData *) decryptMessage:(NSData *)message {
  return message;
}

+ (DSSecurity *) noSecurity {
  return [[[DSSecurity alloc] init] autorelease];
}

@end

//------------------------------------------------------------------------------

@implementation AESSecurity
@synthesize secret;

- (void) dealloc {
  self.secret = nil;
  [super dealloc];
}

- (BOOL) isSecure {
  return YES; //FIXME set to NO;
}

- (NSData *) encryptMessage:(NSData *)message {
  return [message AES256EncryptWithKey:secret];
}
- (NSData *) decryptMessage:(NSData *)message {
  return [message AES256DecryptWithKey:secret];
}

+ (AESSecurity *) securityWithSecret:(NSString *)secret {
  AESSecurity *security = [[AESSecurity alloc] init];
  security.secret = secret;
  return [security autorelease];
}

//------------------------------------------------------------------------------

@end


