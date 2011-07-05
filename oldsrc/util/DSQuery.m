//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <iDrone/DSQuery.h>
#import <iDrone/DSDrone.h>
#import <iDrone/DSLocalDrone.h>
#import <iDrone/DSCollection.h>
#import <iDrone/DSCallback.h>

static char kASCENDING = '+';
static char kDESCENDING = '-';

@interface DSQueryFilter : NSObject <DSArraySerializable> {

  NSString *field;
  NSObject *value;
}

@property (nonatomic, copy) NSString *field;
@property (nonatomic, copy) NSObject *value;

+ (DSQueryFilter *) filterFromArray:(NSArray *)array;
+ (DSQueryFilter *) filterWithField:(NSString *)field value:(NSObject *)value;

@end

@implementation DSQueryFilter

@synthesize field, value;

- (void) dealloc {
  self.field = nil;
  self.value = nil;
  [super dealloc];
}

- (void) loadArray:(NSArray *)array {
  self.field = [array objectAtIndex:0];
  self.value = [array objectAtIndex:1];
}

- (NSMutableArray *) toArray {
  return [NSMutableArray arrayWithObjects:field, value, nil];
}

- (id) JSON {
  return [self toArray];
}

+ (DSQueryFilter *) filterFromArray:(NSArray *)array {
  DSQueryFilter *filter = [[[DSQueryFilter alloc] init] autorelease];
  [filter loadArray:array];
  return filter;
}

+ (DSQueryFilter *) filterWithField:(NSString *)field value:(NSObject *)value {
  DSQueryFilter *filter = [[[DSQueryFilter alloc] init] autorelease];
  filter.field = field;
  filter.value = value;
  return filter;
}

@end

@implementation DSQuery

@synthesize keysOnly, droneid, callback, didRun, didSucceed;
@synthesize limit, offset, order, filters, ds_type_;

- (id) init {
  if (self = [super init]) {
    filters = [[NSMutableArray alloc] initWithCapacity:5];
    order = [[NSMutableArray alloc] initWithCapacity:2];

    ds_type_ = nil;
    limit = -1;
    offset = -1;
    keysOnly = NO;

    keys = nil;
    models = nil;

    count = 0;
    didRun = NO;
    didSucceed = NO;
  }
  return self;
}

- (void) dealloc {
  self.droneid = nil;
  self.callback = nil;
  self.ds_type_ = nil;

  [filters release];
  [order release];

  if (keys != nil)
    [keys release];
  if (models != nil)
    [models release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (NSMutableArray *) keys {
  if (keys == nil)
    keys = [[NSMutableArray alloc] initWithCapacity:10];
  return keys;
}

- (DSCollection *) models {
  if (models == nil)
    models = [[DSCollection alloc] initWithCapacity:10];
  return models;
}

//------------------------------------------------------------------------------

- (void) filterByField:(NSString *)field value:(NSObject *)value {
  [filters addObject:[DSQueryFilter filterWithField:field value:value]];
}

//------------------------------------------------------------------------------

- (void) orderByField:(NSString *)field ascending:(BOOL)ascending {
  char asc = ascending ? kASCENDING : kDESCENDING;
  [order addObject:[NSString stringWithFormat:@"%c%@", asc, field]];
}

- (void) ascendingOrderByField:(NSString *)field {
  [self orderByField:field ascending:YES];
}

- (void) descendingOrderByField:(NSString *)field {
  [self orderByField:field ascending:NO];
}

//------------------------------------------------------------------------------

- (int) count {
  if (models != nil)
    return [models count];

  if (keys != nil)
    return [keys count];

  return 0;
}

//------------------------------------------------------------------------------

- (NSString *) SQLWhereWithArguments:(NSMutableArray *)arguments {

  NSMutableString *where = [NSMutableString string];
  NSMutableString *end = [NSMutableString string];

  if (ds_type_ != nil) {
    [where appendString:@"ds_type_ = ?"];
    [arguments addObject:ds_type_];
  }

  for (DSQueryFilter *f in filters) {
    if ([where length] > 0)
      [where appendFormat:@" AND "];
    [where appendFormat:@"%@ ?", f.field];
    [arguments addObject:f.value];
  }

  if ([order count] > 0) {
    [end appendFormat:@" ORDER BY"];

    for (NSString *string in order) {
      NSString *direction = @"ASC";
      NSString *field = [string substringFromIndex:1];
      if ([string characterAtIndex:0] == kDESCENDING)
        direction = @"DESC";

      if ([end length] > 9)
        [end appendFormat:@", %@ %@", field, direction];
      else
        [end appendFormat:@" %@ %@", field, direction];
    }
  }

  if (limit >= 0)
    [end appendFormat:@" LIMIT %i", limit];

  if (offset >= 0)
    [end appendFormat:@" OFFSET %i", offset];

  [where appendString:end];
  return where;
}

//------------------------------------------------------------------------------
- (void) runWithLocalDrone:(DSLocalDrone *)local wait:(BOOL)wait {
  [local runQuery:self wait:wait];
}

- (void) queryRanWithCallback:(DSCallback *)cbk {
  didRun = YES;
  didSucceed = cbk.didSucceed;

  if ([cbk.object isKindOfClass:[DSCollection class]]) {
    [models release];
    models = [cbk.object retain];

  } else if ([cbk.object isKindOfClass:[NSArray class]]) {
    [keys release];
    keys = [cbk.object retain];
  }

  if (callback == nil)
    return;

  callback.object = keysOnly ? (id)keys : (id)models;
  [callback callSucceeded:didSucceed];
}

//------------------------------------------------------------------------------

- (id) JSON {
  return [self toDict];
}

- (void) loadDict:(NSDictionary *)dict {

  if ([dict valueForKey:@"ds_type_"] != nil)
    self.ds_type_ = [dict valueForKey:@"ds_type_"];

  if ([dict valueForKey:@"keysonly"] != nil)
    keysOnly = [[dict valueForKey:@"keysonly"] boolValue];

  if ([dict valueForKey:@"offset"] != nil)
    offset = [[dict valueForKey:@"offset"] intValue];

  if ([dict valueForKey:@"limit"] != nil)
    limit = [[dict valueForKey:@"limit"] intValue];

  if ([dict valueForKey:@"order"] != nil)
    [order addObjectsFromArray:[dict valueForKey:@"order"]];

  if ([dict valueForKey:@"filter"] != nil)
    for (NSArray *array in [dict valueForKey:@"filter"])
      [filters addObject:[DSQueryFilter filterFromArray:array]];
}

- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];

  [dict setValue:ds_type_ forKey:@"ds_type_"];
  [dict setValue:[NSNumber numberWithBool:keysOnly] forKey:@"keysonly"];

  if (limit > 0)
    [dict setValue:[NSNumber numberWithInt:limit] forKey:@"limit"];

  if (offset > 0)
    [dict setValue:[NSNumber numberWithInt:offset] forKey:@"offset"];

  if ([order count] > 0)
    [dict setValue:order forKey:@"order"];

  if ([filters count] > 0)
    [dict setValue:filters forKey:@"filter"];

  return dict;
}

//------------------------------------------------------------------------------

+ (DSQuery *) queryDroneID:(NSString *)droneid {
  DSQuery *query = [[[DSQuery alloc] init] autorelease];
  query.droneid = droneid;
  return query;
}
+ (DSQuery *) queryDroneID:(NSString *)droneid ForType:(NSString *)type {
  DSQuery *query = [[[DSQuery alloc] init] autorelease];
  query.droneid = droneid;
  query.ds_type_ = type;
  return query;
}



@end
