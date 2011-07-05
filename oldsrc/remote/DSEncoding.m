//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSEncoding.h"
#import "DSRequest.h"
#import <YAJL/YAJL.h>

@implementation DSEncoding

- (NSData *) encodeRequest:(DSRequest *)request {
  [NSException raise:@"Encoding" format:@"encoding unsupported"];
  return nil;
}

- (DSRequest *) decodeRequest:(NSData *)request {
  [NSException raise:@"Encoding" format:@"decoding unsupported"];
  return nil;
}

+ (DSEncoding *) dataEncoding {
  return [[[DSEncoding alloc] init] autorelease];
}

@end

//------------------------------------------------------------------------------

@implementation JSONEncoding

- (NSData *) encodeRequest:(DSRequest *)request {
  NSString *string = [request yajl_JSONString];
  // NSLog(@">>> Encoding: %@", string);
  return [string dataUsingEncoding:NSASCIIStringEncoding];
}

- (DSRequest *) decodeRequest:(NSData *)request {
  NSString *str;
  str = [[NSString alloc] initWithData:request encoding:NSASCIIStringEncoding];
  // NSLog(@"<<< Decoding: %@", str);
  return [DSRequest requestFromDict:[[str autorelease] yajl_JSON]];
}

+ (JSONEncoding *) jsonEncoding {
  return [[[JSONEncoding alloc] init] autorelease];
}

@end