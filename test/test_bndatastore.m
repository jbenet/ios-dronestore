
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
#import "test_drone.h"


#ifndef WAIT_WHILE
#define WAIT_WHILE(condition)                                         \
  for (int i = 0; (condition) && i < 5; i++) {                    \
    NSDate *date = [NSDate date];                                     \
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate                  \
      dateWithTimeIntervalSinceNow:0.5]];                             \
    NSTimeInterval remW = 0.5 - fabs([date timeIntervalSinceNow]);    \
    [NSThread sleepForTimeInterval:remW];                             \
  }
#endif

@interface BNDatastoreTest : DroneTest {
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

  [self subtest_basic:drone];

  [service release];
  [node release];
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

  [self subtest_stress:drones people:numPeople];
}



@end
