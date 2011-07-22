

@interface NSString (DS_SHA)

- (NSString *) sha1HexDigest;
+ (NSString *) sha1HexDigestFrom:(NSString *) input;

- (NSString *) sha256HexDigest;
+ (NSString *) sha256HexDigestFrom:(NSString *) input;
@end
