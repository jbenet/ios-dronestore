//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@interface DSCrypt : NSObject {

  BOOL encode;
  BOOL base64;
  BOOL aes256;

  NSString *AESKey; // Should be ~32 bytes.

}
@property (nonatomic, assign) BOOL encode;
@property (nonatomic, assign) BOOL base64;
@property (nonatomic, assign) BOOL aes256;
@property (nonatomic, retain) NSString *AESKey;

- (NSData *) encodeData:  (NSData *)message;
- (NSData *) decodeData:  (NSData *)data;

- (NSData *)   encodedDataFromString:(NSString *)message;
- (NSString *) encodedStringFromString:(NSString *)message;
- (NSString *) decodedStringFromData:(NSData *) secret;
- (NSString *) decodedStringFromData:(NSData *) secret
                            encoding:(NSStringEncoding) encoding;

- (NSData *) base64EncodeData:(NSData *)data;
- (NSData *) base64DecodeData:(NSData *)data;

- (NSData *) AES256EncryptData: (NSData *)message;
- (NSData *) AES256DecryptData: (NSData *)message;

+ (NSString *) md5hash:(NSString *)string;

@end


