
#import <Foundation/Foundation.h>

// A Serial representation.
// This is used to house versions for easy transfer via network or storage.

@interface DSSerialRep : NSObject {
  NSMutableDictionary *contents;
}

@property (nonatomic, readonly, copy) NSDictionary *contents;

- (id) init;
- (id) initWithDictionary:(NSDictionary *)dict;
- (id) initWithSerialRep:(DSSerialRep *)serialRep;

- (id) valueForKey:(NSString *)key;

- (NSData *) data;

@end


@interface DSMutableSerialRep : DSSerialRep {}

- (void) setValue:(id)value forKey:(NSString *)key;
@end


@interface DSSerialRep (BSON)
- (NSData *) BSON;
+ (DSSerialRep *) representationWithBSON:(NSData *)bson;
@end

//
// @interface DSSerialRep (JSON)
// - (NSData *) JSON;
// + (DSSerialRep *) representationWithJSON:(NSData *)json;
// @end
//
