//
//  NSData+AES.h
//

@interface NSData (AES256)


- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;
- (NSData *)AES256EncryptWithKey:(NSString *)key andIV:(NSString *)iv;
- (NSData *)AES256DecryptWithKey:(NSString *)key andIV:(NSString *)iv;


@end
