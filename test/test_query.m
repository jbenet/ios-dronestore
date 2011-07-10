
#import "DSKey.h"
#import "DSQuery.h"
#import "DSVersion.h"
#import "DSModel.h"
#import "NSString+SHA.h"
#import "DSComparable.h"
#import <GHUnit/GHUnit.h>

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

  sr = [[DSMutableSerialRep alloc] init];
  [sr setValue:@"/ABCD" forKey:@"key"];
  [sr setValue:h1 forKey:@"hash"];
  [sr setValue:DSVersionBlankHash forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_now().ns]
    forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_now().ns]
    forKey:@"created"];
  [sr setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDictionary
    dictionaryWithObjectsAndKeys:@"herp", @"value", nil], @"str", nil]
    forKey:@"attributes"];
  [sr setValue:@"Hurr" forKey:@"type"];

  DSVersion *v1 = [[[DSVersion alloc] initWithSerialRep:sr] autorelease];

  sr = [[DSMutableSerialRep alloc] init];
  [sr setValue:@"/ABCD" forKey:@"key"];
  [sr setValue:h2 forKey:@"hash"];
  [sr setValue:h1 forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_now().ns]
    forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_now().ns]
    forKey:@"created"];
  [sr setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDictionary
    dictionaryWithObjectsAndKeys:@"derp", @"value", nil], @"str", nil]
    forKey:@"attributes"];
  [sr setValue:@"Hurr" forKey:@"type"];

  DSVersion *v2 = [[[DSVersion alloc] initWithSerialRep:sr] autorelease];

  sr = [[DSMutableSerialRep alloc] init];
  [sr setValue:@"/ABCD" forKey:@"key"];
  [sr setValue:h3 forKey:@"hash"];
  [sr setValue:h2 forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_now().ns]
    forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:nanotime_now().ns]
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


@end
