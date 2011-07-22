
#import "DSKey.h"

@interface KeyTest : GHTestCase {
}
@end

#ifndef DSKeySTR
#define DSKeySTR(str) [[DSKey keyWithString:str] string]
#endif

@implementation KeyTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void) __subtest_basic_string:(NSString *)string {
  string = [string absolutePathString];
  NSArray *compts = [string componentsSeparatedByString:@"/"];

  GHAssertEqualStrings(string, DSKeySTR(string), @"strs");
  GHAssertTrue([DSKeyFmt(@"/P/%@", string) isEqualToKey:
    [DSKey(@"/P/") childWithKey:DSKey(string)]], @"strs");
  GHAssertTrue([DSKeyFmt(@"/P/%@", string) isEqual:
    [DSKey(@"/P/") childWithKey:DSKey(string)]], @"strs");
  GHAssertTrue([DSKeyFmt(@"/%@/C", string) isEqualToKey:
    [DSKey(string) childWithString:@"C"]], @"strs");
  GHAssertTrue([DSKeyFmt(@"/%@/C", string) isEqual:
    [DSKey(string) childWithString:@"C"]], @"strs");
  GHAssertTrue([DSKey(string) compare:DSKey(string)] == NSOrderedSame, @"strs");
  GHAssertTrue([DSKey(string) isEqualToKey:DSKey(string)], @"strs");
  GHAssertTrue([DSKey(string) isEqual:DSKey(string)], @"strs");
  GHAssertFalse([DSKey(string) isEqual:string], @"strs");
  GHAssertTrue([DSKey(string) compare:DSKey(string)] == NSOrderedSame, @"strs");
  GHAssertEqualStrings(DSKey(string).name, [compts lastObject], @"strs");

  if ([compts count] > 1) {
    NSString *secondToLast = [compts objectAtIndex:[compts count] - 2];
    GHAssertEqualStrings(DSKey(string).type, secondToLast, @"strs");
  }

  GHAssertTrue(([compts count] <= 2) == [DSKey(string) isTopLevelKey], @"strs");
  GHAssertTrue([DSKey(string).parent isAncestorOfKey:DSKey(string)], @"strs");
}

- (void) test_basic {

  [self __subtest_basic_string:@""];
  [self __subtest_basic_string:@"abcde"];
  [self __subtest_basic_string:@"disahfidsalfhduisaufidsail"];
  [self __subtest_basic_string:@"/fdisahfodisa/fdsa/fdsafdsafdsa/fdsafdsa/"];
  [self __subtest_basic_string:@"/A/b/C/d/E/f/G/G/g/?g/g"];
  [self __subtest_basic_string:@"A/b/C/d/E/f/G/G/g/?g/g"];
  [self __subtest_basic_string:@"dsafdasfdsafdsafdsa/fdsa"];
  [self __subtest_basic_string:@"41432143214t321t473174723194732189"];
  [self __subtest_basic_string:@"/fdisaha////fdsa////fdsafdsafdsa/fdsafdsa/"];

}

- (void) test_ancestry {
  DSKey *k1 = DSKey(@"/A/B/C");
  DSKey *k2 = DSKey(@"/A/B/C/D");

  GHAssertEqualStrings(k1.string, @"/A/B/C", @"strings should equal");
  GHAssertEqualStrings(k2.string, @"/A/B/C/D", @"strings should equal");
  GHAssertTrue([k1 isAncestorOfKey:k2], @"ancestry");
  GHAssertTrue([k1 isEqualToKey:k2.parent], @"parent");
  GHAssertTrue([k1 isEqual:k2.parent], @"parent");
  GHAssertTrue([[k1 childWithString:@"D"] isEqualToKey:k2], @"child");
  GHAssertTrue([[k1 childWithString:@"D"] isEqual:k2], @"child");

  GHAssertEqualStrings(k1.type, @"B", @"strings should equal");
  GHAssertEqualStrings(k2.type, @"C", @"strings should equal");
  GHAssertEqualStrings(k2.type, k1.name, @"strings should equal");
}


- (void) test_equal_hash {

  NSMutableArray *array = [NSMutableArray array];
  NSMutableSet *set = [NSMutableSet set];


  for (int i = 0; i < 100; i++) {
    DSKey *ki = DSKeyFmt(@"/A/B/C/D/%d", i);
    [array addObject:ki];
    [set addObject:ki];

    for (int j = 0; j < 100; j++) {
      DSKey *kj = DSKeyFmt(@"/A/B/C/D/%d", j);
      if (i == j) {
        GHAssertEqualObjects(ki, kj, @"%@ should equal %@", ki, kj);
        GHAssertTrue([ki isEqual:kj], @"%@ should equal %@? %d", ki, kj);
        GHAssertTrue([ki isEqualToKey:kj], @"%@ should equal %@", ki, kj);
        GHAssertTrue([ki hash] == [kj hash],
          @"%d should equal %@d", [ki hash], [kj hash]);

        GHAssertTrue([array containsObject:kj], @"array snot contain %@", kj);
        GHAssertTrue([set containsObject:kj], @"dict snot contain %@", kj);
      } else {
        GHAssertNotEqualObjects(ki, kj, @"%@ snot equal %@", ki, kj);
        GHAssertFalse([ki isEqual:kj], @"%@ snot equal %@? %d", ki, kj);
        GHAssertFalse([ki isEqualToKey:kj], @"%@ snot equal %@", ki, kj);
        GHAssertFalse([ki hash] == [kj hash],
          @"%d should equal %@d", [ki hash], [kj hash]);

        GHAssertFalse([array containsObject:kj], @"array snot contain %@", kj);
        GHAssertFalse([set containsObject:kj], @"dict snot contain %@", kj);

      }
    }

    [array removeObject:ki];
    [set removeObject:ki];
  }





}

@end
