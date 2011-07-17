
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
  GHAssertTrue([DSKeyFmt(@"/%@/C", string) isEqualToKey:
    [DSKey(string) childWithString:@"C"]], @"strs");
  GHAssertTrue([DSKey(string) compare:DSKey(string)] == NSOrderedSame, @"strs");
  GHAssertTrue([DSKey(string) isEqualToKey:DSKey(string)], @"strs");
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
  GHAssertTrue([[k1 childWithString:@"D"] isEqualToKey:k2], @"child");

  GHAssertEqualStrings(k1.type, @"B", @"strings should equal");
  GHAssertEqualStrings(k2.type, @"C", @"strings should equal");
  GHAssertEqualStrings(k2.type, k1.name, @"strings should equal");
}


@end
