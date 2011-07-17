
#import "DSKey.h"
#import "DSDrone.h"
#import "DSVersion.h"
#import "DSAttribute.h"
#import "DSDatastore.h"
#import "TestPerson.h"
#import "DSBNDatastore.h"
#import "DSQuery.h"
#import "DSCollection.h"

#import "NSString+SHA.h"



#ifndef WAIT_WHILE
#define WAIT_WHILE(condition) \
  for (int i = 0; (condition) && i < 10000; i++) \
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate \
      dateWithTimeIntervalSinceNow:0.5]];
    // [NSThread sleepForTimeInterval:0.5]; // main thread apparently.
#endif

@interface BNDatastoreTest : GHTestCase {
}
@end

@implementation BNDatastoreTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void) test_basic {

  //
  // To Run this test, run an DataDrone data.py at port 1362 with id testdata
  // ./data.py --lru-cache 1000 -p 1362 -i testdata
  //
  //


  BNNode *node = [[BNNode alloc] initWithName:@"BNDatastoreTest"];
  BNRemoteService *service =
    [[BNRemoteService alloc] initWithName:@"testdata" andNode:node];
  [node.server connectToAddress:@"localhost:1362"];

  WAIT_WHILE(![node linkForName:service.name]);
  GHAssertNotNil([node linkForName:service.name], @"Check the link is there.");

  DSBNDatastore *ds = [[DSBNDatastore alloc] initWithRemoteService:service];

  DSDrone *drone = [[DSDrone alloc] initWithId:DSKey(@"/DroneA/")
    andDatastore:ds];
  [ds release];


  TestPerson *person = [[TestPerson alloc] initWithKeyName:@"A"];
  person.first = @"A";
  person.last = @"B";
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
  [person2 commit];


  GHAssertTrue([drone contains:person2.key], @"should contain it");
  GHAssertFalse([person isEqualToModel:person2], @"!eq.");
  GHAssertFalse([[drone get:person2.key] isEqualToModel:person2], @"!eq.");
  GHAssertNotEqualStrings(person2.first, person.first, @"should not eq.");

  person2 = [drone merge:person2];

  GHAssertTrue([drone contains:person2.key], @"should contain it");
  GHAssertFalse([person isEqualToModel:person2], @"!eq.");
  GHAssertTrue([[drone get:person2.key] isEqualToModel:person2], @"should eq.");


  DSQuery *query = [[DSQuery alloc] initWithModel:[TestPerson class]];
  DSCollection *result = [drone query:query];
  GHAssertTrue([result count] == 1, @"query count");
  GHAssertTrue([person2 isEqualToModel:[result modelAtIndex:0]],
    @"should eq.");
  GHAssertTrue([person2 isEqualToModel:[result modelForKey:person2.key]],
    @"should eq.");

  [query release];

  [drone release];
  [service release];
  [node release];
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
    p.awesome += 0.001;
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


  //
  // To Run this test, run five DataDrone data.py instances with:
  // id testdata1 at port 1371
  // id testdata2 at port 1372
  // id testdata3 at port 1373
  // id testdata4 at port 1374
  // id testdata5 at port 1375
  //
  // or run these:
  // ./data.py --lru-cache 1000 -p 1371 -i testdata1
  // ./data.py --lru-cache 1000 -p 1372 -i testdata2
  // ./data.py --lru-cache 1000 -p 1373 -i testdata3
  // ./data.py --lru-cache 1000 -p 1374 -i testdata4
  // ./data.py --lru-cache 1000 -p 1375 -i testdata5
  //
  // or if you run your own, change values below.
  //

  BNNode *node = [[BNNode alloc] initWithName:@"BNDatastoreTest"];

  BNRemoteService *service1;
  BNRemoteService *service2;
  BNRemoteService *service3;
  BNRemoteService *service4;
  BNRemoteService *service5;
  service1 = [[BNRemoteService alloc] initWithName:@"testdata1" andNode:node];
  service2 = [[BNRemoteService alloc] initWithName:@"testdata2" andNode:node];
  service3 = [[BNRemoteService alloc] initWithName:@"testdata3" andNode:node];
  service4 = [[BNRemoteService alloc] initWithName:@"testdata4" andNode:node];
  service5 = [[BNRemoteService alloc] initWithName:@"testdata5" andNode:node];

  [node.server connectToAddress:@"localhost:1371"];
  [node.server connectToAddress:@"localhost:1372"];
  [node.server connectToAddress:@"localhost:1373"];
  [node.server connectToAddress:@"localhost:1374"];
  [node.server connectToAddress:@"localhost:1375"];

  WAIT_WHILE(![node linkForName:service1.name]);
  WAIT_WHILE(![node linkForName:service2.name]);
  WAIT_WHILE(![node linkForName:service3.name]);
  WAIT_WHILE(![node linkForName:service4.name]);
  WAIT_WHILE(![node linkForName:service5.name]);
  GHAssertNotNil([node linkForName:service1.name], @"Check the link is there.");
  GHAssertNotNil([node linkForName:service2.name], @"Check the link is there.");
  GHAssertNotNil([node linkForName:service3.name], @"Check the link is there.");
  GHAssertNotNil([node linkForName:service4.name], @"Check the link is there.");
  GHAssertNotNil([node linkForName:service5.name], @"Check the link is there.");

  srand((unsigned int)time(NULL)); // make sure rand is seeded.

  int numPeople = 10;


  DSBNDatastore *b1 = [[DSBNDatastore alloc] initWithRemoteService:service1];
  DSBNDatastore *b2 = [[DSBNDatastore alloc] initWithRemoteService:service2];
  DSBNDatastore *b3 = [[DSBNDatastore alloc] initWithRemoteService:service3];
  DSBNDatastore *b4 = [[DSBNDatastore alloc] initWithRemoteService:service4];
  DSBNDatastore *b5 = [[DSBNDatastore alloc] initWithRemoteService:service5];

  DSDrone *d1 = [[DSDrone alloc] initWithId:DSKey(@"/Drone1/") andDatastore:b1];
  DSDrone *d2 = [[DSDrone alloc] initWithId:DSKey(@"/Drone2/") andDatastore:b2];
  DSDrone *d3 = [[DSDrone alloc] initWithId:DSKey(@"/Drone3/") andDatastore:b3];
  DSDrone *d4 = [[DSDrone alloc] initWithId:DSKey(@"/Drone4/") andDatastore:b4];
  DSDrone *d5 = [[DSDrone alloc] initWithId:DSKey(@"/Drone5/") andDatastore:b5];

  NSArray *drones = [NSArray arrayWithObjects:d1, d2, d3, d4, d5, nil];

  for (int i = 0; i < numPeople; i++) {
    NSString *str = [NSString stringWithFormat:@"%d", i];
    TestPerson *p = [[TestPerson alloc] initWithKeyName:str];
    p.first = [NSString stringWithFormat:@"first%d", i];
    p.last = [NSString stringWithFormat:@"last%d", i];
    p.phone = [NSString stringWithFormat:@"phone%d", i];
    p.age = 0;
    p.awesome = i / numPeople;
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
      GHAssertTrue(fabs(p.awesome - o.awesome) < 0.00001, @"awesome");

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

      NSLog(@"p: %@", p.version.serialRep.contents);
      NSLog(@"o: %@", o.version.serialRep.contents);
      GHAssertTrue([p isEqualToModel:o], @"equal");
      GHAssertEqualStrings(p.first, o.first, @"first");
      GHAssertEqualStrings(p.last, o.last, @"last");
      GHAssertEqualStrings(p.phone, o.phone, @"phone");
      GHAssertTrue(p.age == o.age, @"age");
      GHAssertTrue(fabs(p.awesome - o.awesome) < 0.00001, @"awesome");

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
