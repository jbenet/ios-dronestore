
#import "DSCollection.h"
#import <iDrone/DSCollection.h>
#import <iDrone/DSModel.h>
#import <YAJL/YAJL.h>

@interface CollectionTest : GHTestCase {
  DSCollection *collection;
  DSModel *a, *b, *c, *d, *e;
}
@end

@implementation CollectionTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void)setUpClass {
  [super setUpClass];

  a = [[DSModel alloc] initNew];
  b = [[DSModel alloc] initNew];
  c = [[DSModel alloc] initNew];
  d = [[DSModel alloc] initNew];
  e = [[DSModel alloc] initNew];

  NSLog(@" a :: %@ ", a.ds_key_);
  NSLog(@" b :: %@ ", b.ds_key_);
  NSLog(@" c :: %@ ", c.ds_key_);
  NSLog(@" d :: %@ ", d.ds_key_);
  NSLog(@" e :: %@ ", e.ds_key_);
}

- (void)tearDownClass {
  [super tearDownClass];

  [a release];
  [b release];
  [c release];
  [d release];
  [e release];
}

- (void)setUp {
  [super setUp];

  collection = [[DSCollection alloc] init];

  [collection insertModel:a];
  [collection insertModel:b];
  [collection insertModel:c];
  [collection insertModel:d];
  [collection insertModel:e];
  NSLog(@"SetUp");
}

- (void)tearDown {
  [super tearDown];

  NSLog(@"TearDown");
  [collection release];
  collection = nil;
}

- (void)testSize {

  GHAssertEquals([collection count], 5, @"Collection Count == 5");

}

- (void)testGet {

  GHAssertTrue([a isEqual:[collection modelForKey:a.ds_key_]], @"modelForKey");
  GHAssertTrue([b isEqual:[collection modelForKey:b.ds_key_]], @"modelForKey");
  GHAssertTrue([c isEqual:[collection modelForKey:c.ds_key_]], @"modelForKey");
  GHAssertTrue([d isEqual:[collection modelForKey:d.ds_key_]], @"modelForKey");
  GHAssertTrue([e isEqual:[collection modelForKey:e.ds_key_]], @"modelForKey");

  NSLog(@" at 0 : %@ ", [[collection modelAtIndex:0] ds_key_]);
  GHAssertTrue([a isEqual:[collection modelAtIndex:0]], @" modelAtIndex ");
  NSLog(@" at 1 : %@ ", [[collection modelAtIndex:1] ds_key_]);
  GHAssertTrue([b isEqual:[collection modelAtIndex:1]], @" modelAtIndex ");
  NSLog(@" at 2 : %@ ", [[collection modelAtIndex:2] ds_key_]);
  GHAssertTrue([c isEqual:[collection modelAtIndex:2]], @" modelAtIndex ");
  NSLog(@" at 3 : %@ ", [[collection modelAtIndex:3] ds_key_]);
  GHAssertTrue([d isEqual:[collection modelAtIndex:3]], @" modelAtIndex ");
  NSLog(@" at 4 : %@ ", [[collection modelAtIndex:4] ds_key_]);
  GHAssertTrue([e isEqual:[collection modelAtIndex:4]], @" modelAtIndex ");

}

- (void)testGetSameMemory {

  GHAssertEquals(a, [collection modelForKey:a.ds_key_], @" modelForKey ");
  GHAssertEquals(b, [collection modelForKey:b.ds_key_], @" modelForKey ");
  GHAssertEquals(c, [collection modelForKey:c.ds_key_], @" modelForKey ");
  GHAssertEquals(d, [collection modelForKey:d.ds_key_], @" modelForKey ");
  GHAssertEquals(e, [collection modelForKey:e.ds_key_], @" modelForKey ");

  NSLog(@" at 0 : %@ ", [[collection modelAtIndex:0] ds_key_]);
  GHAssertEquals(a, [collection modelAtIndex:0], @" modelAtIndex ");
  NSLog(@" at 1 : %@ ", [[collection modelAtIndex:1] ds_key_]);
  GHAssertEquals(b, [collection modelAtIndex:1], @" modelAtIndex ");
  NSLog(@" at 2 : %@ ", [[collection modelAtIndex:2] ds_key_]);
  GHAssertEquals(c, [collection modelAtIndex:2], @" modelAtIndex ");
  NSLog(@" at 3 : %@ ", [[collection modelAtIndex:3] ds_key_]);
  GHAssertEquals(d, [collection modelAtIndex:3], @" modelAtIndex ");
  NSLog(@" at 4 : %@ ", [[collection modelAtIndex:4] ds_key_]);
  GHAssertEquals(e, [collection modelAtIndex:4], @" modelAtIndex ");

}


- (void) testRemove {

  [collection removeModel:a];
  GHAssertEquals([collection count], 4, @"Collection Count == 4");
  [collection removeModel:b];
  GHAssertEquals([collection count], 3, @"Collection Count == 3");
  [collection removeModel:c];
  GHAssertEquals([collection count], 2, @"Collection Count == 2");
  [collection removeModelAtIndex:1];
  GHAssertEquals([collection count], 1, @"Collection Count == 1");
  [collection removeModelAtIndex:0];
  GHAssertEquals([collection count], 0, @"Collection Count == 0");
}

- (void) testRemoveMany {

  NSArray *array = [NSArray arrayWithObjects: a, b.ds_key_, c, @"science", nil];

  GHAssertEquals([collection count], 5, @"Collection Count == 4");
  [collection removeModelsInArray:array];
  GHAssertEquals([collection count], 2, @"Collection Count == 4");

  [collection removeAllModels];
  GHAssertEquals([collection count], 0, @"Collection Count == 0");

}

- (void) testRemoveAll {

  GHAssertEquals([collection count], 5, @"Collection Count == 5");
  [collection clear];
  GHAssertEquals([collection count], 0, @"Collection Count == 0");

}

- (void) testInsert {
  [self testRemove];

  [collection insertModel:a];
  GHAssertEquals([collection count], 1, @"Collection Count == 1");
  GHAssertEquals(a, [collection modelAtIndex:0], @" modelAtIndex ");

  [collection insertModel:b atIndex: 1];
  GHAssertEquals(b, [collection modelAtIndex:1], @" modelAtIndex ");
  GHAssertEquals([collection count], 2, @"Collection Count == 1");

  [collection insertModel:c atIndex: 1];
  GHAssertEquals(c, [collection modelAtIndex:1], @" modelAtIndex ");
  GHAssertEquals(b, [collection modelAtIndex:2], @" modelAtIndex ");
  GHAssertEquals(a, [collection modelAtIndex:0], @" modelAtIndex ");
  GHAssertEquals([collection count], 3, @"Collection Count == 1");

}

- (void) testDuplicateInsert {
  [collection insertModel:a];
  [collection insertModel:a];
  [collection insertModel:a];
  [collection insertModel:b];
  [collection insertModel:c atIndex:3];
  [collection insertModel:a atIndex:4];
  [collection insertModel:a];
  GHAssertEquals([collection count], 5, @"Collection Count == 5");

}

- (void) testData {
  NSData *data = [collection data];
  NSLog(@"Data: %@", data);
  [collection release];
  collection = [[DSCollection collectionWithData:data] retain];
  NSLog(@"Data2: %@", [collection data]);
  [self testGet];
}

- (void) testArray {
  NSLog(@"From %@", [collection yajl_JSONString]);

  NSArray *array = [collection models];
  [collection release];
  collection = [[DSCollection collectionWithArray:array] retain];
  [self testGetSameMemory];
  NSLog(@"To %@", [collection yajl_JSONString]);

  NSArray *array2 = [[collection yajl_JSONString] yajl_JSON];
  [collection release];
  collection = [[DSCollection collectionWithArray:array2] retain];
  NSLog(@"To %@", [collection yajl_JSONString]);
  [self testGet];

}

- (void) testRemoveAndInsert {

  [collection removeModel:a];
  [collection removeModel:b];
  [collection removeModel:c];
  GHAssertEquals([collection count], 2, @"Collection Count == 2");
  [collection insertModel:a];
  [collection insertModel:b];
  GHAssertEquals([collection count], 4, @"Collection Count == 4");

  GHAssertEquals(a, [collection modelForKey:a.ds_key_], @" modelForKey ");
  GHAssertEquals(b, [collection modelForKey:b.ds_key_], @" modelForKey ");
  GHAssertNil([collection modelForKey:c.ds_key_], @" modelForKey ");
  GHAssertEquals(d, [collection modelForKey:d.ds_key_], @" modelForKey ");
  GHAssertEquals(e, [collection modelForKey:e.ds_key_], @" modelForKey ");

  GHAssertEquals(d, [collection modelAtIndex:0], @" modelAtIndex ");
  GHAssertEquals(e, [collection modelAtIndex:1], @" modelAtIndex ");
  GHAssertEquals(a, [collection modelAtIndex:2], @" modelAtIndex ");
  GHAssertEquals(b, [collection modelAtIndex:3], @" modelAtIndex ");
  GHAssertThrowsSpecific([collection modelAtIndex:4], NSException, NSRangeException, @" modelAtIndex ");

}

- (void) testCopy {

  GHAssertEquals([collection count], 5, @"Collection Count == 5");
  DSCollection *other = [collection copy];

  GHAssertEquals([other count], 5, @"Collection Count == 5");

  [other removeModel:a];
  [other removeModel:b];

  GHAssertEquals([collection count], 5, @"Collection Count == 5");
  GHAssertEquals([other count], 3, @"Collection Count == 5");

  [collection removeModel:c];
  [collection removeModel:a];

  GHAssertEquals([collection count], 3, @"Collection Count == 5");
  GHAssertEquals([other count], 3, @"Collection Count == 5");

  [other insertModel:a];

  GHAssertEquals([collection count], 3, @"Collection Count == 5");
  GHAssertEquals([other count], 4, @"Collection Count == 5");

  [other release];
}

@end
