
#import "DSKey.h"
#import "DSQuery.h"
#import "DSVersion.h"
#import "DSModel.h"
#import "NSString+SHA.h"
#import "DSComparable.h"

#import "TestPerson.h"

@interface QueryTest : GHTestCase {
}
@end

@implementation QueryTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (NSArray *) versions {
  NSString *h1 = [[NSString stringWithFormat:@"herp"] sha1HexDigest];
  NSString *h2 = [[NSString stringWithFormat:@"derp"] sha1HexDigest];
  NSString *h3 = [[NSString stringWithFormat:@"lerp"] sha1HexDigest];
  DSMutableSerialRep *sr = nil;

  sr = [[[DSMutableSerialRep alloc] init] autorelease];
  [sr setValue:@"/ABCD" forKey:@"key"];
  [sr setValue:h1 forKey:@"hash"];
  [sr setValue:DSVersionBlankHash forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_utc_now().ns]
    forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_utc_now().ns]
    forKey:@"created"];
  [sr setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDictionary
    dictionaryWithObjectsAndKeys:@"herp", @"value", nil], @"str", nil]
    forKey:@"attributes"];
  [sr setValue:@"Hurr" forKey:@"type"];

  DSVersion *v1 = [[[DSVersion alloc] initWithSerialRep:sr] autorelease];

  sr = [[[DSMutableSerialRep alloc] init] autorelease];
  [sr setValue:@"/ABCD" forKey:@"key"];
  [sr setValue:h2 forKey:@"hash"];
  [sr setValue:h1 forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_utc_now().ns]
    forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_utc_now().ns]
    forKey:@"created"];
  [sr setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDictionary
    dictionaryWithObjectsAndKeys:@"derp", @"value", nil], @"str", nil]
    forKey:@"attributes"];
  [sr setValue:@"Hurr" forKey:@"type"];

  DSVersion *v2 = [[[DSVersion alloc] initWithSerialRep:sr] autorelease];

  sr = [[[DSMutableSerialRep alloc] init] autorelease];
  [sr setValue:@"/ABCD" forKey:@"key"];
  [sr setValue:h3 forKey:@"hash"];
  [sr setValue:h2 forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_utc_now().ns]
    forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_utc_now().ns]
    forKey:@"created"];
  [sr setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDictionary
    dictionaryWithObjectsAndKeys:@"lerp", @"value", nil], @"str", nil]
    forKey:@"attributes"];
  [sr setValue:@"Hurr" forKey:@"type"];

  DSVersion *v3 = [[[DSVersion alloc] initWithSerialRep:sr] autorelease];

  return [NSArray arrayWithObjects:v1, v2, v3, nil];
}

- (void) test_filter {

  NSArray *vs = [self versions];
  DSVersion *v1 = [vs objectAtIndex:0];
  DSVersion *v2 = [vs objectAtIndex:1];
  DSVersion *v3 = [vs objectAtIndex:2];

  nanotime t1 = v1.committed;
  nanotime t2 = v2.committed;
  nanotime t3 = v3.committed;

  DSFilter *fk_gt_a = [DSFilter filter:@"key" op:DSCompOpGreaterThan
    value:@"/A"];

  GHAssertTrue([fk_gt_a objectPasses:v1], @"fk_gt_a objectPasses v1");
  GHAssertTrue([fk_gt_a objectPasses:v2], @"fk_gt_a objectPasses v2");
  GHAssertTrue([fk_gt_a objectPasses:v3], @"fk_gt_a objectPasses v3");

  GHAssertTrue([fk_gt_a valuePasses:@"/BCDEG"], @"fk_gt_a vP 1");
  GHAssertTrue([fk_gt_a valuePasses:@"/ZCDE/fdsafa/fas"], @"fk_gt_a vP 1");
  GHAssertFalse([fk_gt_a valuePasses:@"/6353456346543"], @"fk_gt_a vP 1");
  GHAssertFalse([fk_gt_a valuePasses:@"."], @"fk_gt_a vP 1");
  GHAssertTrue([fk_gt_a valuePasses:@"afsdafdsa"], @"fk_gt_a vP 1");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_gt_a]], vs, @"fk_gt_a fAwF");


  DSFilter *fk_lt_a = [DSFilter filter:@"key" op:DSCompOpLessThan
    value:@"/A"];

  GHAssertFalse([fk_lt_a objectPasses:v1], @"fk_lt_a objectPasses v1");
  GHAssertFalse([fk_lt_a objectPasses:v2], @"fk_lt_a objectPasses v2");
  GHAssertFalse([fk_lt_a objectPasses:v3], @"fk_lt_a objectPasses v3");

  GHAssertFalse([fk_lt_a valuePasses:@"/BCDEG"], @"fk_lt_a vP 1");
  GHAssertFalse([fk_lt_a valuePasses:@"/ZCDE/fdsafa/fas"], @"fk_lt_a vP 1");
  GHAssertTrue([fk_lt_a valuePasses:@"/6353456346543"], @"fk_lt_a vP 1");
  GHAssertTrue([fk_lt_a valuePasses:@"."], @"fk_lt_a vP 1");
  GHAssertFalse([fk_lt_a valuePasses:@"afsdafdsa"], @"fk_lt_a vP 1");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_lt_a]], [NSArray array], @"fk_lt_a fAwF");


  DSFilter *fk_eq_a = [DSFilter filter:@"key" op:DSCompOpEqual value:@"/ABCD"];

  GHAssertTrue([fk_eq_a objectPasses:v1], @"fk_eq_a objectPasses v1");
  GHAssertTrue([fk_eq_a objectPasses:v2], @"fk_eq_a objectPasses v2");
  GHAssertTrue([fk_eq_a objectPasses:v3], @"fk_eq_a objectPasses v3");

  GHAssertFalse([fk_eq_a valuePasses:@"/BCDEG"], @"fk_eq_a vP 1");
  GHAssertFalse([fk_eq_a valuePasses:@"/ZCDE/fdsafa/fas"], @"fk_eq_a vP 1");
  GHAssertFalse([fk_eq_a valuePasses:@"/6353456346543"], @"fk_eq_a vP 1");
  GHAssertFalse([fk_eq_a valuePasses:@"."], @"fk_eq_a vP 1");
  GHAssertFalse([fk_eq_a valuePasses:@"afsdafdsa"], @"fk_eq_a vP 1");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_eq_a]], vs, @"fk_lt_a fAwF");


  DSFilter *fk_gt_b = [DSFilter filter:@"key" op:DSCompOpGreaterThan
    value:@"/B"];

  GHAssertFalse([fk_gt_b objectPasses:v1], @"fk_gt_b objectPasses v1");
  GHAssertFalse([fk_gt_b objectPasses:v2], @"fk_gt_b objectPasses v2");
  GHAssertFalse([fk_gt_b objectPasses:v3], @"fk_gt_b objectPasses v3");

  GHAssertFalse([fk_gt_b valuePasses:@"/A"], @" vP 1");
  GHAssertTrue([fk_gt_b valuePasses:@"/BCDEG"], @" vP 1");
  GHAssertTrue([fk_gt_b valuePasses:@"/ZCDE/fdsafa/fas"], @" vP 1");
  GHAssertFalse([fk_gt_b valuePasses:@"/6353456346543"], @" vP 1");
  GHAssertFalse([fk_gt_b valuePasses:@"."], @" vP 1");
  GHAssertTrue([fk_gt_b valuePasses:@"afsdafdsa"], @" vP 1");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_gt_b]], [NSArray array], @"fk_gt_a fAwF");


  DSFilter *fk_lt_b = [DSFilter filter:@"key" op:DSCompOpLessThan
    value:@"/B"];

  GHAssertTrue([fk_lt_b objectPasses:v1], @"fk_gt_b objectPasses v1");
  GHAssertTrue([fk_lt_b objectPasses:v2], @"fk_gt_b objectPasses v2");
  GHAssertTrue([fk_lt_b objectPasses:v3], @"fk_gt_b objectPasses v3");

  GHAssertTrue([fk_lt_b valuePasses:@"/A"], @" vP 1");
  GHAssertFalse([fk_lt_b valuePasses:@"/BCDEG"], @" vP 1");
  GHAssertFalse([fk_lt_b valuePasses:@"/ZCDE/fdsafa/fas"], @" vP 1");
  GHAssertTrue([fk_lt_b valuePasses:@"/6353456346543"], @" vP 1");
  GHAssertTrue([fk_lt_b valuePasses:@"."], @" vP 1");
  GHAssertFalse([fk_lt_b valuePasses:@"afsdafdsa"], @" vP 1");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_lt_b]], vs, @"fk_lt_a fAwF");


  DSFilter *fk_gt_ab = [DSFilter filter:@"key" op:DSCompOpGreaterThan
    value:@"/AB"];

  GHAssertTrue([fk_gt_ab objectPasses:v1], @"fk_gt_ab objectPasses v1");
  GHAssertTrue([fk_gt_ab objectPasses:v2], @"fk_gt_ab objectPasses v2");
  GHAssertTrue([fk_gt_ab objectPasses:v3], @"fk_gt_ab objectPasses v3");

  GHAssertFalse([fk_gt_ab valuePasses:@"/A"], @" vP 1");
  GHAssertTrue([fk_gt_ab valuePasses:@"/BCDEG"], @" vP 1");
  GHAssertTrue([fk_gt_ab valuePasses:@"/ZCDE/fdsafa/fas"], @" vP 1");
  GHAssertFalse([fk_gt_ab valuePasses:@"/6353456346543"], @" vP 1");
  GHAssertFalse([fk_gt_ab valuePasses:@"."], @" vP 1");
  GHAssertTrue([fk_gt_ab valuePasses:@"afsdafdsa"], @" vP 1");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_gt_ab]], vs, @"fk_gt_ab fAwF");
  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObjects:fk_gt_ab, fk_lt_b, nil]]), vs, @"multifilter");
  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObjects:fk_lt_b, fk_gt_ab, nil]]), vs, @"multifilter");



  DSFilter *fk_gte_t1 = [DSFilter filter:@"committed"
    op:DSCompOpGreaterThanOrEqual value:[NSNumber numberWithLongLong:t1.ns]];
  DSFilter *fk_gte_t2 = [DSFilter filter:@"committed"
    op:DSCompOpGreaterThanOrEqual value:[NSNumber numberWithLongLong:t2.ns]];
  DSFilter *fk_gte_t3 = [DSFilter filter:@"committed"
    op:DSCompOpGreaterThanOrEqual value:[NSNumber numberWithLongLong:t3.ns]];

  GHAssertTrue([fk_gte_t1 objectPasses:v1], @"fk_gte_t1 objectPasses v1");
  GHAssertTrue([fk_gte_t1 objectPasses:v2], @"fk_gte_t1 objectPasses v2");
  GHAssertTrue([fk_gte_t1 objectPasses:v3], @"fk_gte_t1 objectPasses v3");

  GHAssertFalse([fk_gte_t2 objectPasses:v1], @"fk_gte_t2 objectPasses v1");
  GHAssertTrue([fk_gte_t2 objectPasses:v2], @"fk_gte_t2 objectPasses v2");
  GHAssertTrue([fk_gte_t2 objectPasses:v3], @"fk_gte_t2 objectPasses v3");

  GHAssertFalse([fk_gte_t3 objectPasses:v1], @"fk_gte_t3 objectPasses v1");
  GHAssertFalse([fk_gte_t3 objectPasses:v2], @"fk_gte_t3 objectPasses v2");
  GHAssertTrue([fk_gte_t3 objectPasses:v3], @"fk_gte_t3 objectPasses v3");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_gte_t1]], vs, @"fk_gt_ab fAwF");
  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_gte_t2]]),
    ([NSArray arrayWithObjects:v2, v3, nil]), @"multifilter");
  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_gte_t3]], [NSArray arrayWithObject:v3],
    @"multifilter");



  DSFilter *fk_lte_t1 = [DSFilter filter:@"committed" op:DSCompOpLessThanOrEqual
    value:[NSNumber numberWithLongLong:t1.ns]];
  DSFilter *fk_lte_t2 = [DSFilter filter:@"committed" op:DSCompOpLessThanOrEqual
    value:[NSNumber numberWithLongLong:t2.ns]];
  DSFilter *fk_lte_t3 = [DSFilter filter:@"committed" op:DSCompOpLessThanOrEqual
    value:[NSNumber numberWithLongLong:t3.ns]];


  GHAssertTrue([fk_lte_t1 objectPasses:v1], @"fk_lte_t1 objectPasses v1");
  GHAssertFalse([fk_lte_t1 objectPasses:v2], @"fk_lte_t3 objectPasses v2");
  GHAssertFalse([fk_lte_t1 objectPasses:v3], @"fk_lte_t2 objectPasses v3");

  GHAssertTrue([fk_lte_t2 objectPasses:v1], @"fk_lte_t2 objectPasses v1");
  GHAssertTrue([fk_lte_t2 objectPasses:v2], @"fk_lte_t3 objectPasses v2");
  GHAssertFalse([fk_lte_t2 objectPasses:v3], @"fk_lte_t1 objectPasses v3");

  GHAssertTrue([fk_lte_t3 objectPasses:v1], @"fk_gte_t3 objectPasses v1");
  GHAssertTrue([fk_lte_t3 objectPasses:v2], @"fk_gte_t3 objectPasses v2");
  GHAssertTrue([fk_lte_t3 objectPasses:v3], @"fk_gte_t3 objectPasses v3");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_lte_t1]], [NSArray arrayWithObject:v1],
    @"fk_gt_ab fAwF");
  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_lte_t2]]),
    ([NSArray arrayWithObjects:v1, v2, nil]), @"multifilter");
  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_lte_t3]], vs,
    @"multifilter");

  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObjects:fk_gte_t2, fk_lte_t2, nil]]),
    ([NSArray arrayWithObject:v2]), @"fk_gt_ab fAwF");
  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObjects:fk_gte_t1, fk_lte_t3, nil]]),
    vs, @"fk_gt_ab fAwF");
  GHAssertEqualObjects(([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObjects:fk_gte_t3, fk_lte_t1, nil]]),
    ([NSArray array]), @"fk_gt_ab fAwF");


  DSFilter *fk_eq_t1 = [DSFilter filter:@"committed" op:DSCompOpEqual
    value:[NSNumber numberWithLongLong:t1.ns]];
  DSFilter *fk_eq_t2 = [DSFilter filter:@"committed" op:DSCompOpEqual
    value:[NSNumber numberWithLongLong:t2.ns]];
  DSFilter *fk_eq_t3 = [DSFilter filter:@"committed" op:DSCompOpEqual
    value:[NSNumber numberWithLongLong:t3.ns]];

  GHAssertTrue([fk_eq_t1 objectPasses:v1], @"fk_eq_t1 objectPasses v1");
  GHAssertFalse([fk_eq_t1 objectPasses:v2], @"fk_eq_t2 objectPasses v2");
  GHAssertFalse([fk_eq_t1 objectPasses:v3], @"fk_eq_t3 objectPasses v3");

  GHAssertFalse([fk_eq_t2 objectPasses:v1], @"fk_eq_t3 objectPasses v1");
  GHAssertTrue([fk_eq_t2 objectPasses:v2], @"fk_eq_t3 objectPasses v2");
  GHAssertFalse([fk_eq_t2 objectPasses:v3], @"fk_eq_t3 objectPasses v3");

  GHAssertFalse([fk_eq_t3 objectPasses:v1], @"fk_eq_t3 objectPasses v1");
  GHAssertFalse([fk_eq_t3 objectPasses:v2], @"fk_eq_t3 objectPasses v2");
  GHAssertTrue([fk_eq_t3 objectPasses:v3], @"fk_eq_t3 objectPasses v3");

  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_eq_t1]], [NSArray arrayWithObject:v1],
    @"fk_eq_t1 fAwF");
  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_eq_t2]], [NSArray arrayWithObject:v2],
    @"fk_eq_t2 fAwF");
  GHAssertEqualObjects([DSFilter filteredArray:vs withFilters:
    [NSArray arrayWithObject:fk_eq_t3]], [NSArray arrayWithObject:v3],
    @"fk_eq_t3 fAwF");

}


- (void) test_filter_order {
  NSNumber *t1 = [NSNumber numberWithLongLong:nanotime_utc_now().ns];
  NSNumber *t2 = [NSNumber numberWithLongLong:nanotime_utc_now().ns];

  DSFilter *f1 = [DSFilter filter:@"key" op:DSCompOpGreaterThan value:@"/A"];
  DSFilter *f2 = [DSFilter filter:@"key" op:DSCompOpLessThan value:@"/A"];
  DSFilter *f3 = [DSFilter filter:@"committed" op:DSCompOpEqual value:t1];
  DSFilter *f4 = [DSFilter filter:@"committed" op:DSCompOpGreaterThanOrEqual
    value:t2];

  GHAssertEqualObjects(([f1 array]), ([NSArray arrayWithObjects:@"key",
    DSCompOpGreaterThan, @"/A", nil]), @"array equals");
  GHAssertEqualObjects(([f2 array]), ([NSArray arrayWithObjects:@"key",
    DSCompOpLessThan, @"/A", nil]), @"array equals");
  GHAssertEqualObjects(([f3 array]), ([NSArray arrayWithObjects:@"committed",
    DSCompOpEqual, t1, nil]), @"array equals");
  GHAssertEqualObjects(([f4 array]), ([NSArray arrayWithObjects:@"committed",
    DSCompOpGreaterThanOrEqual, t2, nil]), @"array equals");
}

- (void) test_order {
  DSOrder *o1 = [DSOrder orderWithString:@"key"];
  DSOrder *o2 = [DSOrder orderWithString:@"+committed"];
  DSOrder *o3 = [DSOrder orderWithString:@"-created"];

  NSArray *vs = [self versions];
  DSVersion *v1 = [vs objectAtIndex:0];
  DSVersion *v2 = [vs objectAtIndex:1];
  DSVersion *v3 = [vs objectAtIndex:2];

  GHAssertTrue(o1.isAscending, @"ascending");
  GHAssertTrue(o2.isAscending, @"ascending");
  GHAssertFalse(o3.isAscending, @"ascending");

  #define assert_sorting(in1, in2, in3, o1, o2, o3, out1, out2, out3)        \
    GHAssertEqualObjects(([DSOrder                                           \
      sortedArray:[NSArray arrayWithObjects: in1, in2, in3, nil]             \
      withOrders:[NSArray arrayWithObjects:o1, o2, o3, nil]]),               \
    ([NSArray arrayWithObjects:out1, out2, out3, nil]),                      \
    @"Testing DSOrder([in1, in2, in3], [o1, o2, o3]) = [out1, out2, out3]");

  assert_sorting(v3, v2, v1,  o1, nil, nil,  v3, v2, v1);
  assert_sorting(v3, v2, v1,  o1, o2,  nil,  v1, v2, v3);
  assert_sorting(v1, v3, v2,  o1, o3,  nil,  v3, v2, v1);
  assert_sorting(v3, v2, v1,  o1, o2,  o3,   v1, v2, v3);
  assert_sorting(v1, v3, v2,  o1, o3,  o2,   v3, v2, v1);

  assert_sorting(v3, v2, v1,  o2, nil, nil,  v1, v2, v3);
  assert_sorting(v3, v2, v1,  o2, o1,  nil,  v1, v2, v3);
  assert_sorting(v3, v2, v1,  o2, o3,  nil,  v1, v2, v3);
  assert_sorting(v3, v2, v1,  o2, o1,  o3,   v1, v2, v3);
  assert_sorting(v3, v2, v1,  o2, o3,  o1,   v1, v2, v3);

  assert_sorting(v1, v2, v3,  o3, nil, nil,  v3, v2, v1);
  assert_sorting(v1, v2, v3,  o3, o2,  nil,  v3, v2, v1);
  assert_sorting(v1, v2, v3,  o3, o3,  nil,  v3, v2, v1);
  assert_sorting(v1, v2, v3,  o3, o2,  o3,   v3, v2, v1);
  assert_sorting(v1, v2, v3,  o3, o3,  o2,   v3, v2, v1);

  #undef assert_sorting
}


- (void) test_order_object {

  GHAssertEqualObjects([[DSOrder orderWithString:@"key"] string], @"+key",
    @"equal order objects");
  GHAssertEqualObjects([[DSOrder orderWithString:@"+committed"] string],
    @"+committed", @"equal order objects");
  GHAssertEqualObjects([[DSOrder orderWithString:@"-created"] string],
    @"-created", @"equal order objects");

}

- (void) test_query {
  DSQuery *q1 = [[DSQuery alloc] initWithModel:[TestPerson class]];
  DSQuery *q2 = [[DSQuery alloc] initWithType:[TestPerson dstype]];
  DSQuery *q3 = [[DSQuery alloc] initWithType:[TestPerson dstype]];

  NSNumber *now = [NSNumber numberWithLongLong:nanotime_utc_now().ns];

  q1.limit = 100;
  q2.offset = 200;
  q3.keysonly = YES;

  q1.offset = 300;
  q2.keysonly = YES;
  q3.limit = 1;

  [q1 addFilter:[DSFilter filter:@"key" op:DSCompOpGreaterThan  value:@"/ABC"]];
  [q1 addFilter:[DSFilter filter:@"created" op:DSCompOpGreaterThan  value:now]];

  [q2 addOrder:[DSOrder orderWithString:@"key"]];
  [q2 addOrder:[DSOrder orderWithString:@"-created"]];

  NSDictionary *q1d = [NSDictionary dictionaryWithObjectsAndKeys:
    [TestPerson dstype], @"type",
    [NSNumber numberWithInt:100], @"limit",
    [NSNumber numberWithInt:300], @"offset",
    [NSArray arrayWithObjects:
      [NSArray arrayWithObjects:@"key", DSCompOpGreaterThan, @"/ABC", nil],
      [NSArray arrayWithObjects:@"created", DSCompOpGreaterThan, now, nil],
    nil], @"filter", nil];

  NSDictionary *q2d = [NSDictionary dictionaryWithObjectsAndKeys:
    [TestPerson dstype], @"type",
    [NSNumber numberWithInt:200], @"offset",
    [NSNumber numberWithBool:YES], @"keysonly",
    [NSArray arrayWithObjects:@"+key", @"-created", nil], @"order", nil];

  NSDictionary *q3d = [NSDictionary dictionaryWithObjectsAndKeys:
    [TestPerson dstype], @"type",
    [NSNumber numberWithInt:1], @"limit",
    [NSNumber numberWithBool:YES], @"keysonly", nil];

  GHAssertEqualObjects((q1d), [q1 dictionary], @"query eq dict");
  GHAssertEqualObjects((q2d), [q2 dictionary], @"query eq dict");
  GHAssertEqualObjects((q3d), [q3 dictionary], @"query eq dict");

  GHAssertEqualObjects((q1d), [[DSQuery queryWithDictionary:q1d] dictionary],
    @"query eq dict after construction");
  GHAssertEqualObjects((q2d), [[DSQuery queryWithDictionary:q2d] dictionary],
    @"query eq dict after construction");
  GHAssertEqualObjects((q3d), [[DSQuery queryWithDictionary:q3d] dictionary],
    @"query eq dict after construction");

  [q1 release];
  [q2 release];
  [q3 release];
}

@end
