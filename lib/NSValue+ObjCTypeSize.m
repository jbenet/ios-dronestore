
#import "NSValue+ObjCTypeSize.h"

// Author: jbenet


@implementation NSValue (ObjCTypeSize)
- (size_t) typeSize {
  return objc_primitive_size([self objCType]);
}
+ (size_t) sizeOfObjCType:(const char *)objCType {
  return objc_primitive_size(objCType);
}
@end


inline int objc_primitive_size(const char * type)
{
  switch (*type)
  {
    case __primitive_c_char      : return sizeof(char);
    case __primitive_c_int       : return sizeof(int);
    case __primitive_c_short     : return sizeof(short);
    case __primitive_c_long      : return sizeof(long);
    case __primitive_c_longlong  : return sizeof(long long);
    case __primitive_c_uchar     : return sizeof(unsigned char);
    case __primitive_c_uint      : return sizeof(unsigned int);
    case __primitive_c_ushort    : return sizeof(unsigned short);
    case __primitive_c_ulong     : return sizeof(unsigned long);
    case __primitive_c_ulonglong : return sizeof(unsigned long long);
    case __primitive_c_ufloat    : return sizeof(float);
    case __primitive_c_udouble   : return sizeof(double);
    case __primitive_c_bool      : return sizeof(bool);
    case __primitive_c_void      : return 0;
    case __primitive_c_charptr   : return sizeof(char*);
    case __primitive_c_id        : return sizeof(id);
    case __primitive_c_class     : return sizeof(Class);
    case __primitive_c_selector  : return sizeof(SEL);
    default: return -1; // unknown
  }
}

