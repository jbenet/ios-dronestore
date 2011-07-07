
#import "DSKey.h"
#import "DSVersion.h"
#import "DSModel.h"
#import "DSAttribute.h"
#import "DSMerge.h"

#import <GHUnit/GHUnit.h>
#import "NSString+SHA.h"

#import "TestPerson.h"


@interface MergeTest : GHTestCase {
}
@end

@implementation MergeTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}


- (void) __subtestBlankPerson:(TestPerson *)person {

  GHAssertEqualStrings(person.first, @"", @"blank firstname");
  GHAssertEqualStrings(person.last, @"", @"blank firstname");
  GHAssertEqualStrings(person.phone, @"0", @"blank firstname");
  GHAssertTrue(person.age == 1, @"blank age");
  GHAssertTrue(fabs(person.awesome - 0.1) < 0.000001, @"blank awesone");

  GHAssertTrue(person.version.isBlank, @"must have blank version");
  GHAssertFalse(person.isCommitted, @"must not be committed");

}

- (void) __subtestCommittedPerson:(TestPerson *)person {
  GHAssertFalse(person.version.isBlank, @"must not have blank version");
  GHAssertTrue(person.isCommitted, @"must not have blank version");

  GHAssertEqualStrings([person.version valueForAttribute:@"first"],
    person.first, @"version: first");
  GHAssertEqualStrings([person.version valueForAttribute:@"last"],
    person.last, @"version: last");
  GHAssertEqualStrings([person.version valueForAttribute:@"phone"],
    person.phone, @"version: phone");
  GHAssertTrue(person.age == [[person.version valueForAttribute:@"age"]
    intValue], @"version: age");
  GHAssertTrue(fabs([[person.version valueForAttribute:@"awesome"]
    floatValue] - person.awesome) < 0.000001, @"version: awesome");

  for (DSAttribute *attr in [[TestPerson attributes] allValues]) {
    GHAssertEqualObjects([attr valueForInstance:person],
      [person.version valueForAttribute:attr.name], @"attr eq version");
  }

}


- (void) __subtestPerson:(TestPerson *)p1 otherPerson:(TestPerson *)p2
  diffAttrs:(NSArray *)attrs {

  GHAssertEqualStrings([p1 dstype], [p2 dstype], @"type");
  GHAssertEqualStrings(p1.key.string, p2.key.string, @"keys");

  GHAssertEqualStrings(p1.version.type, p2.version.type, @"type");
  GHAssertTrue((p1.version.isBlank == p2.version.isBlank), @"blank");
  GHAssertTrue(p1.isCommitted == p2.isCommitted, @"committed");

  if (attrs == nil) {
    GHAssertTrue([p1.version isEqualToVersion:p2.version], @"version eq.");
    GHAssertEqualStrings(p1.version.hashstr, p2.version.hashstr, @"ver eq.");
  } else {
    GHAssertFalse([p1.version isEqualToVersion:p2.version], @"version neq.");
    GHAssertNotEqualStrings(p1.version.hashstr, p2.version.hashstr, @"ver");

  }

  for (DSAttribute *attr in [[TestPerson attributes] allValues]) {

    if ([attrs containsObject:attr.name]) {
      NSLog(@"%@ should not be equal", attr.name);
      GHAssertNotEqualObjects([p1.version valueForAttribute:attr.name],
        [p2.version valueForAttribute:attr.name], @"val");
      GHAssertNotEqualObjects([attr valueForInstance:p1],
        [attr valueForInstance:p2], @"val");
      GHAssertNotEqualObjects([p1.version valueForAttribute:attr.name],
        [p2.version valueForAttribute:attr.name], @"val");
    } else {
      NSLog(@"%@ should be equal", attr.name);
      GHAssertEqualObjects([p1.version valueForAttribute:attr.name],
        [p2.version valueForAttribute:attr.name], @"val");
      GHAssertEqualObjects([attr valueForInstance:p1],
        [attr valueForInstance:p2], @"val");
      GHAssertEqualObjects([p1.version valueForAttribute:attr.name],
        [p2.version valueForAttribute:attr.name], @"val");
    }
  }

}

- (void) test_basic {

  TestPerson *p1 = [[TestPerson alloc] initWithKeyName:@"Tesla"];
  TestPerson *p2 = [[TestPerson alloc] initWithKeyName:@"Tesla"];

  [self __subtestBlankPerson:p1];
  [self __subtestBlankPerson:p2];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];

  p1.age = 52;
  p2.age = 52;

  [p1 commit];
  NSLog(@"committed p1 %@", p1.version.hashstr);
  [p2 commit];
  NSLog(@"committed p2 %@", p2.version.hashstr);

  [self __subtestCommittedPerson:p1];
  [self __subtestCommittedPerson:p2];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:[NSArray array]];


  p1.first = @"Nikola";
  p1.last = @"Tesla";
  p1.phone = @"7777777777";

  p2.first = @"Nikola";
  p2.last = @"Tesla";
  p2.phone = @"7777777777";

  [p1 commit];
  NSLog(@"committed p1 %@", p1.version.hashstr);
  [p2 commit];
  NSLog(@"committed p2 %@", p2.version.hashstr);

  [self __subtestCommittedPerson:p1];
  [self __subtestCommittedPerson:p2];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:[NSArray array]];

  p1.age = 53;
  [p1 commit];
  NSLog(@"committed p1 %@", p1.version.hashstr);

  [self __subtestCommittedPerson:p1];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:[NSArray
    arrayWithObjects:@"age", nil]];

  p2.awesome = 60.0;
  [p2 commit];
  NSLog(@"committed %@", p1.version.hashstr);

  [self __subtestCommittedPerson:p2];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:[NSArray
    arrayWithObjects:@"age", @"awesome", nil]];


  [p1 mergeVersion:p2.version];
  NSLog(@"p1 merged p2");

  [self __subtestCommittedPerson:p1];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:[NSArray
    arrayWithObjects:@"age", nil]];

  [p2 mergeVersion:p1.version];
  NSLog(@"p2 merged p1");

  [self __subtestCommittedPerson:p2];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:[NSArray array]];


}


@end
