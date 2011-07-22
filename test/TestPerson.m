
#import "TestPerson.h"
#import "DSAttribute.h"
#import "DSMerge.h"
#import "DSCollection.h"

static DSCollection *allPeople = nil;


@implementation TestCompany
@synthesize name, url, employees;

+ (id) objectWithSerializedValue:(NSDictionary *)dict {
  TestCompany *company = [[[TestCompany alloc] init] autorelease];
  company.name = [dict valueForKey:@"name"];
  company.url = [dict valueForKey:@"url"];
  company.employees = [[dict valueForKey:@"employees"] intValue];
  return company;
}

- (NSObject *) serializedValue {
  return [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", url, @"url",
    [NSNumber numberWithInt:employees], @"employees", nil];
}

- (BOOL) isEqualToCompany:(TestCompany *)other {
  return [name isEqualToString:other.name]
      && [url isEqualToString:other.url]
      && employees == other.employees;
}

- (BOOL) isEqual:(NSObject *)other {
  if ([other isKindOfClass:[TestCompany class]])
    return [self isEqualToCompany:(TestCompany *)other];
  return [super isEqual:other];
}

- (NSUInteger) hash {
  return [name hash] + [url hash] + employees;
}

- (id) copyWithZone:(NSZone *)zone {
  TestCompany *copy = [[[self class] allocWithZone:zone] init];
  copy.name = self.name;
  copy.url = self.url;
  copy.employees = self.employees;
  return copy;
}

@end





@implementation TestPerson
@synthesize first, last, phone, awesomesauce, age, father, mother;
@synthesize children, titles, titles2, computers, computers2;
@synthesize company, previousCompanies, clientCompanies;

- (id) initWithVersion:(DSVersion *)_version {
  if ((self = [super initWithVersion:_version])) {
    [[[self class] allPeople] addModel:self];
  }
  return self;
}

+ (void) registerAttributes {

  [super registerAttributes];

  DSRegisterAttribute(first, NSString, @"", DSLatestMergeStrategy);
  DSRegisterAttribute(last, NSString, @"", DSLatestMergeStrategy);
  DSRegisterAttribute(phone, NSString, @"0", DSLatestMergeStrategy);

  DSRegisterPrimitiveAttribute(age, int, 1, DSMaxMergeStrategy);
  DSRegisterPrimitiveAttribute(awesome, float, 0.1,DSLatestObjectMergeStrategy);

  DSRegisterModelAttribute(father, TestPerson, DSLatestMergeStrategy);
  DSRegisterModelAttribute(mother, TestPerson, DSLatestMergeStrategy);

  DSRegisterCollectionAttribute(children, TestPerson, DSLatestMergeStrategy);

  DSRegisterAttribute(titles, NSMutableArray, [NSMutableArray array],
    DSLatestMergeStrategy);
  DSRegisterAttribute(computers, NSMutableDictionary,
    [NSMutableDictionary dictionary], DSLatestMergeStrategy);

  DSRegisterArrayAttribute(titles2, NSString, DSLatestMergeStrategy);
  DSRegisterDictionaryAttribute(computers2, NSString, DSLatestMergeStrategy);


  DSRegisterAttribute(company, TestCompany, nil, DSLatestMergeStrategy);
  DSRegisterArrayAttribute(previousCompanies, TestCompany,
    DSLatestMergeStrategy);
  DSRegisterDictionaryAttribute(clientCompanies, TestCompany,
    DSLatestMergeStrategy);

  [self rebindAttribute:@"awesome" toProperty:@"awesomesauce"];
}

+ (NSString *) dstype {
  return @"Person";
}

+ (DSCollection *) allPeople {
  if (!allPeople)
    allPeople = [[DSCollection alloc] init];
  return allPeople;
}

- (id<DSModelContainer>) modelContainerForAttribute:(DSModelAttribute *)attr {
  return [[self class] allPeople];
}


@end