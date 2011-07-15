
#import "DSCollection.h"
#import "DSModel.h"

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

  a = [[DSModel alloc] initWithKeyName:@"A"];
  b = [[DSModel alloc] initWithKeyName:@"b"];
  c = [[DSModel alloc] initWithKeyName:@"c"];
  d = [[DSModel alloc] initWithKeyName:@"d"];
  e = [[DSModel alloc] initWithKeyName:@"e"];

  NSLog(@" a :: %@ ", a.key);
  NSLog(@" b :: %@ ", b.key);
  NSLog(@" c :: %@ ", c.key);
  NSLog(@" d :: %@ ", d.key);
  NSLog(@" e :: %@ ", e.key);
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

  GHAssertTrue([collection count] == 5, @"Collection Count == 5");

}

- (void)testGet {

  GHAssertTrue([a isEqualToModel:[collection modelForKey:a.key]], @"mFK");
  GHAssertTrue([b isEqualToModel:[collection modelForKey:b.key]], @"mFK");
  GHAssertTrue([c isEqualToModel:[collection modelForKey:c.key]], @"mFK");
  GHAssertTrue([d isEqualToModel:[collection modelForKey:d.key]], @"mFK");
  GHAssertTrue([e isEqualToModel:[collection modelForKey:e.key]], @"mFK");

  NSLog(@" at 0 : %@ ", [[collection modelAtIndex:0] key]);
  GHAssertTrue([a isEqualToModel:[collection modelAtIndex:0]], @" mAI");
  NSLog(@" at 1 : %@ ", [[collection modelAtIndex:1] key]);
  GHAssertTrue([b isEqualToModel:[collection modelAtIndex:1]], @" mAI ");
  NSLog(@" at 2 : %@ ", [[collection modelAtIndex:2] key]);
  GHAssertTrue([c isEqualToModel:[collection modelAtIndex:2]], @" mAI ");
  NSLog(@" at 3 : %@ ", [[collection modelAtIndex:3] key]);
  GHAssertTrue([d isEqualToModel:[collection modelAtIndex:3]], @" mAI ");
  NSLog(@" at 4 : %@ ", [[collection modelAtIndex:4] key]);
  GHAssertTrue([e isEqualToModel:[collection modelAtIndex:4]], @" mAI ");

}

- (void)testGetSameMemory {

  GHAssertEquals(a, [collection modelForKey:a.key], @" modelForKey ");
  GHAssertEquals(b, [collection modelForKey:b.key], @" modelForKey ");
  GHAssertEquals(c, [collection modelForKey:c.key], @" modelForKey ");
  GHAssertEquals(d, [collection modelForKey:d.key], @" modelForKey ");
  GHAssertEquals(e, [collection modelForKey:e.key], @" modelForKey ");

  NSLog(@" at 0 : %@ ", [[collection modelAtIndex:0] key]);
  GHAssertEquals(a, [collection modelAtIndex:0], @" modelAtIndex ");
  NSLog(@" at 1 : %@ ", [[collection modelAtIndex:1] key]);
  GHAssertEquals(b, [collection modelAtIndex:1], @" modelAtIndex ");
  NSLog(@" at 2 : %@ ", [[collection modelAtIndex:2] key]);
  GHAssertEquals(c, [collection modelAtIndex:2], @" modelAtIndex ");
  NSLog(@" at 3 : %@ ", [[collection modelAtIndex:3] key]);
  GHAssertEquals(d, [collection modelAtIndex:3], @" modelAtIndex ");
  NSLog(@" at 4 : %@ ", [[collection modelAtIndex:4] key]);
  GHAssertEquals(e, [collection modelAtIndex:4], @" modelAtIndex ");

}


- (void) testRemove {

  [collection removeModel:a];
  GHAssertTrue([collection count] == 4, @"Collection Count == 4");
  [collection removeModel:b];
  GHAssertTrue([collection count] == 3, @"Collection Count == 3");
  [collection removeModel:c];
  GHAssertTrue([collection count] == 2, @"Collection Count == 2");
  [collection removeModelAtIndex:1];
  GHAssertTrue([collection count] == 1, @"Collection Count == 1");
  [collection removeModelAtIndex:0];
  GHAssertTrue([collection count] == 0, @"Collection Count == 0");
}

- (void) testRemoveMany {

  NSArray *array = [NSArray arrayWithObjects: a, b.key, c, @"science", nil];

  GHAssertTrue([collection count] == 5, @"Collection Count == 5");
  [collection removeModelsInArray:array];
  GHAssertTrue([collection count] == 2, @"Collection Count == 2");

  [collection removeAllModels];
  GHAssertTrue([collection count] == 0, @"Collection Count == 0");

}

- (void) testRemoveAll {

  GHAssertTrue([collection count] == 5, @"Collection Count == 5");
  [collection clear];
  GHAssertTrue([collection count] == 0, @"Collection Count == 0");

}

- (void) testInsert {
  [self testRemove];

  [collection insertModel:a];
  GHAssertTrue([collection count] == 1, @"Collection Count == 1");
  GHAssertEquals(a, [collection modelAtIndex:0], @" modelAtIndex ");

  [collection insertModel:b atIndex: 1];
  GHAssertEquals(b, [collection modelAtIndex:1], @" modelAtIndex ");
  GHAssertTrue([collection count] == 2, @"Collection Count == 1");

  [collection insertModel:c atIndex: 1];
  GHAssertEquals(c, [collection modelAtIndex:1], @" modelAtIndex ");
  GHAssertEquals(b, [collection modelAtIndex:2], @" modelAtIndex ");
  GHAssertEquals(a, [collection modelAtIndex:0], @" modelAtIndex ");
  GHAssertTrue([collection count] == 3, @"Collection Count == 1");

}

- (void) testDuplicateInsert {
  [collection insertModel:a];
  [collection insertModel:a];
  [collection insertModel:a];
  [collection insertModel:b];
  [collection insertModel:c atIndex:3];
  [collection insertModel:a atIndex:4];
  [collection insertModel:a];
  GHAssertTrue([collection count] == 5, @"Collection Count == 5");

}

- (void) testArray {
  NSArray *array = [collection models];
  [collection release];
  collection = [[DSCollection collectionWithArray:array] retain];
  [self testGetSameMemory];
}

- (void) testRemoveAndInsert {

  [collection removeModel:a];
  [collection removeModel:b];
  [collection removeModel:c];
  GHAssertTrue([collection count] == 2, @"Collection Count == 2");
  [collection insertModel:a];
  [collection insertModel:b];
  GHAssertTrue([collection count] == 4, @"Collection Count == 4");

  GHAssertEquals(a, [collection modelForKey:a.key], @" modelForKey ");
  GHAssertEquals(b, [collection modelForKey:b.key], @" modelForKey ");
  GHAssertNil([collection modelForKey:c.key], @" modelForKey ");
  GHAssertEquals(d, [collection modelForKey:d.key], @" modelForKey ");
  GHAssertEquals(e, [collection modelForKey:e.key], @" modelForKey ");

  GHAssertEquals(d, [collection modelAtIndex:0], @" modelAtIndex ");
  GHAssertEquals(e, [collection modelAtIndex:1], @" modelAtIndex ");
  GHAssertEquals(a, [collection modelAtIndex:2], @" modelAtIndex ");
  GHAssertEquals(b, [collection modelAtIndex:3], @" modelAtIndex ");
  GHAssertThrowsSpecific([collection modelAtIndex:4], NSException,
    NSRangeException, @" modelAtIndex ");

}

- (void) testCopy {

  GHAssertTrue([collection count] == 5, @"Collection Count == 5");
  DSCollection *other = [collection copy];

  GHAssertTrue([other count] == 5, @"Collection Count == 5");

  [other removeModel:a];
  [other removeModel:b];

  GHAssertTrue([collection count] == 5, @"Collection Count == 5");
  GHAssertTrue([other count] == 3, @"Collection Count == 5");

  [collection removeModel:c];
  [collection removeModel:a];

  GHAssertTrue([collection count] == 3, @"Collection Count == 5");
  GHAssertTrue([other count] == 3, @"Collection Count == 5");

  [other insertModel:a];

  GHAssertTrue([collection count] == 3, @"Collection Count == 5");
  GHAssertTrue([other count] == 4, @"Collection Count == 5");

  [other release];
}

@end
