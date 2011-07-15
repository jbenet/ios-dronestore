
#import "DSKey.h"

@interface KeyTest : GHTestCase {
}
@end

#ifndef DSKEY
#define DSKEY(str) [DSKey keyWithString:str]
#endif

#ifndef DSKEYSTR
#define DSKEYSTR(str) [[DSKey keyWithString:str] string]
#endif

@implementation KeyTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void) __subtest_basic_string:(NSString *)string {
  string = [string absolutePathString];
  NSArray *compts = [string componentsSeparatedByString:@"/"];

  GHAssertEqualStrings(string, DSKEYSTR(string), @"strs");
  GHAssertTrue([DSKEY(string) isEqualToKey:DSKEY(string)], @"strs");
  GHAssertTrue([DSKEY(string) compare:DSKEY(string)] == NSOrderedSame, @"strs");
  GHAssertEqualStrings(DSKEY(string).name, [compts lastObject], @"strs");

  if ([compts count] > 1) {
    NSString *secondToLast = [compts objectAtIndex:[compts count] - 2];
    GHAssertEqualStrings(DSKEY(string).type, secondToLast, @"strs");
  }

  GHAssertTrue(([compts count] <= 2) == [DSKEY(string) isTopLevelKey], @"strs");
  GHAssertTrue([DSKEY(string).parent isAncestorOfKey:DSKEY(string)], @"strs");
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
  DSKey *k1 = DSKEY(@"/A/B/C");
  DSKey *k2 = DSKEY(@"/A/B/C/D");

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
