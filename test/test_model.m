
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


  [person.titles2 addObject:@"Hurr"];
  [person.titles2 addObject:@"Durr"];

  [person.computers2 setValue:@"MBP" forKey:@"Ithil"];
  [person.computers2 setValue:@"MBP" forKey:@"Osgiliath"];
  [person.computers2 setValue:@"iPhone 4" forKey:@"Witchking"];
  [person.computers2 setValue:@"iPad 2" forKey:@"Imladris"];

  oldHash = person.version.hashstr;
  [person commit];



  TestCompany *company1 = [[[TestCompany alloc] init] autorelease];
  company1.name = @"TrollCo";
  company1.url = @"www.trolldom.com";
  company1.employees = 9001;

  TestCompany *company2 = [[[TestCompany alloc] init] autorelease];
  company2.name = @"HappyCo";
  company2.url = @"www.happyco.com";
  company2.employees = -50;

  TestCompany *company3 = [[[TestCompany alloc] init] autorelease];
  company3.name = @"PhysCo";
  company3.url = @"www.physco.com";
  company3.employees = 413290;


  person.company = company1;
  [person.previousCompanies addObject:company2];
  [person.clientCompanies setValue:company2 forKey:@"Happs"];

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

  GHAssertTrue([person.titles2 count] == 2,  @"titles");
  GHAssertTrue([person.titles2 containsObject:@"Hurr"], @"titles");
  GHAssertTrue([person.titles2 containsObject:@"Durr"], @"titles");

  GHAssertTrue([person.computers count] == 4, @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Ithil"], @"MBP",
    @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Osgiliath"], @"MBP",
    @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Witchking"], @"iPhone 4",
    @"computers");
  GHAssertEqualStrings([person.computers valueForKey:@"Imladris"], @"iPad 2",
    @"computers");

  GHAssertTrue([person.computers2 count] == 4, @"computers");
  GHAssertEqualStrings([person.computers2 valueForKey:@"Ithil"], @"MBP",
    @"computers");
  GHAssertEqualStrings([person.computers2 valueForKey:@"Osgiliath"], @"MBP",
    @"computers");
  GHAssertEqualStrings([person.computers2 valueForKey:@"Witchking"],
    @"iPhone 4", @"computers");
  GHAssertEqualStrings([person.computers2 valueForKey:@"Imladris"],
    @"iPad 2", @"computers");


  GHAssertEqualObjects(person.company, company1,  @"company");
  GHAssertTrue([person.previousCompanies containsObject:company2], @"prevcos");
  GHAssertNotNil([person.clientCompanies valueForKey:@"Happs"], @"prevcos");



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

  GHAssertTrue(([[[[person class] attributeNamed:@"titles2"]
    valueForInstance:person] isEqualToArray:
   [NSArray arrayWithObjects:@"Hurr", @"Durr", nil]]), @"attr: titles2");

  GHAssertTrue(([[[[person class] attributeNamed:@"computers2"]
    valueForInstance:person] isEqualToDictionary:
    [NSDictionary dictionaryWithObjectsAndKeys:@"MBP", @"Ithil", @"MBP",
    @"Osgiliath", @"iPhone 4", @"Witchking", @"iPad 2", @"Imladris", nil]]),
    @"attr: computers2");


  GHAssertEqualObjects([[[person class] attributeNamed:@"company"]
    valueForInstance:person], [company1 serializedValue],
    @"attr: company");

  GHAssertTrue(([[[[person class] attributeNamed:@"previousCompanies"]
    valueForInstance:person] isEqualToArray:
   [NSArray arrayWithObjects:[company2 serializedValue], nil]]),
     @"attr: previousCompanies");

   GHAssertTrue(([[[[person class] attributeNamed:@"clientCompanies"]
     valueForInstance:person] isEqualToDictionary:
     [NSDictionary dictionaryWithObjectsAndKeys:[company2 serializedValue],
     @"Happs", nil]]), @"attr: clientCompanies");




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

  GHAssertTrue(([[person.version valueForAttribute:@"titles2"] isEqualToArray:
    [NSArray arrayWithObjects:@"Hurr", @"Durr", nil]]), @"attr: titles2");

  GHAssertTrue(([[person.version valueForAttribute:@"computers2"]
    isEqualToDictionary: [NSDictionary dictionaryWithObjectsAndKeys:@"MBP",
    @"Ithil", @"MBP", @"Osgiliath", @"iPhone 4", @"Witchking", @"iPad 2",
    @"Imladris", nil]]), @"attr: computers2");



  GHAssertEqualObjects([person.version valueForAttribute:@"company"],
    [company1 serializedValue], @"attr: company");

  GHAssertTrue(([[person.version valueForAttribute:@"previousCompanies"]
    isEqualToArray:[NSArray arrayWithObjects:[company2 serializedValue], nil]]),
     @"attr: previousCompanies");

   GHAssertTrue(([[person.version valueForAttribute:@"clientCompanies"]
     isEqualToDictionary: [NSDictionary dictionaryWithObjectsAndKeys:
    [company2 serializedValue], @"Happs", nil]]), @"attr: clientCompanies");



  GHAssertEqualStrings([[person class] dstype], person.version.type,
    @"version type");


  person.first = @"Herpington";
  [person.titles addObject:@"Murr"];
  [person.computers setValue:@"Tower" forKey:@"Barad Dur"];
  [person.titles2 addObject:@"Murr"];
  [person.computers2 setValue:@"Tower" forKey:@"Barad Dur"];

  person.company = company3;
  [person.previousCompanies addObject:company1];
  [person.clientCompanies setValue:company1 forKey:@"BosTroll"];

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

  GHAssertTrue(([[person.version valueForAttribute:@"titles2"] isEqualToArray:
   [NSArray arrayWithObjects:@"Hurr", @"Durr", @"Murr", nil]]),
    @"attr: titles2");

  GHAssertTrue(([[person.version valueForAttribute:@"computers2"]
    isEqualToDictionary: [NSDictionary dictionaryWithObjectsAndKeys:@"MBP",
    @"Ithil", @"MBP", @"Osgiliath", @"iPhone 4", @"Witchking", @"iPad 2",
    @"Imladris", @"Tower", @"Barad Dur", nil]]), @"attr: computers2");



  GHAssertEqualObjects([person.version valueForAttribute:@"company"],
    [company3 serializedValue], @"attr: company");

  GHAssertTrue(([[person.version valueForAttribute:@"previousCompanies"]
    isEqualToArray:[NSArray arrayWithObjects:[company2 serializedValue],
    [company1 serializedValue], nil]]), @"attr: previousCompanies");

   GHAssertTrue(([[person.version valueForAttribute:@"clientCompanies"]
     isEqualToDictionary: [NSDictionary dictionaryWithObjectsAndKeys:
    [company2 serializedValue], @"Happs", [company1 serializedValue],
    @"BosTroll", nil]]), @"attr: clientCompanies");




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
