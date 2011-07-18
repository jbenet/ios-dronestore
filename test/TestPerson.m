
#import "TestPerson.h"
#import "DSAttribute.h"
#import "DSMerge.h"
#import "DSCollection.h"

static DSCollection *allPeople = nil;

@implementation TestPerson
@synthesize first, last, phone, awesomesauce, age, father, mother;

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