
#import <Foundation/Foundation.h>
#import "DSVersion.h"
#import "iDrone.h"

const const NSString *DSVersionBlankHash =
  @"0000000000000000000000000000000000000000";

//------------------------------------------------------------------------------
@implementation DSVersion

@synthesize serialRep;

- (id) init {
  [NSException raise:@"DSVersionConstructionException" format:@"Versions must "
    "be constructed with either a Key or a SerialRep."];
  return nil;
}


- (id) initWithSerialRep:(DSSerialRep *)_serialRep {
  if ((self = [super init])) {
    if (![_serialRep isValidVersionRepresentation]) {
      [NSException raise:@"DSVersionInvalidRepException" format:@"SerialRep "
        "is not a valid SerialRep."];
    }

    serialRep = [[DSMutableSerialRep alloc] initWithSerialRep:_serialRep];
  }
  return self;
}


- (void) dealloc {
  [serialRep release];
  [super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark properties

- (DSKey *) key {
  return [DSKey keyWithString:[serialRep valueForKey:@"key"]];
}

- (NSString *) hashstr {
  return [serialRep valueForKey:@"hash"];
}

- (NSString *) parent {
  return [serialRep valueForKey:@"parent"];
}

- (NSString *) type {
  return [serialRep valueForKey:@"type"];
}

// - (Class) typeClass {
//   return
// }

- (nanotime) committed {
  nanotime nt;
  nt.ns = [[serialRep valueForKey:@"committed"] longLongValue];
  return nt;
}

- (NSDate *) committedDate {
  return [NSDate dateWithNanotimeSince1970:[self committed]];
}

- (nanotime) created {
  nanotime nt;
  nt.ns = [[serialRep valueForKey:@"created"] longLongValue];
  return nt;
}

- (NSDate *) createdDate {
  return [NSDate dateWithNanotimeSince1970:[self created]];
}

- (BOOL) isBlank {
  return [DSVersionBlankHash isEqualToString:self.hashstr];
}

//------------------------------------------------------------------------------

- (Class) typeClass {
  return [[DSModel class] modelWithDSType:self.type];
}

- (id) valueForAttribute:(NSString *)attrName {
  return [self metaData:@"value" forAttribute:attrName];
}


- (NSDictionary *) dataForAttribute:(NSString *)attrName {
  return [[serialRep valueForKey:@"attributes"] valueForKey:attrName];
}

- (id) metaData:(NSString *)key forAttribute:(NSString *)attrName {
  NSObject *obj = [self dataForAttribute:attrName];

  // object MUST be a dict or nil. otherwise it is malformed data...
  if ([obj isKindOfClass:[NSDictionary class]])
    return [(NSDictionary *)obj valueForKey:key];

  else if (obj)
    DSLog(@"[%@] malformed data for attribute %@", self.key, attrName);

  return nil;
}

//------------------------------------------------------------------------------

- (NSObject *) valueForKey:(NSString *)key {
  if ([key isEqualToString:@"committed"])
    return [NSNumber numberWithLongLong:self.committed.ns];
  if ([key isEqualToString:@"created"])
    return [NSNumber numberWithLongLong:self.created.ns];

  if ([self respondsToSelector:NSSelectorFromString(key)])
    return [(id)self performSelector:NSSelectorFromString(key)];

  NSObject *obj = [self valueForAttribute:key];
  return (obj ? obj : [super valueForKey:key]);
}

//------------------------------------------------------------------------------

- (BOOL) isEqualToVersion:(DSVersion *)version {
  return [self.hashstr isEqualToString:version.hashstr];
}

//------------------------------------------------------------------------------

+ (DSVersion *) versionWithSerialRep:(DSSerialRep *)serialRep {
  return [[[DSVersion alloc] initWithSerialRep:serialRep] autorelease];
}

+ (DSVersion *) blankVersionWithKey:(DSKey *)key {
  DSMutableSerialRep *serialRep = [[DSMutableSerialRep alloc] init];

  // Blank Version. fill it with defaults:
  [serialRep setValue:[key string] forKey:@"key"];
  [serialRep setValue:DSVersionBlankHash forKey:@"hash"];
  [serialRep setValue:DSVersionBlankHash forKey:@"parent"];
  [serialRep setValue:[NSNumber numberWithLongLong:0] forKey:@"committed"];
  [serialRep setValue:[NSNumber numberWithLongLong:0] forKey:@"created"];
  [serialRep setValue:[NSMutableDictionary dictionary] forKey:@"attributes"];
  [serialRep setValue:@"" forKey:@"type"];

  DSVersion *version = [self versionWithSerialRep:serialRep];
  [serialRep release];

  return version;
}

@end



//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


@implementation DSSerialRep (Version)

- (BOOL) isValidVersionRepresentation {
  NSObject *value;

  value = [self valueForKey:@"key"];
  if (value == nil || ![value isKindOfClass:[NSString class]])
    return NO;

  value = [self valueForKey:@"hash"];
  if (value == nil || ![value isKindOfClass:[NSString class]])
    return NO;

  value = [self valueForKey:@"parent"];
  if (value == nil || ![value isKindOfClass:[NSString class]])
    return NO;

  value = [self valueForKey:@"committed"];
  if (value == nil || ![value isKindOfClass:[NSNumber class]])
    return NO;

  value = [self valueForKey:@"created"];
  if (value == nil || ![value isKindOfClass:[NSNumber class]])
    return NO;

  value = [self valueForKey:@"attributes"];
  if (value == nil || ![value isKindOfClass:[NSDictionary class]])
    return NO;

  value = [self valueForKey:@"type"];
  if (value == nil || ![value isKindOfClass:[NSString class]])
    return NO;

  return YES;
}

@end


