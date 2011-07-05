
#import "DSDatabase.h"
#import <iDrone/DSModel.h>
#import "FMDatabase.h"
#import "FMResultSet.h"

@interface DatabaseTest : GHTestCase {
  DSDatabase *db;
}
@end

@implementation DatabaseTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void)setUpClass {
}

- (void)tearDownClass {
  [DSDatabase deleteDatabaseNamed:@"test"];
}

- (void)setUp {
  db = [DSDatabase databaseWithName:@"test" andDrone:nil];
  [db retain];

}

- (void)tearDown {
  [db release];
  NSLog(@"released");
}

- (void)testInsert {
  DSModel *a = [[DSModel alloc] initNew];
  NSString *key = [[a.ds_key_ copy] autorelease];
  GHAssertTrue([db saveModel:a], @"Inserting failed");

  DSModel *b = [[db modelForKey:key] retain];
  GHAssertTrue([[a ds_key_] isEqualToString:[b ds_key_]], @"Key Comparison B");

  [a release];
  [b release];

  DSModel *c = [[db modelForKey:key] retain];
  GHAssertTrue([key isEqualToString:[c ds_key_]], @"Key Comparison C");
  [c release];
}


- (void) testLookups {

  DSModel *z = [[DSModel alloc] initNew];
  NSString *key = [[z.ds_key_ copy] autorelease];
  GHAssertTrue([db saveModel:z], @"Inserting failed");

  DSModel *a = [[db modelForKey:key withClass:[DSModel class]] retain];
  GHAssertTrue([key isEqualToString:[a ds_key_]], @"Key Compare");
  [a release];

  DSModel *b;
  b = [db modelForKey:[key substringFromIndex:3] withClass:[DSModel class]];
  GHAssertNil(b, @"Shouldnt find a model here.");

  DSModel *c = [db modelForKey:[key substringFromIndex:1]];
  GHAssertNil(c, @"Shouldnt find a model here either.");

}

- (void) testInsertMultiple {
  [self testInsert];
  [self testLookups];
  [self testInsert];
  [self testLookups];
  [self testInsert];
  [self testLookups];
  [self testInsert];
  [self testLookups];
  [self testInsert];
  [self testLookups];
}

- (void) testDeleteDatabase {
  DSDatabase *ndb = [[DSDatabase alloc] initWithName:@"todelete" andDrone:nil];
  BOOL exists = [[NSFileManager defaultManager]
                  fileExistsAtPath:[DSDatabase pathForName:@"todelete"]];
  GHAssertTrue(exists, @"file exists");
  [ndb release];

  [DSDatabase deleteDatabaseNamed:@"todelete"];
  exists = [[NSFileManager defaultManager]
            fileExistsAtPath:[DSDatabase pathForName:@"todelete"]];
  GHAssertFalse(exists, @"file exists");
}

- (void) synchUseDB {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSLog(@"Begin synchUseDB...");

  [self testInsertMultiple];

  NSLog(@"End synchUseDB...");

  [pool release];
}

- (void) testMultiThreadedUse {

  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  queue.maxConcurrentOperationCount = 10;

  NSInvocationOperation *op;
  for (int i = 0; i < 20; i++) {
    op = [[NSInvocationOperation alloc] initWithTarget:self
                 selector:@selector(synchUseDB) object:nil];
    [queue addOperation:op];
  }

  [queue waitUntilAllOperationsAreFinished];

}


@end