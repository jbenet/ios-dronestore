
#import "NSString+SHA.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (DS_SHA)

- (NSString *) sha1HexDigest {
  return [NSString sha1HexDigestFrom:self];
}

+ (NSString *) sha1HexDigestFrom:(NSString *) input
{
  unsigned char hashed[32];
  CC_SHA1([input UTF8String],
          [input lengthOfBytesUsingEncoding:NSASCIIStringEncoding],
          hashed);

  NSMutableString *hex = [[[NSMutableString alloc] init] autorelease];
  for (int i = 0; i < 32; i++)
    [hex appendFormat:@"%02x", hashed[i]];

  return hex;
}

- (NSString *) sha256HexDigest {
  return [NSString sha256HexDigestFrom:self];
}

+ (NSString *) sha256HexDigestFrom:(NSString *) input
{
  unsigned char hashed[32];
  CC_SHA256([input UTF8String],
            [input lengthOfBytesUsingEncoding:NSASCIIStringEncoding],
            hashed);

  NSMutableString *hex = [[[NSMutableString alloc] init] autorelease];
  for (int i = 0; i < 32; i++)
    [hex appendFormat:@"%02x", hashed[i]];

  return hex;
}

@end