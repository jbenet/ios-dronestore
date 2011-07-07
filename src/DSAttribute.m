
#import <Foundation/Foundation.h>
#import "DSAttribute.h"
#import "DSMerge.h"
#import "DSModel.h"
#import "NSValue+ObjCTypeSize.h"

@implementation DSAttribute

@synthesize name, type, strategy, defaultValue;

- (id) init {
  [NSException raise:@"DSAttributeInit" format:@"%@ must be inited with "
    "name, type, defaultValue, and strategy", [self class]];
  return self;
}

- (id) initWithName:(NSString *)_name type:(Class)_type {
  if ((self = [super init])) {

    name = [_name copy];
    type = _type;

    _name = [NSString stringWithFormat:@"set%@:", [name capitalizedString]];
    setter = NSSelectorFromString(_name); // - (void) setName:(type);
    getter = NSSelectorFromString(name); // - (type) name;
  }
  return self;
}

- (void) dealloc {
  [name release];
  [strategy release];
  [defaultValue release];
  [super dealloc];
}



+ (id) attributeWithName:(NSString *)name type:(Class)type {
  return [[[[self class] alloc] initWithName:name type:type] autorelease];
}


//------------------------------------------------------------------------------

- (void) setStrategy:(DSMergeStrategy *)_strategy {
  [_strategy retain];
  [strategy release];
  strategy = _strategy;

  strategy.attribute = self;
}

//------------------------------------------------------------------------------

- (NSString *) description {
  return [NSString stringWithFormat:@"<attribute %@ of type %@ with strategy "
    "%@>", name, [type class], [strategy class]];
}

//------------------------------------------------------------------------------


- (void) __invokeSetValue:(NSValue *)value forInstance:(DSModel *)instance {

  if (![value isKindOfClass:type]) {
    [NSException raise:@"DSInvalidType" format:@"%@ is not an instance of %@ "
      "and cannot be set on %@.%@", value, type, [instance class], name];
  }

  [instance performSelector:setter withObject:value];

}

- (void) setValue:(id)value forInstance:(DSModel *)instance {

  [self __invokeSetValue:value forInstance:instance];

  // THINME(jbenet)
  // redundant storage... consider using a decorator instead.
  NSMutableDictionary *data = [instance mutableDataForAttribute:name];
  [data setValue:value forKey:@"value"];
  [strategy setValue:value forInstance:instance];
}

- (void) setDefaultValue:(id)value forInstance:(DSModel *)instance {

  [self __invokeSetValue:value forInstance:instance];

  // THINME(jbenet)
  // redundant storage... consider using a decorator instead.
  NSMutableDictionary *data = [instance mutableDataForAttribute:name];
  [data setValue:value forKey:@"value"];
  [strategy setDefaultValue:value forInstance:instance];
}

- (id) valueForInstance:(DSModel *)instance {
  return [instance performSelector:getter];
}

//------------------------------------------------------------------------------


- (void) setData:(NSDictionary *)data forInstance:(DSModel *)instance {
  [instance setData:data forAttribute:name];
  [self setValue:[data valueForKey:@"value"] forInstance:instance];
}

- (NSDictionary *) dataForInstance:(DSModel *)instance {

  // make sure we (and merge strategies) have the latest value.
  // grr need decorators...

  NSObject *curr_val = [self valueForInstance:instance];
  NSObject *prev_val = [instance.version valueForAttribute:name];
  if (![curr_val isEqual:prev_val])
    [self setValue:curr_val forInstance:instance];

  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  [dict addEntriesFromDictionary:[instance dataForAttribute:name]];
  return [dict autorelease];
}

@end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


@implementation DSPrimitiveAttribute
// Thanks to invocation magic!

- (id) initWithName:(NSString *)_name type:(Class)_type {
  [NSException raise:@"DSPrimitiveAttributeInit" format:@"%@ must be inited "
    "with name and objCType", [self class]];
  return self;
}

- (id) initWithName:(NSString *)_name objCType:(const char *)_objCType {
  Class valueClass = [NSValue classForObjCType:_objCType];
  if ((self = [super initWithName:_name type:valueClass])) {
    objCType = _objCType;
  }
  return self;
}

+ (id) attributeWithName:(NSString *)name
  objCType:(const char *)type  {
  return [[[[self class] alloc] initWithName:name objCType:type] autorelease];
}

- (void) dealloc {
  [super dealloc];
}

//------------------------------------------------------------------------------

- (NSString *) description {
  return [NSString stringWithFormat:@"<attribute %@ of primitive type %s with "
    "strategy %@>", name, objCType, [strategy class]];
}


//------------------------------------------------------------------------------

- (void) __invokeSetValue:(NSValue *)value forInstance:(DSModel *)instance {

  if (strcmp([value objCType], objCType) != 0) {
    [NSException raise:@"DSInvalidType" format:@"%@ is of objCType %s not %s "
      "and cannot be set on %@.%@", value, [value objCType], objCType,
      [instance class], name];
  }

  char argumentBuffer[objc_primitive_size(objCType)];
  [value getValue:&argumentBuffer];

  NSMethodSignature *sig = [instance methodSignatureForSelector:setter];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
  [inv setSelector:setter];
  [inv setTarget:instance];
  [inv setArgument:&argumentBuffer atIndex:2];
  //args 0 and 1 are self and _cmd set by NSInvocation
  [inv invoke];

}


- (NSValue *) valueForInstance:(DSModel *)instance {
  char retBuf[objc_primitive_size(objCType)];

  NSMethodSignature *sig = [instance methodSignatureForSelector:getter];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
  [inv setSelector:getter];
  [inv setTarget:instance];
  [inv invoke];

  [inv getReturnValue:&retBuf];
  return [type value:&retBuf withObjCType:objCType];
}

@end


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

@implementation NSValue (DSAttribute)

+ (Class) classForObjCType:(const char *)objCType {
  switch (*objCType)
  {
    case __primitive_c_char      :
    case __primitive_c_int       :
    case __primitive_c_short     :
    case __primitive_c_long      :
    case __primitive_c_longlong  :
    case __primitive_c_uchar     :
    case __primitive_c_uint      :
    case __primitive_c_ushort    :
    case __primitive_c_ulong     :
    case __primitive_c_ulonglong :
    case __primitive_c_ufloat    :
    case __primitive_c_udouble   :
    case __primitive_c_bool      : return [NSNumber class];
    default: return [NSValue class];
  }
}

@end

//------------------------------------------------------------------------------

@implementation NSNumber (DSAttribute)
+ (id) value:(const void *)buf withObjCType:(const char *)type {
  switch (*type)
  {
    case __primitive_c_char:
      return [NSNumber numberWithChar:*(char *)buf];
    case __primitive_c_int:
      return [NSNumber numberWithInt:*(int*)buf];
    case __primitive_c_short:
      return [NSNumber numberWithShort:*(short*)buf];
    case __primitive_c_long:
      return [NSNumber numberWithLong:*(long*)buf];
    case __primitive_c_longlong:
      return [NSNumber numberWithLongLong:*(long long*)buf];
    case __primitive_c_uchar:
      return [NSNumber numberWithUnsignedChar:*(unsigned char*)buf];
    case __primitive_c_uint:
      return [NSNumber numberWithUnsignedInt:*(unsigned int*)buf];
    case __primitive_c_ushort:
      return [NSNumber numberWithUnsignedShort:*(unsigned short*)buf];
    case __primitive_c_ulong:
      return [NSNumber numberWithUnsignedLong:*(unsigned long*)buf];
    case __primitive_c_ulonglong:
      return [NSNumber numberWithUnsignedLongLong:*(unsigned long long*)buf];
    case __primitive_c_ufloat:
      return [NSNumber numberWithFloat:*(float *)buf];
    case __primitive_c_udouble:
      return [NSNumber numberWithDouble:*(double *)buf];
    case __primitive_c_bool:
      return [NSNumber numberWithBool:*(bool *)buf];
    default:
      return [NSValue value:buf withObjCType:type];
  }
}
@end


