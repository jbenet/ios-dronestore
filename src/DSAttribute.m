
#import <Foundation/Foundation.h>
#import "DSAttribute.h"
#import "DSMerge.h"

@implementation DSAttribute

@synthesize name, type, strategy;

- (id) initWithName:(NSString *)_name type:(Class)_type
  andStrategy:(Class)_strategy {
  if ((self = [super init])) {

    if (![_strategy isSubclassOfClass:[DSMergeStrategy class]])
      [NSException raise:@"DSInvalidStrategy" format:@"The class %@ is not"
        "derived from %@", _strategy, [DSMergeStrategy class]];

    data = [[NSMutableDictionary alloc] init];

    name = [_name copy];
    type = _type;
    strategy = _strategy;

    _name = [NSString stringWithFormat:@"set%@:", [name capitalizedString]];
    setter = NSSelectorFromString(_name); // - (void) setName:(type);
    getter = NSSelectorFromString(name); // - (type) name;
  }
  return self;
}

- (void) dealloc {
  [data release];
  [name release];
  [super dealloc];
}

+ (DSAttribute *) attributeWithName:(NSString *)name type:(Class)type
  andStrategy:(Class)strategy {
  return [[[DSAttribute alloc] initWithName:name type:type andStrategy:strategy]
    autorelease];
}


//------------------------------------------------------------------------------

- (void) setValue:(id)value forInstance:(DSModel *)instance {
  if (![value isKindOfClass:type]) {
    [NSException raise:@"DSInvalidType" format:@"%@ is not an instance of %@ "
      "and cannot be set on %@.%@", value, type, instance, name];
  }

  [instance performSelector:setter withObject:value];
}

- (id) valueForInstance:(DSModel *)instance {
  return [instance performSelector:getter];
}


- (NSDictionary) dataForInstance:(DSModel *)instance {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  [dict addEntriesFromDictionary:[instance dataForAttribute:name]];
  [dict setValue:[self valueForInstance:instance] forKey:@"value"];
  return [dict autorelease];
}

@end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

//
// @implementation DSPrimitiveAttribute
// // Thanks to invocation magic!
//
// - (id) initWithName:(NSString *)name objCType:(const char *)type
//   andStrategy:(DSMergeStrategy *)str {
//   if ((self = [super initWithName:name type:[NSValue class] andStrategy:str])) {
//
//   }
//   return self;
// }
//
// + (DSAttribute *) attributeWithName:(NSString *)name objCType:(const char *)type
//   andStrategy:(DSMergeStrategy *)strategy {
//   return [[[DSAttribute alloc] initWithName:name objCType:type
//     andStrategy:strategy] autorelease];
// }
//
// - (void) dealloc {
//   [type release];
//   [super dealloc];
// }
//
//
// //------------------------------------------------------------------------------
//
// - (void) setValue:(NSValue *)value forInstance:(DSModel *)instance {
//   type argumentValue;
//   [value getValue:&argumentValue];
//
//   NSMethodSignature *sig = [instance methodSignatureForSelector:setter];
//   NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
//   [inv setSelector:setter];
//   [inv setTarget:instance];
//   [inv setArgument:&argumentValue atIndex:2];
//   //args 0 and 1 are self and _cmd set by NSInvocation
//   [inv invoke];
// }
//
// - (NSValue *) valueForInstance:(DSModel *)instance {
//   type returnValue;
//
//   NSMethodSignature *sig = [instance methodSignatureForSelector:getter];
//   NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
//   [inv setSelector:getter];
//   [inv setTarget:instance];
//   [inv invoke];
//
//   [inv getReturnValue:&returnValue];
//   return [NSValue valueWithBytes:&returnValue objCType:@encode(type)];
// }
//
// @end

