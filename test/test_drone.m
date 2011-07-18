
#import "DSKey.h"
#import "DSDrone.h"
#import "DSVersion.h"
#import "DSAttribute.h"
#import "DSDatastore.h"
#import "TestPerson.h"
#import "DSFMDBDatastore.h"
#import "DSQuery.h"
#import "DSCollection.h"

#import "NSString+SHA.h"

@interface DroneTest : GHTestCase {
}
@end

@implementation DroneTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}


- (void) test_basic {

  DSDatastore *ds = [[DSDictionaryDatastore alloc] init];
  DSDrone *drone = [[DSDrone alloc] initWithId:DSKey(@"/DroneA/")
    andDatastore:ds];
  [ds release];


  TestPerson *person = [[TestPerson alloc] initWithKeyName:@"A"];
  person.first = @"A";
  person.last = @"B";
  [person commit];

  TestPerson *father = [[TestPerson alloc] initWithKeyName:@"Father"];
  person.father = father;
  [person commit];

  GHAssertFalse([drone contains:person.key], @"Should not contain it");
  GHAssertNil([drone get:person.key], @"Should not contain it");

  [drone put:person];

  GHAssertTrue([drone contains:person.key], @"should contain it");
  GHAssertTrue([[drone get:person.key] isEqualToModel:person], @"should eq.");

  for (int i = 0; i < 100; i++) {
    [drone delete:person.key];

    GHAssertFalse([drone contains:person.key], @"Should not contain it");
    GHAssertNil([drone get:person.key], @"Should not contain it");

    [drone put:person];

    GHAssertTrue([drone contains:person.key], @"should contain it");
    GHAssertTrue([[drone get:person.key] isEqualToModel:person], @"should eq.");
  }

  TestPerson *person2 = [[TestPerson alloc] initWithVersion:person.version];
  GHAssertTrue([drone contains:person2.key], @"should contain it");
  GHAssertTrue([person isEqualToModel:person2], @"should eq.");
  GHAssertTrue([[drone get:person2.key] isEqualToModel:person2], @"should eq.");

  person2.first = @"C";

  TestPerson *mother = [[TestPerson alloc] initWithKeyName:@"Mother"];
  person2.mother = mother;
  [person2 commit];

  GHAssertTrue([drone contains:person2.key], @"should contain it");
  GHAssertFalse([person isEqualToModel:person2], @"!eq.");
  GHAssertFalse([[drone get:person2.key] isEqualToModel:person2], @"!eq.");
  GHAssertNotEqualStrings(person2.first, person.first, @"should not eq.");
  GHAssertTrue(person2.father == person.father, @"should not eq.");
  GHAssertFalse(person2.mother == person.mother, @"should not eq.");

  person2 = [drone merge:person2];

  GHAssertTrue([drone contains:person2.key], @"should contain it");
  GHAssertFalse([person isEqualToModel:person2], @"!eq.");
  GHAssertTrue([[drone get:person2.key] isEqualToModel:person2], @"should eq.");

  GHAssertTrue([[(TestPerson *)[drone get:person2.key] father]
    isEqualToModel:father], @"eq.");
  GHAssertTrue([[(TestPerson *)[drone get:person2.key] mother]
    isEqualToModel:mother], @"eq.");


  DSQuery *query = [[DSQuery alloc] initWithModel:[TestPerson class]];
  DSCollection *result = [drone query:query];
  GHAssertTrue([result count] == 1, @"query count");
  GHAssertTrue([person2 isEqualToModel:[result modelAtIndex:0]],
    @"should eq.");
  GHAssertTrue([person2 isEqualToModel:[result modelForKey:person2.key]],
    @"should eq.");

  [query release];

  [drone release];
}


- (void) updateAttr:(DSAttribute *)attr drones:(NSArray *)drones
  people:(int)people iteration:(int)iteration {
  DSDrone *d = [drones objectAtIndex:rand() % 5];
  NSString *str = [NSString stringWithFormat:@"%d", (rand() % people)];
  DSKey *key = [TestPerson keyWithName:str];

  TestPerson *p = [d get:key];
  if (p == nil)
    return; //

  if ([attr.name isEqualToString:@"age"]) {
    p.age += 1;
  } else if ([attr.name isEqualToString:@"awesome"]) {
    p.awesomesauce += 0.00001;
  } else if ([attr isKindOfClass:[DSModelAttribute class]]) {
    NSString *str2 = [NSString stringWithFormat:@"%d", (rand() % people)];
    DSKey *key2 = [TestPerson keyWithName:str2];
    TestPerson *op = [d get:key2];
    [attr setValue:op.key.string forInstance:p];
  } else {
    NSString *oldVal = [attr valueForInstance:p];
    NSString *newVal = [NSString stringWithFormat:@"%@%d", oldVal, iteration];
    [attr setValue:newVal forInstance:p];
  }
  [p commit];
  [d merge:p];
}

- (void) shuffleRandomPersonInDrones:(NSArray *)drones people:(int)people {

  int d1, d2;
  d1 = rand() % 5;
  do {
    d2 = rand() % 5;
  } while (d1 == d2);

  DSDrone *drone1 = [drones objectAtIndex:d1];
  DSDrone *drone2 = [drones objectAtIndex:d2];

  NSString *str = [NSString stringWithFormat:@"%d", (rand() % people)];
  DSKey *key = [TestPerson keyWithName:str];

  TestPerson *p = [drone1 get:key];
  if (p == nil)
    return; //

  [drone2 merge:p];
}

- (void) test_stress {

  srand((unsigned int)time(NULL)); // make sure rand is seeded.

  int numPeople = 10;

  // DSDrone *d1 = [[DSDrone alloc] initWithId:DSKey(@"/Drone1/")
  //   andDatastore:[[[DSDictionaryDatastore alloc] init] autorelease]];
  // DSDrone *d2 = [[DSDrone alloc] initWithId:DSKey(@"/Drone2/")
  //   andDatastore:[[[DSDictionaryDatastore alloc] init] autorelease]];
  // DSDrone *d3 = [[DSDrone alloc] initWithId:DSKey(@"/Drone3/")
  //   andDatastore:[[[DSDictionaryDatastore alloc] init] autorelease]];
  // DSDrone *d4 = [[DSDrone alloc] initWithId:DSKey(@"/Drone4/")
  //   andDatastore:[[[DSDictionaryDatastore alloc] init] autorelease]];
  // DSDrone *d5 = [[DSDrone alloc] initWithId:DSKey(@"/Drone5/")
  //   andDatastore:[[[DSDictionaryDatastore alloc] init] autorelease]];

  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_1"];
  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_2"];
  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_3"];
  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_4"];
  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_5"];

  SQLSchema *s1 = [SQLSchema versionTableNamed:@"test_db_1"];
  SQLSchema *s2 = [SQLSchema versionTableNamed:@"test_db_2"];
  SQLSchema *s3 = [SQLSchema versionTableNamed:@"test_db_3"];
  SQLSchema *s4 = [SQLSchema versionTableNamed:@"test_db_4"];
  SQLSchema *s5 = [SQLSchema versionTableNamed:@"test_db_5"];

  DSFMDBDatastore *f1 = [[DSFMDBDatastore alloc] initWithSchema:s1];
  DSFMDBDatastore *f2 = [[DSFMDBDatastore alloc] initWithSchema:s2];
  DSFMDBDatastore *f3 = [[DSFMDBDatastore alloc] initWithSchema:s3];
  DSFMDBDatastore *f4 = [[DSFMDBDatastore alloc] initWithSchema:s4];
  DSFMDBDatastore *f5 = [[DSFMDBDatastore alloc] initWithSchema:s5];


  DSDrone *d1 = [[DSDrone alloc] initWithId:DSKey(@"/Drone1/") andDatastore:f1];
  DSDrone *d2 = [[DSDrone alloc] initWithId:DSKey(@"/Drone2/") andDatastore:f2];
  DSDrone *d3 = [[DSDrone alloc] initWithId:DSKey(@"/Drone3/") andDatastore:f3];
  DSDrone *d4 = [[DSDrone alloc] initWithId:DSKey(@"/Drone4/") andDatastore:f4];
  DSDrone *d5 = [[DSDrone alloc] initWithId:DSKey(@"/Drone5/") andDatastore:f5];

  NSArray *drones = [NSArray arrayWithObjects:d1, d2, d3, d4, d5, nil];

  for (int i = 0; i < numPeople; i++) {
    NSString *str = [NSString stringWithFormat:@"%d", i];
    TestPerson *p = [[TestPerson alloc] initWithKeyName:str];
    p.first = [NSString stringWithFormat:@"first%d", i];
    p.last = [NSString stringWithFormat:@"last%d", i];
    p.phone = [NSString stringWithFormat:@"phone%d", i];
    p.age = 0;
    p.awesomesauce = i / numPeople;
    [p commit];

    DSDrone *d = [drones objectAtIndex:rand() % 5];
    [d put:p];
    NSLog(@"Added person %@", p);
  }


  for (int i = 0; i < numPeople * 10; i++) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    for (DSAttribute *attr in [[TestPerson attributes] allValues])
      [self updateAttr:attr drones:drones people:numPeople iteration:i];

    [self shuffleRandomPersonInDrones:drones people:numPeople];
    [self shuffleRandomPersonInDrones:drones people:numPeople];
    [self shuffleRandomPersonInDrones:drones people:numPeople];
    [self shuffleRandomPersonInDrones:drones people:numPeople];
    [self shuffleRandomPersonInDrones:drones people:numPeople];

    [pool drain];
  }

  for (DSDrone *drone in drones) {
    NSLog(@"Drone Contents: %@", drone);
    for (int i = 0; i < numPeople; i++) {
      DSKey *k = [TestPerson keyWithName:[NSString stringWithFormat:@"%d", i]];
      TestPerson *p = [drone get:k];
      NSLog(@"person %d: %@", i, (p == nil ? @"not found" : [p description]));
    }
  }

  for (int i = 0; i < numPeople; i++) {
    DSKey *k = [TestPerson keyWithName:[NSString stringWithFormat:@"%d", i]];
    TestPerson *p = [[drones objectAtIndex:0] get:k];
    for (DSDrone *drone in drones)
      p = [drone merge:p];

    for (DSDrone *drone in drones) {
      p = [drone merge:p];

      TestPerson *o = [drone get:p.key];
      GHAssertTrue([p isEqualToModel:o], @"equal");
      GHAssertEqualStrings(p.first, o.first, @"first");
      GHAssertEqualStrings(p.last, o.last, @"last");
      GHAssertEqualStrings(p.phone, o.phone, @"phone");
      GHAssertTrue(p.age == o.age, @"age");
      GHAssertTrue(fabs(p.awesomesauce - o.awesomesauce) < 0.00001, @"awesome");

      GHAssertTrue([p.version isEqualToVersion:o.version], @"version");

    }
  }

  DSQuery *query = [[DSQuery alloc] initWithModel:[TestPerson class]];
  for (DSDrone *drone in drones) {
    DSCollection *result = [drone query:query];
    GHAssertTrue([result count] == numPeople, @"query count");

    for (int i = 0; i < numPeople; i++) {
      DSKey *k = [TestPerson keyWithName:[NSString stringWithFormat:@"%d", i]];
      TestPerson *p = [[drones objectAtIndex:0] get:k];

      TestPerson *o = [result modelForKey:p.key];

      GHAssertTrue([p isEqualToModel:o], @"equal");
      GHAssertEqualStrings(p.first, o.first, @"first");
      GHAssertEqualStrings(p.last, o.last, @"last");
      GHAssertEqualStrings(p.phone, o.phone, @"phone");
      GHAssertTrue(p.age == o.age, @"age");
      GHAssertTrue(fabs(p.awesomesauce - o.awesomesauce) < 0.00001, @"awesome");

      GHAssertTrue([p.version isEqualToVersion:o.version], @"version");

    }
  }
  [query release];


  [d1 release];
  [d2 release];
  [d3 release];
  [d4 release];
  [d5 release];
}




@end
