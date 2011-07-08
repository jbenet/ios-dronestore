
#import <bson-objc/BSONCodec.h>
#import "DSSerialRep.h"

@implementation DSSerialRep

@synthesize contents;

- (id) init {
  if ((self = [super init])) {
    contents = [[NSMutableDictionary alloc] initWithCapacity:10];
  }
  return self;
}

- (id) initWithData:(NSData *)data {
  return [self initWithDictionary:[data BSONValue]];
}

- (id) initWithDictionary:(NSDictionary *)dict {
  if ((self = [self init])) {
    [contents addEntriesFromDictionary:dict];
  }
  return self;
}

- (id) initWithSerialRep:(DSSerialRep *)serialRep {
  return [self initWithDictionary:serialRep.contents];
}

- (void) dealloc {
  [contents release];
  [super dealloc];
}

+ (DSSerialRep *) serialRepWithData:(NSData *)data {
  return [self representationWithBSON:data];
}

//------------------------------------------------------------------------------

- (id) valueForKey:(NSString *)key {
  return [contents valueForKey:key];
}

- (NSData *) data {
  return [self BSON];
}

@end


@implementation DSMutableSerialRep

- (void) setValue:(id)value forKey:(NSString *)key {
  [contents setValue:value forKey:key];
}

@end



@implementation DSSerialRep (BSON)
- (NSData *) BSON {
  return [contents BSONRepresentation];
}

+ (id) representationWithBSON:(NSData *)bson {
  DSSerialRep *sr;
  sr = [[self alloc] initWithDictionary:[bson BSONValue]];
  return [sr autorelease];
}
@end


//TODO(jbenet)
@implementation DSSerialRep (JSON)
- (NSData *) JSON {
  return nil;
}
+ (DSSerialRep *) representationWithJSON:(NSData *)json {
  return nil;
}
@end

