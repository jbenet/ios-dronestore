
#import "DSModel.h"
#import "iDrone.h"

#import "NSString+SHA.h"

static NSMutableDictionary *dsModelRegistry = nil;
static NSMutableDictionary *dsAttributeRegistry = nil;


//------------------------------------------------------------------------------
@implementation DSModel

@synthesize key, version, created;

- (id) init {
  [NSException raise:@"DSInvalidModelConstruction" format:@"DSModel requires"
    "a Key or a Version to initialize."];
  return nil;
}

- (id) initWithKey:(DSKey *)_key {
  if ((self = [super init])) {
    key = [_key retain];
    version = [[DSVersion blankVersionWithKey:key] retain];
    created = [[NSDate date] retain]; //TODO(jbenet) make this sysTime

    attributeData = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (id) initWithVersion:(DSVersion *)_version {
  if ((self = [super init])) {
    version = [_version retain];
    created = [[version createdDate] retain];
    key = [[version key] retain];

    attributeData = [[NSMutableDictionary alloc] init];
  }
  return self;
}

+ (DSModel *) modelWithVersion:(DSVersion *)version {
  return [[[DSModel alloc] initWithVersion:version] autorelease];
}

- (void) dealloc {
  [version release];
  [created release];
  [key release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (NSString *) description {
  return [NSString stringWithFormat:@"<%@ %@>", [[self class] dstype], key];
}

// Unfortunately, we don't have a decorator so we cant keep tabs on this.
// decorators would be too confusing for users...
// - (BOOL) isDirty {
//   NSMutableDictionary *attrs = [self attributeData];
// }

- (BOOL) isCommitted {
  return !version.isBlank;
}


//------------------------------------------------------------------------------

- (void) commit {
  NSMutableString *hash = [[NSMutableString alloc] init];
  [hash appendFormat:@"%@,%@,", self.key, [[self class] dstype]];

  NSMutableDictionary *attrData = [[NSMutableDictionary alloc] init];
  NSDictionary *attrs = [self attributes];
  for (DSAttribute *attr in [attrs allValues]) {
    [attrData setValue:[attr dataForInstance:self] forKey:attr.name];
    [hash appendFormat:@"%@=%@,", attr.name, [attrData valueForKey:attr.name]];
  }

  hash = [self sha1HexDigest];

  if ([hash isEqualToString:version.hashstr]) {
    DSLog(@"[%@] committing unmodified version.", self.key);
    return;
  }

  NSNumber *nt_committed = [NSNumber numberWithLongLong:nanotime_now().ns];
  NSNumber *nt_created = [NSNumber numberWithLongLong:version.created.ns];

  DSMutableSerialRep *serialRep = [[DSMutableSerialRep alloc] init];
  [serialRep setValue:hash forKey:@"hash"];
  [serialRep setValue:[key string] forKey:@"key"];
  [serialRep setValue:[self dstype] forKey:@"type"];
  [serialRep setValue:version.hashstr forKey:@"parent"];
  [serialRep setValue:nt_committed forKey:@"committed"];
  [serialRep setValue:nt_created forKey:@"created"];
  [serialRep setValue:attrs forKey:@"attributes"];

  NSLog(@"%@", serialRep.contents);
  [version release];
  version = [[DSVersion alloc] initWithSerialRep:serialRep];
}

- (void) merge:(DSVersion *)version {
  [NSException raise:@"DSNotImplemented" format:@"Not Implemented Yet"];
}

//------------------------------------------------------------------------------


- (void) setData:(NSDictionary *)dict forAttribute:(NSString *)attrName {
  NSMutableDictionary *data = [attributeData valueForKey:attrName];
  [data removeAllObjects];
  [data addEntriesFromDictionary:dict];
}


- (NSDictionary *) dataForAttribute:(NSString *)attrName {
  // NSMutableDictionary *data = [NSMutableDictionary dictionary];
  // if ([attributeData valueForKey:attr.name])
  //   [data addEntriesFromDictionary:[attributeData valueForKey:attr.name]];
  // [data setValue:[attr valueForInstance:self] forKey:@"value"];
  return [attributeData valueForKey:attrName];
}


+ (NSDictionary *) attributes {
  return [dsAttributeRegistry valueForKey:[self dstype]];
}

//------------------------------------------------------------------------------


+ (void) registerAttribute:(DSAttribute *)attr {
  NSMutableDictionary *attrs = [dsAttributeRegistry valueForKey:[self dstype]];
  assert(attrs);
  [attrs setValue:attr forKey:attr.name];
  [attributeData setValue:[NSMutableDictionary dictionary] forKey:attr.name];
}

+ (void) registerAttributes {
  // default is blank.
}


+ (void) initialize {

  if (dsModelRegistry == nil)
    dsModelRegistry = [[NSMutableDictionary alloc] init];
  if (dsAttributeRegistry == nil)
    dsAttributeRegistry = [[NSMutableDictionary alloc] init];

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dsAttributeRegistry setValue:dict forKey:[self dstype]];
  [dsModelRegistry setValue:[self class] forKey:[self dstype]];

  [self registerAttributes];
}
//------------------------------------------------------------------------------

// override this to name model something different than its Class name.
- (NSString *) dstype {
  return [[self class] dstype];
}

+ (NSString *) dstype {
  return NSStringFromClass([self class]);
}

+ (Class) modelWithDSType:(NSString *)type {
  //TODO(jbenet): synch here? shouldnt need to... its basically immutable now.
  return [dsModelRegistry valueForKey:type];
}

@end



