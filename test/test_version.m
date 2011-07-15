
#import "DSKey.h"
#import "DSVersion.h"
#import "DSSerialRep.h"
#import "NSString+SHA.h"

@interface VersionTest : GHTestCase {
}
@end

@implementation VersionTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void) test_blank {

  DSVersion *blank = [DSVersion blankVersionWithKey:[DSKey keyWithString:@"A"]];
  GHAssertEqualStrings([blank.key string], @"/A", @"cmp");
  GHAssertEqualStrings(blank.hashstr,
    @"0000000000000000000000000000000000000000", @"cmp");
  GHAssertEqualStrings(blank.parent,
    @"0000000000000000000000000000000000000000", @"cmp");
  GHAssertEqualStrings(blank.type, @"", @"cmp");
  GHAssertTrue(blank.committed.ns == 0, @"cmp" );
  GHAssertTrue(blank.isBlank, @"cmp");

  DSVersion *bl2 = [DSVersion blankVersionWithKey:[DSKey keyWithString:@"BBB"]];
  GHAssertTrue(bl2.isBlank, @"cmp");
  GHAssertTrue([blank isEqualToVersion:bl2], @"cmp");
  GHAssertFalse([blank.key isEqualToKey:bl2.key], @"cmp");

}

- (void) test_creation {

  NSString *h1 = [[NSString stringWithFormat:@"herp"] sha1HexDigest];
  NSString *h2 = [[NSString stringWithFormat:@"derp"] sha1HexDigest];

  DSMutableSerialRep *sr = [[DSMutableSerialRep alloc] init];
  [sr setValue:@"/A/B/C" forKey:@"key"];
  [sr setValue:h1 forKey:@"hash"];
  [sr setValue:h2 forKey:@"parent"];
  [sr setValue:[NSNumber numberWithLongLong:0] forKey:@"committed"];
  [sr setValue:[NSNumber numberWithLongLong:0] forKey:@"created"];
  [sr setValue:[NSMutableDictionary dictionary] forKey:@"attributes"];
  [sr setValue:@"Hurr" forKey:@"type"];

  DSVersion *v = [[DSVersion alloc] initWithSerialRep:sr];
  GHAssertEqualStrings([v.key string], @"/A/B/C", @"creation");
  GHAssertEqualStrings(v.hashstr, h1, @"creation");
  GHAssertEqualStrings(v.parent, h2, @"creation");
  GHAssertTrue(v.committed.ns == 0, @"creation");
  GHAssertTrue(v.created.ns == 0, @"creation");
  GHAssertEqualStrings(v.type, @"Hurr", @"creation");

  [sr release];
}


@end
