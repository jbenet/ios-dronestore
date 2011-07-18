
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
  GHAssertNil(person.father, @"father");
  GHAssertNil(person.mother, @"mother");

  GHAssertTrue([person.children count] == 0, @"children");
  GHAssertTrue([person.titles count] == 0,  @"titles");
  GHAssertTrue([person.computers count] == 0, @"computers");

  // dumb float point math.
  GHAssertTrue(fabs(person.awesomesauce - 0.1) < 0.00000001, @"awesome");
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
  GHAssertTrue(fabs(person.awesomesauce - 0.1) < 0.00000001, @"awesome");


  TestPerson *father = [[TestPerson alloc] initWithKeyName:@"DadDerp"];
  TestPerson *mother = [[TestPerson alloc] initWithKeyName:@"MomDerp"];

  person.first = @"Herp";
  person.last = @"Derp";
  person.phone = @"1235674444";
  person.age = 5;
  person.father = father;
  person.mother = mother;

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

  GHAssertTrue([person.children count] == 0, @"children");
  GHAssertTrue([person.titles count] == 0,  @"titles");
  GHAssertTrue([person.computers count] == 0, @"computers");


  TestPerson *son1 = [[TestPerson alloc] initWithKeyName:@"Son1Derp"];
  TestPerson *son2 = [[TestPerson alloc] initWithKeyName:@"Son2Derp"];
  TestPerson *son3 = [[TestPerson alloc] initWithKeyName:@"Son3Derp"];

  [person.children addModel:son1];
  [person.children addModel:son2];
  [person.children addModel:son3];

  [person.titles addObject:@"Hurr"];
  [person.titles addObject:@"Durr"];

  [person.computers setValue:@"MBP" forKey:@"Ithil"];
  [person.computers setValue:@"MBP" forKey:@"Osgiliath"];
  [person.computers setValue:@"iPhone 4" forKey:@"Witchking"];
  [person.computers setValue:@"iPad 2" forKey:@"Imladris"];

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

  GHAssertTrue([person.children count] == 3, @"children");
  GHAssertNotNil([person.children modelForKey:son1.key], @"children");
  GHAssertNotNil([person.children modelForKey:son2.key], @"children");
  GHAssertNotNil([person.children modelForKey:son3.key], @"children");

  GHAssertTrue([person.titles count] == 2,  @"titles");
  GHAssertTrue([person.titles containsObject:@"Hurr"], @"titles");
  GHAssertTrue([person.titles containsObject:@"Durr"], @"titles");

  GHAssertTrue([person.computers count] == 4, @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Ithil"], @"MBP",
    @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Osgiliath"], @"MBP",
    @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Witchking"], @"iPhone 4",
    @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Imladris"], @"iPad 2",
    @"computers");


  GHAssertEqualStrings([[[person class] attributeNamed:@"first"]
    valueForInstance:person], @"Herp", @"attr: first");
  GHAssertEqualStrings([[[person class] attributeNamed:@"last"]
    valueForInstance:person], @"Derp", @"attr: last");
  GHAssertEqualStrings([[[person class] attributeNamed:@"phone"]
    valueForInstance:person], @"1235674444", @"attr: phone");

  GHAssertTrue([[[[person class] attributeNamed:@"age"] valueForInstance:person]
    intValue] == 5, @"version: age");

  GHAssertEqualStrings([[[person class] attributeNamed:@"father"]
    valueForInstance:person], father.key.string, @"attr: father");
  GHAssertEqualStrings([[[person class] attributeNamed:@"mother"]
    valueForInstance:person], mother.key.string, @"attr: mother");

  NSMutableArray *childrenkeyarr = [NSMutableArray array];
  for (DSKey *key in person.children)
    [childrenkeyarr addObject:key.string];

  GHAssertTrue([[[[person class] attributeNamed:@"children"]
    valueForInstance:person] isEqualToArray:childrenkeyarr], @"attr: children");

  GHAssertTrue(([[[[person class] attributeNamed:@"titles"]
    valueForInstance:person] isEqualToArray:
   [NSArray arrayWithObjects:@"Hurr", @"Durr", nil]]), @"attr: titles");

  GHAssertTrue(([[[[person class] attributeNamed:@"computers"]
    valueForInstance:person] isEqualToDictionary:
    [NSDictionary dictionaryWithObjectsAndKeys:@"MBP", @"Ithil", @"MBP", 
    @"Osgiliath", @"iPhone 4", @"Witchking", @"iPad 2", @"Imladris", nil]]),
    @"attr: computers");


  // dumb float point math.
  GHAssertTrue(fabs(person.awesomesauce - 0.1) < 0.00000001, @"awesome");

  GHAssertEqualStrings([person.version valueForAttribute:@"first"], @"Herp",
    @"version: first");
  GHAssertEqualStrings([person.version valueForAttribute:@"last"], @"Derp",
    @"version: last");
  GHAssertEqualStrings([person.version valueForAttribute:@"phone"],
    @"1235674444", @"version: phone");

  GHAssertEqualStrings([person.version valueForAttribute:@"father"],
    father.key.string, @"version: phone");
  GHAssertEqualStrings([person.version valueForAttribute:@"mother"],
    mother.key.string, @"version: phone");

  GHAssertTrue([[person.version valueForAttribute:@"children"]
    isEqualToArray:childrenkeyarr], @"attr: children");

  GHAssertTrue(([[person.version valueForAttribute:@"titles"] isEqualToArray:
    [NSArray arrayWithObjects:@"Hurr", @"Durr", nil]]), @"attr: titles");

  GHAssertTrue(([[person.version valueForAttribute:@"computers"]
    isEqualToDictionary: [NSDictionary dictionaryWithObjectsAndKeys:@"MBP",
    @"Ithil", @"MBP", @"Osgiliath", @"iPhone 4", @"Witchking", @"iPad 2",
    @"Imladris", nil]]), @"attr: computers");

  GHAssertEqualStrings([[person class] dstype], person.version.type,
    @"version type");


  person.first = @"Herpington";
  [person.titles addObject:@"Murr"];
  [person.computers setValue:@"Tower" forKey:@"Barad Dur"];

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

  GHAssertEqualStrings([person.version valueForAttribute:@"father"],
    father.key.string, @"version: phone");
  GHAssertEqualStrings([person.version valueForAttribute:@"mother"],
    mother.key.string, @"version: phone");

  GHAssertTrue([[person.version valueForAttribute:@"children"]
    isEqualToArray:childrenkeyarr], @"attr: children");

  GHAssertTrue(([[person.version valueForAttribute:@"titles"] isEqualToArray:
   [NSArray arrayWithObjects:@"Hurr", @"Durr", @"Murr", nil]]), 
    @"attr: titles");

  GHAssertTrue(([[person.version valueForAttribute:@"computers"]
    isEqualToDictionary: [NSDictionary dictionaryWithObjectsAndKeys:@"MBP",
    @"Ithil", @"MBP", @"Osgiliath", @"iPhone 4", @"Witchking", @"iPad 2",
    @"Imladris", @"Tower", @"Barad Dur", nil]]), @"attr: computers");

  GHAssertEqualStrings([[person class] dstype], person.version.type,
    @"version type");

  GHAssertTrue([[person.version valueForAttribute:@"age"] intValue] == 5,
    @"version: age");

  GHAssertTrue(fabs([[person.version valueForAttribute:@"awesome"] floatValue] -
    0.1) < 0.00000001,  @"version: age");

  [father release];
  [mother release];
}


@end
