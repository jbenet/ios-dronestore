
#import "DSKey.h"

@implementation DSKey

@synthesize string;

- (id) init {
  return [self initWithString:@"/"];
}

- (id) initWithString:(NSString *)_string {
  if ((self = [super init])) {
    string = [[_string absolutePathString] retain];
  }
  return self;
}

- (void) dealloc {
  [string release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (NSString *) description {
  return string;
}

- (NSString *) name {
  return [[self components] lastObject];
}

- (NSString *) type {
  NSArray *cmp = [self components];
  if ([cmp count] >= 2)
    return [cmp objectAtIndex:[cmp count] - 2];
  return @"";
}

//------------------------------------------------------------------------------

- (DSKey *) parent {
  NSMutableArray *cmp = [NSMutableArray arrayWithArray:[self components]];
  [cmp removeLastObject];
  return [[self class] keyWithString:[cmp componentsJoinedByString:@"/"]];
}

- (DSKey *) childWithString:(NSString *)child {
  NSString *key = [NSString stringWithFormat:@"%@/%@", string, child];
  return [DSKey keyWithString:key];
}

- (DSKey *) childWithKey:(DSKey *)key {
  return [self childWithString:key.string];
}

- (BOOL) isAncestorOfKey:(DSKey *)key {
  return [key.string hasPrefix:string];
}

- (BOOL) isTopLevelKey {
  return [[self components] count] <= 2;
}

//------------------------------------------------------------------------------

- (NSString *) hashString {
  return string; //Todo(jbenet)
}

- (NSArray *) components {
  return [string componentsSeparatedByString:@"/"];
}

- (BOOL) isEqualToKey:(DSKey *)key {
  return [self compare:key] == NSOrderedSame;
}

- (NSComparisonResult) compare:(DSKey *)key {
  return [string compare:key.string];
}

//------------------------------------------------------------------------------

+ (DSKey *) keyWithString:(NSString *)string {
  return [[[DSKey alloc] initWithString:string] autorelease];
}

//------------------------------------------------------------------------------

@end


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

@implementation NSString (Slashes)

- (NSString *) stringByRemovingDuplicateSlashes {
  NSArray *components = [self componentsSeparatedByString:@"/"];
  NSMutableArray *keep = [NSMutableArray array];
  for (NSString *component in components) {
    if ([component length] > 0)
      [keep addObject:component];
  }
  return [keep componentsJoinedByString:@"/"];
}

- (NSString *) absolutePathString {
  NSString *str = [self stringByRemovingDuplicateSlashes];
  return [NSString stringWithFormat:@"/%@", str];
}

@end
