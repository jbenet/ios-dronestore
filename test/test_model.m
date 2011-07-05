
#import "DSKey.h"
#import "DSVersion.h"
#import "DSModel.h"
#import <GHUnit/GHUnit.h>
#import "NSString+SHA.h"

@interface ModelTest : GHTestCase {
}
@end

@implementation ModelTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void) test_basic {

  DSModel *a = [[DSModel alloc] initWithKey:[DSKey keyWithString:@"/Model/A"]];
  GHAssertEqualStrings([a.key string], @"/Model/A", @"basic");
  GHAssertEqualStrings([a dstype], @"DSModel", @"basic");
  GHAssertEqualStrings([[a class] dstype], @"DSModel", @"basic");
  GHAssertTrue(a.version.isBlank, @"DSModel", @"basic");

  NSString *oldHash = a.version.hashstr;

  [a commit];
  GHAssertEqualStrings([a.key string], @"/Model/A", @"basic");
  GHAssertEqualStrings([a dstype], @"DSModel", @"basic");
  GHAssertEqualStrings([[a class] dstype], @"DSModel", @"basic");
  GHAssertEqualStrings(a.version.parent, oldHash, @"basic");


}

- (void) test_creation {


}


@end
