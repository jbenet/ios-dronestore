
#import "DSSerialRep.h"

@interface SerialRepTest : GHTestCase {
}
@end

@implementation SerialRepTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void) test_basic {

  NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"a", @"a",
    @"b", @"b", @"c", @"c", @"d", @"d", nil];

  DSMutableSerialRep *rep = [[DSMutableSerialRep alloc] initWithDictionary:d];
  GHAssertEqualStrings([rep valueForKey:@"a"], @"a", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"b"], @"b", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"c"], @"c", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"d"], @"d", @"basic");
  GHAssertNil([rep valueForKey:@"e"], @"nil");
  GHAssertNil([rep valueForKey:@"fdsafdsafsad"], @"nil");
  GHAssertNil([rep valueForKey:@"fdsfdsaafiodjsaoi"], @"nil");

  [rep setValue:@"e" forKey:@"e"];
  GHAssertEqualStrings([rep valueForKey:@"e"], @"e", @"basic");
  [rep setValue:@"f" forKey:@"d"];
  GHAssertEqualStrings([rep valueForKey:@"d"], @"f", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"a"], @"a", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"b"], @"b", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"c"], @"c", @"basic");

  [rep setValue:nil forKey:@"a"];
  GHAssertEqualStrings([rep valueForKey:@"d"], @"f", @"basic");
  GHAssertNil([rep valueForKey:@"a"], @"nil");
  GHAssertEqualStrings([rep valueForKey:@"b"], @"b", @"basic");
  GHAssertEqualStrings([rep valueForKey:@"c"], @"c", @"basic");

  [rep release];

}

- (void) test_conversions {

  NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"abc",
    @"afdsaffa", @"bfdsafa", @"b43214", @"c6543", @"cgfg", @"d", @"d", nil];

  DSMutableSerialRep *rep = [[DSMutableSerialRep alloc] initWithDictionary:d];

  NSData *data = [rep BSON];
  DSMutableSerialRep *rep2;
  rep2 = (DSMutableSerialRep *)[DSMutableSerialRep representationWithBSON:data];

  for (NSString *key in rep.contents) {
    GHAssertEqualStrings([rep valueForKey:key], [rep2 valueForKey:key], @"eq");
  }


}


@end
