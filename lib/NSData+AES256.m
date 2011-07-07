//
//  NSData+AES.h
//

#import <CommonCrypto/CommonCryptor.h>


@implementation NSData (AES256)

- (NSData *) cryptOperation:(CCOperation)operation withKey:(NSString *)keyStr
  andIV: (NSString *)iv {

  // 'key' should be 32 bytes for AES256, will be null-padded otherwise
  char key[kCCKeySizeAES256];
  [keyStr getCString:key maxLength:sizeof(key) encoding:NSUTF8StringEncoding];

  // Perform PKCS7Padding on the key.
  unsigned long bytes_to_pad = sizeof(key) - [keyStr length];
  if (bytes_to_pad > 0) {
    char byte = bytes_to_pad;
    for (unsigned long i = sizeof(key) - bytes_to_pad; i < sizeof(key); i++)
      key[i] = byte;
  }

  NSUInteger dataLength = [self length];

  //See the doc: For block ciphers, the output size will always be less than or
  //equal to the input size plus the size of one block.
  //That's why we need to add the size of one block here
  size_t bufferSize = dataLength + kCCBlockSizeAES128;
  void *buffer = malloc(bufferSize);

  size_t numBytesDecrypted = 0;
  CCCryptorStatus status = CCCrypt(operation, kCCAlgorithmAES128,
                                   kCCOptionPKCS7Padding,
                                   key, kCCKeySizeAES256,
                                   [iv UTF8String],
                                   [self bytes], dataLength, /* input */
                                   buffer, bufferSize, /* output */
                                   &numBytesDecrypted);

  if (status == kCCSuccess) {
    //the returned NSData takes ownership of buffer and will free it on dealloc
    return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
  }

  free(buffer); //free the buffer;
  return nil;
}

- (NSData *)AES256EncryptWithKey:(NSString *)key andIV: (NSString *)iv {
  return [self cryptOperation:kCCEncrypt withKey:key andIV:iv];
}

- (NSData *)AES256DecryptWithKey:(NSString *)key andIV: (NSString *)iv {
  return [self cryptOperation:kCCDecrypt withKey:key andIV:iv];
}

- (NSData *)AES256EncryptWithKey:(NSString *)key {
  return [self cryptOperation:kCCEncrypt withKey:key andIV:nil];
}

- (NSData *)AES256DecryptWithKey:(NSString *)key {
  return [self cryptOperation:kCCDecrypt withKey:key andIV:nil];
}


@end