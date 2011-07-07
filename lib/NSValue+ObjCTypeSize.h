
// Author: jbenet
#import <Foundation/Foundation.h>

@interface NSValue (ObjCTypeSize)
- (size_t) typeSize;
+ (size_t) sizeOfObjCType:(const char *)objCType;
@end

typedef enum  {
  __primitive_c_char      = 'c',  // @encode(char);
  __primitive_c_int       = 'i',  // @encode(int);
  __primitive_c_short     = 's',  // @encode(short);
  __primitive_c_long      = 'l',  // @encode(long);
  __primitive_c_longlong  = 'q',  // @encode(long long);
  __primitive_c_uchar     = 'C',  // @encode(unsigned char);
  __primitive_c_uint      = 'I',  // @encode(unsigned int);
  __primitive_c_ushort    = 'S',  // @encode(unsigned short);
  __primitive_c_ulong     = 'L',  // @encode(unsigned long);
  __primitive_c_ulonglong = 'Q',  // @encode(unsigned long long);
  __primitive_c_ufloat    = 'f',  // @encode(float);
  __primitive_c_udouble   = 'd',  // @encode(double);
  __primitive_c_bool      = 'B',  // @encode(bool);
  __primitive_c_void      = 'v',  // @encode(void);
  __primitive_c_charptr   = '*',  // @encode(char*);
  __primitive_c_id        = '@',  // @encode(id);
  __primitive_c_class     = '#',  // @encode(Class);
  __primitive_c_selector  = ':'   // @encode(SEL);
} __primitive_c_identifier;

int objc_primitive_size(const char * type);
