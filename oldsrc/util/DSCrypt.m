//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSCrypt.h"
#import "NSData+Base64.h"
#import "NSData+AES256.h"

@implementation DSCrypt

@synthesize AESKey;

- (id) initWithKey:(NSString *)key {
  if (self = [super init])
  {
    encode = YES;
    base64 = NO;
    aes256 = YES;
    self.AESKey = key;
  }
  return self;
}

- (NSData *) encodeData:(NSData *)data
{
  if (!encode) return data;
  if (base64) data = [self base64EncodeData:data];
  if (aes256) data = [self AES256EncryptData:data];
  return data;
}

- (NSData *) decodeData:  (NSData *)data
{
  if (!encode) return data;
  if (aes256) data = [self AES256DecryptData:data];
  if (base64) data = [self base64DecodeData:data];
  return data;
}

- (NSData *)   encodedDataFromString:(NSString *)message
{
  return [self encodeData:[message dataUsingEncoding:NSASCIIStringEncoding]];
}

+ (NSData *)   encodedStringFromString:(NSString *)message
{
  NSData *data = [self encodeData:[message dataUsingEncoding:NSASCIIStringEncoding]];
  NSString *secret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  return [secret autorelease];
}

- (NSString *) decodedStringFromData:(NSData *)secret
{
  return [APISecurity decodedStringFromData:secret encoding:NSASCIIStringEncoding];
}

- (NSString *) decodedStringFromData:(NSData *) secret encoding:(NSStringEncoding) encoding
{
  NSString *string;
  string = [[NSString alloc] initWithData:[self decodeData:secret] encoding:encoding];
  return [string autorelease];
}

- (NSData *) base64EncodeData:(NSData *)data
{
  return [data base64EncodedData];
}

- (NSData *) base64DecodeData:(NSData *)data
{
  return [data base64DecodedData];
}

- (NSData *) AES256EncryptData: (NSData *)message
{
  if (AESKey == nil) return message;
  return [data AES256EncryptWithKey:self.AESKey];
}

- (NSData *) AES256DecryptData: (NSData *)message
{
  if (AESKey == nil) return message;
  return [data AES256DecryptWithKey:self.AESKey];
}

- (void) dealloc {
  self.AESKey = nil;
  [super dealloc];
}

+ (NSString *) md5hash:(NSString *)text
{
  NSData *data = [text dataUsingEncoding: NSUTF8StringEncoding];
  unsigned char *digest = MD5([data bytes], [data length], NULL);
  return [NSString stringWithUTF8String: (char *)digest];
}



@end
