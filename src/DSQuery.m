
#import "DSQuery.h"

#import "DSKey.h"
#import "DSModel.h"
#import "DSVersion.h"
#import "DSCollection.h"
#import "DSSerialRep.h"
#import "DSComparable.h"

//------------------------------------------------------------------------------

NSObject * __extractValueForField(NSObject *object, NSString *field) {
  NSObject *value = nil;
  if ([object respondsToSelector:@selector(valueForKey:)]
      && [object valueForKey:field] != nil) {
    value = [(id)object valueForKey:field];
  }
  else if ([object isKindOfClass:[NSDictionary class]]
      && [object valueForKey:@"attributes"] != nil) {
    value = [[object valueForKey:@"attributes"] valueForKey:field];
    value = [value valueForKey:@"value"];
  }
  else if ([object respondsToSelector:NSSelectorFromString(field)]) {
    value = [object performSelector:NSSelectorFromString(field)];
  }
  else if ([object isKindOfClass:[DSSerialRep class]]) {
    // regular attributes should've been caught already. must be attr.
    NSDictionary *dict = [(DSSerialRep *)object valueForKey:field];
    if (dict)
      value = [dict valueForKey:field];
  }
  else if ([object isKindOfClass:[DSVersion class]]) {
    // regular version attributes should've been caught already. must be attr.
    value = [(DSVersion *)object valueForAttribute:field];
  }

  // Return whatever we've got so far.
  return value;
}

//------------------------------------------------------------------------------

DSCompOp *DSCompOpGreaterThanOrEqual = @">=";
DSCompOp *DSCompOpGreaterThan = @">";
DSCompOp *DSCompOpLessThanOrEqual = @"<=";
DSCompOp *DSCompOpLessThan = @"<";
DSCompOp *DSCompOpEqual = @"=";
DSCompOp *DSCompOpNotEqual = @"!=";

@implementation DSFilter
@synthesize field, op, value;

- (void) dealloc {
  [field release];
  [op release];
  [value release];
  [super dealloc];
}

- (BOOL) objectPasses:(NSObject *)object {
  NSObject *val = __extractValueForField(object, self.field);
  if ([self.value isKindOfClass:[NSString class]])
    val = [val description];
  return [self valuePasses:(NSObject<DSComparable> *)val];
}

- (BOOL) valuePasses:(NSObject<DSComparable> *)val {
  if ([DSCompOpGreaterThanOrEqual isEqualToString:op])
    return [val compare:self.value] != NSOrderedAscending;
  if ([DSCompOpGreaterThan isEqualToString:op])
    return [val compare:self.value] == NSOrderedDescending;
  if ([DSCompOpLessThanOrEqual isEqualToString:op])
    return [val compare:self.value] != NSOrderedDescending;
  if ([DSCompOpLessThan isEqualToString:op])
    return [val compare:self.value] == NSOrderedAscending;
  if ([DSCompOpNotEqual isEqualToString:op])
    return [val compare:self.value] != NSOrderedSame;
  if ([DSCompOpEqual isEqualToString:op])
    return [val compare:self.value] == NSOrderedSame;

  [NSException raise:@"DSInvalidComparisonOperator" format:@"Operator %@ is "
    "not a valid %@ comparison operator.", self.op, [self class]];
  return NO;
}

- (NSString *) description {
  return [NSString stringWithFormat:@"DSFilter%@", [self array]];
}

+ (DSFilter *) filter:(NSString *)field op:(DSCompOp *)op
  value:(NSObject<DSComparable> *)value
{
  DSFilter *filter = [[DSFilter alloc] init];
  filter.field = field;
  filter.op = op;
  filter.value = value;
  return [filter autorelease];
}

- (NSArray *) filteredArray:(NSArray *)array {
  NSMutableArray *filteredArray = [NSMutableArray array];
  for (NSObject *object in array) {
    if ([self objectPasses:object])
      [filteredArray addObject:object];
  }
  return filteredArray;
}

+ (NSArray *) filteredArray:(NSArray *)array withFilters:(NSArray *)filters {
  for (DSFilter *filter in filters)
    array = [filter filteredArray:array];
  return array;
}

- (NSArray *) array {
  return [NSArray arrayWithObjects:self.field, self.op, self.value, nil];
}

+ (DSFilter *) filterWithArray:(NSArray *)array {
  DSFilter *filter = [[DSFilter alloc] init];
  filter.field = [array objectAtIndex:0];
  filter.op = [array objectAtIndex:1];
  filter.value = [array objectAtIndex:2];
  return [filter autorelease];
}

@end


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


DSOrderOp *DSOrderOpAscending = @"+";
DSOrderOp *DSOrderOpDescending = @"-";


@implementation DSOrder
@synthesize field, op;

- (id) init {
  [NSException raise:@"DSOrderInvalidConstrucion" format:@"%@ requires "
    "an order to be specified", [self class]];
  return nil;
}

- (id) initWithField:(NSString *)_field op:(DSOrderOp *)_op {
  BOOL ascending = [_op isEqualToString:DSOrderOpAscending];
  if ((self = [super initWithKey:_field ascending:ascending])) {
    field = [_field copy];
    op = [_op copy];
  }
  return self;
}

- (void) dealloc {
  [op release];
  [field release];
  [super dealloc];
}

- (BOOL) isAscending {
  return [op isEqualToString:DSOrderOpAscending];
}

- (NSArray *) sortedArray:(NSArray *)array {
  return [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:self]];
}

+ (DSOrder *) order:(NSString *)field op:(DSOrderOp *)op {
  return [[[DSOrder alloc] initWithField:field op:op] autorelease];
}

+ (NSArray *) sortedArray:(NSArray *)array withOrders:(NSArray *)orders {
  if (!orders || [orders count] == 0)
    return array;
  return [array sortedArrayUsingDescriptors:orders];
}

- (NSString *) description {
  return [self string];
}

- (NSString *) string {
  return [NSString stringWithFormat:@"%@%@", self.op, self.field];
}

+ (DSOrder *) orderWithString:(NSString *)order {
  NSString *op = [order substringToIndex:1];
  if ([op isEqualToString:DSOrderOpAscending]
    || [op isEqualToString:DSOrderOpDescending]) {
    order = [order substringFromIndex:1];
  } else {
    op = @"+";
  }

  return [[[DSOrder alloc] initWithField:order op:op] autorelease];
}
@end


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------



@implementation DSQuery

@synthesize type, filters, orders, limit, offset, keysonly;

- (id) initWithModel:(Class)model {
  return [self initWithType:[model dstype]];
}

- (id) initWithType:(NSString *)_type {
  if ((self = [super init])) {
    type = [_type copy];
    offset = 0;
    limit = 2000;
    keysonly = NO;
    orders = [[NSMutableArray alloc] init];
    filters = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) dealloc {
  [type release];
  [filters release];
  [orders release];
  [super dealloc];
}

//------------------------------------------------------------------------------

- (Class) typeClass {
  return [DSModel modelWithDSType:type];
}

- (NSArray *) operateOnArray:(NSArray *)array {
  array = [DSFilter filteredArray:array withFilters:self.filters];
  array = [DSOrder sortedArray:array withOrders:self.orders];
  int off = MIN(self.offset, [array count]);
  int lim = MIN(self.limit, [array count] - offset);
  return [array subarrayWithRange:NSMakeRange(off, lim)];
}

- (void) addOrder:(DSOrder *)order {
  [orders addObject:order];
}
- (void) addFilter:(DSFilter *)filter {
  [filters addObject: filter];
}

- (NSDictionary *) dictionary {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];

  [dict setValue:type forKey:@"type"];

  if (limit > 0 && limit != 2000)
    [dict setValue:[NSNumber numberWithInt:limit] forKey:@"limit"];
  if (offset > 0)
    [dict setValue:[NSNumber numberWithInt:offset] forKey:@"offset"];
  if (keysonly)
    [dict setValue:[NSNumber numberWithBool:keysonly] forKey:@"keysonly"];

  if ([filters count] > 0) {
    NSMutableArray *arr = [NSMutableArray array];
    for (DSFilter *filter in filters)
      [arr addObject:[filter array]];
    [dict setValue:arr forKey:@"filter"];
  }

  if ([orders count] > 0) {
    NSMutableArray *arr = [NSMutableArray array];
    for (DSOrder *order in orders)
      [arr addObject:[order string]];
    [dict setValue:arr forKey:@"order"];
  }

  return dict;
}

+ (DSQuery *) queryWithDictionary:(NSDictionary *)dict {

  DSQuery *query = [[DSQuery alloc] initWithType:[dict valueForKey:@"type"]];

  if ([dict valueForKey:@"limit"])
    query.limit = [[dict valueForKey:@"limit"] intValue];
  if ([dict valueForKey:@"offset"])
    query.offset = [[dict valueForKey:@"offset"] intValue];
  if ([dict valueForKey:@"keysonly"])
    query.keysonly = [[dict valueForKey:@"keysonly"] boolValue];

  if ([dict valueForKey:@"filter"]) {
    for (NSArray *arr in [dict valueForKey:@"filter"])
      [query addFilter:[DSFilter filterWithArray:arr]];
  }

  if ([dict valueForKey:@"order"]) {
    for (NSString *str in [dict valueForKey:@"order"])
      [query addOrder:[DSOrder orderWithString:str]];
  }

  return [query autorelease];
}

@end

