
#import "DSKey.h"
#import "DSVersion.h"
#import "DSModel.h"
#import "DSAttribute.h"
#import "DSMerge.h"

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
  GHAssertTrue(fabs(person.awesomesauce - 0.1) < 0.000001, @"blank awesone");

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
  NSLog(@"float awesome: %f %f", [[person.version valueForAttribute:@"awesome"]
    floatValue], person.awesomesauce);
  GHAssertTrue(fabs([[person.version valueForAttribute:@"awesome"]
    floatValue] - person.awesomesauce) < 0.000001, @"version: awesome");

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
      GHAssertFalse([[p1.version valueForAttribute:attr.name] isEqual:
        [p2.version valueForAttribute:attr.name]], @"val");
      GHAssertFalse([[attr valueForInstance:p1] isEqual:
        [attr valueForInstance:p2]], @"val");
      GHAssertFalse([[p1.version valueForAttribute:attr.name] isEqual:
        [p2.version valueForAttribute:attr.name]], @"val");
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


- (void) __subtestPerson:(TestPerson *)person first:(NSString *)first
  last:(NSString *)last phone:(NSString *)phone {

  NSLog(@"should be: %@ %@ %@", first, last, phone);
  NSLog(@"currently: %@ %@ %@", person.first, person.last, person.phone);

  GHAssertEqualStrings(person.first, first, @"first name");
  GHAssertEqualStrings(person.last,  last,  @"last name");
  GHAssertEqualStrings(person.phone, phone, @"phone no");
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
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];


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

  p2.awesomesauce = (float)60.0;
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
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];


}


- (void) test_merge_latest_object {
  TestPerson *p1 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p2 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p3 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p4 = [[TestPerson alloc] initWithKeyName:@"A"];

  [self __subtestBlankPerson:p1];
  [self __subtestBlankPerson:p2];
  [self __subtestBlankPerson:p3];
  [self __subtestBlankPerson:p4];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:nil];

  p1.awesomesauce = (float)0.1;
  p2.awesomesauce = (float)0.2;
  p3.awesomesauce = (float)0.3;
  p4.awesomesauce = (float)0.4;

  [p1 commit];
  [p2 commit];
  [p3 commit];
  [p4 commit];


  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:
    [NSArray arrayWithObjects:@"awesome", nil]];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:
    [NSArray arrayWithObjects:@"awesome", nil]];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"awesome", nil]];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"awesome", nil]];


  NSLog(@"p3 merge p4");
  [p3 mergeVersion:p4.version]; // 3 gets 4s  0.4
  NSLog(@"p4 merge p3");
  [p4 mergeVersion:p3.version]; // 4 stays w  0.4
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:nil];
  GHAssertTrue(fabs(p3.awesomesauce - 0.4) < 0.000001,
    @"value is %f", p3.awesomesauce);
  GHAssertTrue(fabs(p4.awesomesauce - 0.4) < 0.000001,
    @"value is %f", p4.awesomesauce);

  NSLog(@"p1 merge p2");
  [p1 mergeVersion:p2.version]; // 1 gets 2s  0.2
  NSLog(@"p2 merge p1");
  [p2 mergeVersion:p1.version]; // 2 stays w  0.2
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];
  GHAssertTrue(fabs(p2.awesomesauce - 0.2) < 0.000001,
    @"value is %f", p2.awesomesauce);
  GHAssertTrue(fabs(p1.awesomesauce - 0.2) < 0.000001,
    @"value is %f", p1.awesomesauce);

  NSLog(@"p1 merge p3");
  [p1 mergeVersion:p3.version]; // 1 stays w  0.2
  NSLog(@"p3 merge p1");
  [p3 mergeVersion:p1.version]; // 3 gets 1s  0.2
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:nil];
  GHAssertTrue(fabs(p3.awesomesauce - 0.2) < 0.000001,
    @"value is %f", p3.awesomesauce);
  GHAssertTrue(fabs(p1.awesomesauce - 0.2) < 0.000001,
    @"value is %f", p1.awesomesauce);

  NSLog(@"p3 merge p4");
  [p3 mergeVersion:p4.version]; // 3 stays w  0.2
  NSLog(@"p4 merge p3");
  [p4 mergeVersion:p3.version]; // 4 gets 3s  0.2
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:nil];
  GHAssertTrue(fabs(p3.awesomesauce - 0.2) < 0.000001,
    @"value is %f", p3.awesomesauce);
  GHAssertTrue(fabs(p4.awesomesauce - 0.2) < 0.000001,
    @"value is %f", p4.awesomesauce);

  [p1 release];
  [p2 release];
  [p3 release];
  [p4 release];
}

- (void) test_merge_latest {

  TestPerson *p1 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p2 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p3 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p4 = [[TestPerson alloc] initWithKeyName:@"A"];

  [self __subtestBlankPerson:p1];
  [self __subtestBlankPerson:p2];
  [self __subtestBlankPerson:p3];
  [self __subtestBlankPerson:p4];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:nil];

  p1.first = @"first1";
  p2.first = @"first2";
  p3.first = @"first3";
  p4.first = @"first4";

  [p1 commit];
  [p2 commit];
  [p3 commit];
  [p4 commit];

  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:
    [NSArray arrayWithObjects:@"first", nil]];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:
    [NSArray arrayWithObjects:@"first", nil]];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"first", nil]];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"first", nil]];

  p4.last = @"last4";
  p3.last = @"last3";
  p2.last = @"last2";
  p1.last = @"last1";

  [p4 commit];
  [p3 commit];
  [p2 commit];
  [p1 commit];

  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", nil]];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", nil]];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", nil]];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", nil]];

  p1.phone = @"phone1";
  p4.phone = @"phone4";
  p3.phone = @"phone3";
  p2.phone = @"phone2";

  [p1 commit];
  [p4 commit];
  [p3 commit];
  [p2 commit];

  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", @"phone", nil]];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", @"phone", nil]];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", @"phone", nil]];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:
    [NSArray arrayWithObjects:@"first", @"last", @"phone", nil]];


  [self __subtestPerson:p1 first:@"first1" last:@"last1" phone:@"phone1"];
  [self __subtestPerson:p2 first:@"first2" last:@"last2" phone:@"phone2"];
  [self __subtestPerson:p3 first:@"first3" last:@"last3" phone:@"phone3"];
  [self __subtestPerson:p4 first:@"first4" last:@"last4" phone:@"phone4"];

  NSLog(@"p3 merge p4");
  [p3 mergeVersion:p4.version];
  [self __subtestPerson:p3 first:@"first4" last:@"last3" phone:@"phone3"];

  NSLog(@"p4 merge p3");
  [p4 mergeVersion:p3.version];
  [self __subtestPerson:p3 first:@"first4" last:@"last3" phone:@"phone3"];

  NSLog(@"p1 merge p2");
  [p1 mergeVersion:p2.version];
  [self __subtestPerson:p1 first:@"first2" last:@"last1" phone:@"phone2"];

  NSLog(@"p2 merge p1");
  [p2 mergeVersion:p1.version];
  [self __subtestPerson:p2 first:@"first2" last:@"last1" phone:@"phone2"];

  NSLog(@"p1 merge p3");
  [p1 mergeVersion:p3.version];
  [self __subtestPerson:p1 first:@"first4" last:@"last1" phone:@"phone2"];

  NSLog(@"p3 merge p1");
  [p3 mergeVersion:p1.version];
  [self __subtestPerson:p3 first:@"first4" last:@"last1" phone:@"phone2"];

  NSLog(@"p4 merge p3");
  [p4 mergeVersion:p3.version];
  [self __subtestPerson:p4 first:@"first4" last:@"last1" phone:@"phone2"];

  NSLog(@"p3 merge p4");
  [p3 mergeVersion:p4.version];
  [self __subtestPerson:p3 first:@"first4" last:@"last1" phone:@"phone2"];


  [p1 mergeVersion:p4.version];
  [p2 mergeVersion:p4.version];
  [p3 mergeVersion:p4.version];

  [self __subtestPerson:p1 first:@"first4" last:@"last1" phone:@"phone2"];
  [self __subtestPerson:p2 first:@"first4" last:@"last1" phone:@"phone2"];
  [self __subtestPerson:p3 first:@"first4" last:@"last1" phone:@"phone2"];
  [self __subtestPerson:p4 first:@"first4" last:@"last1" phone:@"phone2"];

  GHAssertEqualStrings(p1.version.hashstr, p2.version.hashstr, @"hash 1-2");
  GHAssertEqualStrings(p1.version.hashstr, p3.version.hashstr, @"hash 1-3");
  GHAssertEqualStrings(p1.version.hashstr, p4.version.hashstr, @"hash 1-4");

  [p1 release];
  [p2 release];
  [p3 release];
  [p4 release];

}

- (void) test_max {
  TestPerson *p1 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p2 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p3 = [[TestPerson alloc] initWithKeyName:@"A"];
  TestPerson *p4 = [[TestPerson alloc] initWithKeyName:@"A"];
  NSArray *ageArray = [NSArray arrayWithObjects:@"age", nil];

  [self __subtestBlankPerson:p1];
  [self __subtestBlankPerson:p2];
  [self __subtestBlankPerson:p3];
  [self __subtestBlankPerson:p4];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:nil];

  p1.age = 11;
  p2.age = 22;
  p3.age = 33;
  p4.age = 44;

  [p1 commit];
  [p2 commit];
  [p3 commit];
  [p4 commit];


  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:ageArray];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:ageArray];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:ageArray];
  [self __subtestPerson:p2 otherPerson:p3 diffAttrs:ageArray];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:ageArray];


  NSLog(@"p1 merge p2");
  [p1 mergeVersion:p2.version];
  NSLog(@"p2 merge p1");
  [p2 mergeVersion:p1.version];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:ageArray];
  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:ageArray];
  GHAssertTrue(p1.age == 22, @"value is %d", p1.age);
  GHAssertTrue(p2.age == 22, @"value is %d", p2.age);

  NSLog(@"p1 merge p3");
  [p1 mergeVersion:p3.version];
  NSLog(@"p3 merge p1");
  [p3 mergeVersion:p1.version];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:ageArray];
  [self __subtestPerson:p4 otherPerson:p3 diffAttrs:ageArray];
  GHAssertTrue(p1.age == 33, @"value is %d", p1.age);
  GHAssertTrue(p3.age == 33, @"value is %d", p3.age);

  NSLog(@"p4 merge p3");
  [p4 mergeVersion:p3.version];
  NSLog(@"p3 merge p4");
  [p3 mergeVersion:p4.version];
  [self __subtestPerson:p4 otherPerson:p3 diffAttrs:nil];
  [self __subtestPerson:p1 otherPerson:p3 diffAttrs:ageArray];
  [self __subtestPerson:p2 otherPerson:p4 diffAttrs:ageArray];
  GHAssertTrue(p3.age == 44, @"value is %d", p3.age);
  GHAssertTrue(p4.age == 44, @"value is %d", p4.age);

  NSLog(@"p1 merge p4");
  [p1 mergeVersion:p4.version];
  NSLog(@"p2 merge p4");
  [p2 mergeVersion:p4.version];
  NSLog(@"p3 merge p4");
  [p3 mergeVersion:p3.version];

  [self __subtestPerson:p1 otherPerson:p4 diffAttrs:nil];
  [self __subtestPerson:p2 otherPerson:p4 diffAttrs:nil];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:nil];
  GHAssertTrue(p1.age == 44, @"value is %d", p1.age);
  GHAssertTrue(p2.age == 44, @"value is %d", p2.age);
  GHAssertTrue(p3.age == 44, @"value is %d", p3.age);
  GHAssertTrue(p4.age == 44, @"value is %d", p4.age);


  NSLog(@"p4 merge p2");
  [p4 mergeVersion:p2.version];
  NSLog(@"p4 merge p1");
  [p4 mergeVersion:p1.version];
  NSLog(@"p4 merge p3");
  [p4 mergeVersion:p3.version];

  [self __subtestPerson:p1 otherPerson:p2 diffAttrs:nil];
  [self __subtestPerson:p2 otherPerson:p3 diffAttrs:nil];
  [self __subtestPerson:p3 otherPerson:p4 diffAttrs:nil];
  GHAssertTrue(p1.age == 44, @"value is %d", p1.age);
  GHAssertTrue(p2.age == 44, @"value is %d", p2.age);
  GHAssertTrue(p3.age == 44, @"value is %d", p3.age);
  GHAssertTrue(p4.age == 44, @"value is %d", p4.age);

  [p1 release];
  [p2 release];
  [p3 release];
  [p4 release];
}

@end
