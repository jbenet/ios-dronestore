
#import "DSKey.h"
#import "DSVersion.h"
#import "DSModel.h"
#import "DSAttribute.h"

#import "NSString+SHA.h"

#import "TestPerson.h"


@interface ModelTest : GHTestCase {
}
@end

@implementation ModelTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}


- (void) test_basic {

  DSModel *a = [[DSModel alloc] initWithKeyName:@"A"];
  GHAssertEqualStrings([a.key string], @"/DSModel/A", @"basic");
  GHAssertEqualStrings([a dstype], @"DSModel", @"basic");
  GHAssertEqualStrings([[a class] dstype], @"DSModel", @"basic");
  GHAssertTrue(a.version.isBlank, @"must have blank version");
  GHAssertFalse(a.isCommitted, @"must not be committed");

  NSString *oldHash = a.version.hashstr;
  [a commit];

  GHAssertEqualStrings([a.key string], @"/DSModel/A", @"basic");
  GHAssertEqualStrings([a dstype], @"DSModel", @"basic");
  GHAssertEqualStrings([[a class] dstype], @"DSModel", @"basic");
  GHAssertEqualStrings(a.version.parent, oldHash, @"basic");
  GHAssertFalse(a.version.isBlank, @"must not have blank version");
  GHAssertTrue(a.isCommitted, @"must be committed");

  [a commit]; // idempotent.

  GHAssertEqualStrings([a.key string], @"/DSModel/A", @"basic");
  GHAssertEqualStrings([a dstype], @"DSModel", @"basic");
  GHAssertEqualStrings([[a class] dstype], @"DSModel", @"basic");
  GHAssertEqualStrings(a.version.parent, oldHash, @"basic");
  GHAssertFalse(a.version.isBlank, @"must not have blank version");
  GHAssertTrue(a.isCommitted, @"must be committed");

  [a commit]; // idempotent.

  GHAssertEqualStrings([a.key string], @"/DSModel/A", @"basic");
  GHAssertEqualStrings([a dstype], @"DSModel", @"basic");
  GHAssertEqualStrings([[a class] dstype], @"DSModel", @"basic");
  GHAssertEqualStrings(a.version.parent, oldHash, @"basic");
  GHAssertFalse(a.version.isBlank, @"must not have blank version");
  GHAssertTrue(a.isCommitted, @"must be committed");

}

- (void) test_person {
  TestPerson *person = [[TestPerson alloc] initWithKeyName:@"HerpDerp"];
  GHAssertTrue([person.key.string isEqualToString:@"/Person/HerpDerp"],
    @"Key Check");
  GHAssertEqualStrings(person.first, @"", @"first");
  GHAssertEqualStrings(person.last, @"", @"last");
  GHAssertEqualStrings(person.phone, @"0", @"phone");
  GHAssertTrue(person.age == 1, @"age");

  // dumb float point math.
  GHAssertTrue(fabs(person.awesome - 0.1) < 0.00000001, @"awesome");
  GHAssertTrue(person.version.isBlank, @"must not have blank version");
  GHAssertFalse(person.isCommitted, @"must be committed");

  NSString *oldHash = person.version.hashstr;
  [person commit];
  GHAssertEqualStrings(person.version.parent, oldHash, @"parent hash");
  GHAssertNotEqualStrings(person.version.hashstr, oldHash, @"parent hash");
  GHAssertFalse(person.version.isBlank, @"must not have blank version");
  GHAssertTrue(person.isCommitted, @"must be committed");

  GHAssertEqualStrings(person.first, @"", @"first");
  GHAssertEqualStrings(person.last, @"", @"last");
  GHAssertEqualStrings(person.phone, @"0", @"phone");
  GHAssertTrue(person.age == 1, @"age");

  // dumb float point math.
  GHAssertTrue(fabs(person.awesome - 0.1) < 0.00000001, @"awesome");


  person.first = @"Herp";
  person.last = @"Derp";
  person.phone = @"1235674444";
  person.age = 5;

  oldHash = person.version.hashstr;
  [person commit];
  GHAssertEqualStrings(person.version.parent, oldHash, @"parent hash");
  GHAssertNotEqualStrings(person.version.hashstr, oldHash, @"parent hash");
  GHAssertFalse(person.version.isBlank, @"must not have blank version");
  GHAssertTrue(person.isCommitted, @"must be committed");

  GHAssertEqualStrings(person.first, @"Herp", @"first");
  GHAssertEqualStrings(person.last, @"Derp", @"last");
  GHAssertEqualStrings(person.phone, @"1235674444", @"phone");
  GHAssertTrue(person.age == 5, @"age");

  GHAssertEqualStrings([[[person class] attributeNamed:@"first"]
    valueForInstance:person], @"Herp", @"attr: first");
  GHAssertEqualStrings([[[person class] attributeNamed:@"last"]
    valueForInstance:person], @"Derp", @"attr: last");
  GHAssertEqualStrings([[[person class] attributeNamed:@"phone"]
    valueForInstance:person], @"1235674444", @"attr: phone");

  GHAssertTrue([[[[person class] attributeNamed:@"age"] valueForInstance:person]
    intValue] == 5, @"version: age");

  // dumb float point math.
  GHAssertTrue(fabs(person.awesome - 0.1) < 0.00000001, @"awesome");

  GHAssertEqualStrings([person.version valueForAttribute:@"first"], @"Herp",
    @"version: first");
  GHAssertEqualStrings([person.version valueForAttribute:@"last"], @"Derp",
    @"version: last");
  GHAssertEqualStrings([person.version valueForAttribute:@"phone"],
    @"1235674444", @"version: phone");

  GHAssertEqualStrings([[person class] dstype], person.version.type,
    @"version type");

  person.first = @"Herpington";

  oldHash = person.version.hashstr;
  [person commit];
  GHAssertEqualStrings(person.version.parent, oldHash, @"parent hash");
  GHAssertNotEqualStrings(person.version.hashstr, oldHash, @"parent hash");
  GHAssertFalse(person.version.isBlank, @"must not have blank version");
  GHAssertTrue(person.isCommitted, @"must be committed");


  GHAssertEqualStrings([person.version valueForAttribute:@"first"],
    @"Herpington", @"version: first");
  GHAssertEqualStrings([person.version valueForAttribute:@"last"], @"Derp",
    @"version: last");
  GHAssertEqualStrings([person.version valueForAttribute:@"phone"],
    @"1235674444", @"version: phone");


  GHAssertTrue([[person.version valueForAttribute:@"age"] intValue] == 5,
    @"version: age");

  GHAssertTrue(fabs([[person.version valueForAttribute:@"awesome"] floatValue] -
    0.1) < 0.00000001,  @"version: age");

}


@end
