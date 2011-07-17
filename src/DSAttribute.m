
#import <Foundation/Foundation.h>
#import "DSAttribute.h"
#import "DSMerge.h"
#import "DSModel.h"
#import "DSComparable.h"
#import "NSValue+ObjCTypeSize.h"

@implementation DSAttribute

@synthesize name, type, strategy, defaultValue, property;

- (id) init {
  [NSException raise:@"DSAttributeInit" format:@"%@ must be inited with "
    "name, type, defaultValue, and strategy", [self class]];
  return self;
}

- (id) initWithName:(NSString *)_name type:(Class)_type {
  if ((self = [super init])) {

    name = [_name copy];
    type = _type;
    self.property = name;
  }
  return self;
}

- (void) dealloc {
  [name release];
  [property release];
  [strategy release];
  [defaultValue release];
  [super dealloc];
}



+ (id) attributeWithName:(NSString *)name type:(Class)type {
  return [[[[self class] alloc] initWithName:name type:type] autorelease];
}


//------------------------------------------------------------------------------

- (void) setProperty:(NSString *)prop {
  NSString *temp = [prop copy];
  [property release];
  property = temp;

  temp = [NSString stringWithFormat:@"set%@:", [prop capitalizedString]];
  setter = NSSelectorFromString(temp); // - (void) setName:(type);
  getter = NSSelectorFromString(prop); // - (type) name;
}

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


- (void) updateValueForInstance:(DSModel *)instance {
  // make sure we (and merge strategies) have the latest value.
  // grr need decorators...

  NSDictionary *data = [instance dataForAttribute:name];
  id<DSComparable> prop_val = [self valueForInstance:instance];
  id<DSComparable> data_val = [data valueForKey:@"value"];
  if (!prop_val || !data_val || [prop_val compare:data_val] != NSOrderedSame)
    [self setValue:prop_val forInstance:instance];
}

//------------------------------------------------------------------------------

- (void) setData:(NSDictionary *)data forInstance:(DSModel *)instance {
  [instance setData:data forAttribute:name];
  [self __invokeSetValue:[data valueForKey:@"value"] forInstance:instance];
}

- (NSDictionary *) dataForInstance:(DSModel *)instance {
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

    // attempt to convert.
    if ([value isKindOfClass:[NSNumber class]])
      value = [(NSNumber *)value convertedNumberForObjCType:objCType];

    if (value == nil) {
      [NSException raise:@"DSInvalidType" format:@"%@ is of objCType %s not %s "
        "and cannot be set on %@.%@", value, [value objCType], objCType,
        [instance class], name];
    }
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
    case __primitive_c_float     :
    case __primitive_c_double    :
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
    case __primitive_c_float:
      return [NSNumber numberWithFloat:*(float *)buf];
    case __primitive_c_double:
      return [NSNumber numberWithDouble:*(double *)buf];
    case __primitive_c_bool:
      return [NSNumber numberWithBool:*(bool *)buf];
    default:
      return [NSValue value:buf withObjCType:type];
  }
}


#define NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, ret) {                  \
  switch (*objCType) {                                                        \
    case __primitive_c_char:                                                  \
      ret = [NSNumber numberWithChar:(char)var]; break;                       \
    case __primitive_c_int:                                                   \
      ret = [NSNumber numberWithInt:(int)var]; break;                         \
    case __primitive_c_short:                                                 \
      ret = [NSNumber numberWithShort:(short)var]; break;                     \
    case __primitive_c_long:                                                  \
      ret = [NSNumber numberWithLong:(long)var]; break;                       \
    case __primitive_c_longlong:                                              \
      ret = [NSNumber numberWithLongLong:(long long)var]; break;              \
    case __primitive_c_uchar:                                                 \
      ret = [NSNumber numberWithUnsignedChar:(unsigned char)var]; break;      \
    case __primitive_c_uint:                                                  \
      ret = [NSNumber numberWithUnsignedInt:(unsigned int)var]; break;        \
    case __primitive_c_ushort:                                                \
      ret = [NSNumber numberWithUnsignedShort:(unsigned short)var]; break;    \
    case __primitive_c_ulong:                                                 \
      ret = [NSNumber numberWithUnsignedLong:(unsigned long)var]; break;      \
    case __primitive_c_ulonglong:                                             \
      ret = [NSNumber numberWithUnsignedLongLong:(unsigned long long)var];    \
      break;                                                                  \
    case __primitive_c_float:                                                 \
      ret = [NSNumber numberWithFloat:(float)var]; break;                     \
    case __primitive_c_double:                                                \
      ret = [NSNumber numberWithDouble:(double)var]; break;                   \
    case __primitive_c_bool:                                                  \
      ret = [NSNumber numberWithBool:(bool)var]; break;                       \
    default:                                                                  \
      ret = nil; break;                                                       \
  }                                                                           \
}

- (NSNumber *) convertedNumberForObjCType:(const char *)objCType {
  NSNumber *altValue = nil;
  switch (*[self objCType])
  {
    case __primitive_c_char: {
      char var = [self charValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_int: {
      int var = [self intValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_short: {
      short var = [self shortValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_long: {
      long var = [self longValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_longlong: {
      long long var = [self longLongValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_uchar: {
      unsigned char var = [self unsignedCharValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_uint: {
      unsigned int var = [self unsignedIntValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_ushort: {
      unsigned short var = [self shortValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_ulong: {
      unsigned long var = [self unsignedLongValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_ulonglong: {
      unsigned long long var = [self unsignedLongLongValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_float: {
      float var = [self floatValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_double: {
      double var = [self doubleValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
    case __primitive_c_bool: {
      bool var = [self boolValue];
      NSNUMBER_WITH_VAR_AND_OBJCTYPE(var, objCType, altValue);
      break;
    }
  }
  return altValue;
}
#undef NSNUMBER_WITH_VAR_AND_OBJCTYPE

@end


