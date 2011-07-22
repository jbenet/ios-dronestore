

#import "DSKey.h"
#import "DSDatastore.h"
#import "DSFMDBDatastore.h"

#import "NSString+SHA.h"

@interface DatastoreTest : GHTestCase {
}
@end

@implementation DatastoreTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}


- (void) subtestStores:(NSArray *)stores ensureCount:(int)count {
  for (DSDatastore *sn in stores)
    if ([sn respondsToSelector:@selector(count)])
      GHAssertTrue([(id)sn count] == count, @"count equals");
}

- (void) subtestStores:(NSArray *)stores withNumElems:(int)numElems {

  DSKey *pkey = DSKey(@"/dsioafjdiosafjas");

  [self subtestStores:stores ensureCount:0];

  // Ensure removing non-existant keys is ok.
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    for (DSDatastore *sn in stores) {
      GHAssertFalse([sn contains:key], @"non existant");
      GHAssertNil([sn get:key], @"non existant");
      [sn delete:key]; // ok op.
      GHAssertFalse([sn contains:key], @"non existant"); // no change.
      GHAssertNil([sn get:key], @"non existant");
    }
  }

  [self subtestStores:stores ensureCount:0];

  DSQuery *query = [[DSQuery alloc] initWithType:nil];
  for (DSDatastore *sn in stores) {
    NSArray *result = [sn query:query];
    GHAssertTrue([result count] == 0, @"query count");
  }
  [query release];


  // Insert numElems elements
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    for (DSDatastore *sn in stores) {
      GHAssertFalse([sn contains:key], @"insert");
      [sn put:[NSNumber numberWithInt:i] forKey:key];
      GHAssertTrue([sn contains:key], @"insert");
      GHAssertTrue([[sn get:key] intValue] == i, @"insert");
    }
  }

  [self subtestStores:stores ensureCount:numElems];

  query = [[DSQuery alloc] initWithType:nil];
  for (DSDatastore *sn in stores) {
    NSArray *result = [sn query:query];
    GHAssertTrue([result count] == numElems, @"query count");
    result = [result sortedArrayUsingSelector:@selector(compare:)];
    for (int i = 0; i < numElems; i++)
      GHAssertTrue([[result objectAtIndex:i] intValue] == i, @"objs");
  }
  [query release];


  // Reassure they're all there
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    for (DSDatastore *sn in stores) {
      GHAssertTrue([sn contains:key], @"reassure");
      GHAssertTrue([[sn get:key] intValue] == i, @"reass");
    }
  }

  [self subtestStores:stores ensureCount:numElems];

  query = [[DSQuery alloc] initWithType:nil];
  for (DSDatastore *sn in stores) {
    NSArray *result = [sn query:query];
    GHAssertTrue([result count] == numElems, @"query count");
    result = [result sortedArrayUsingSelector:@selector(compare:)];
    for (int i = 0; i < numElems; i++)
      GHAssertTrue([[result objectAtIndex:i] intValue] == i, @"objs");
  }
  [query release];

  // Change all the elements there
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    for (DSDatastore *sn in stores) {
      GHAssertTrue([sn contains:key], @"change");
      GHAssertTrue([[sn get:key] intValue] == i, @"change");
      [sn put:[NSNumber numberWithInt:i + 1] forKey:key];
      GHAssertTrue([sn contains:key], @"change");
      GHAssertTrue([[sn get:key] intValue] != i, @"chg");
      GHAssertTrue([[sn get:key] intValue] == i + 1, @"c");
    }
  }

  [self subtestStores:stores ensureCount:numElems];

  query = [[DSQuery alloc] initWithType:nil];
  for (DSDatastore *sn in stores) {
    NSArray *result = [sn query:query];
    GHAssertTrue([result count] == numElems, @"query count");
    result = [result sortedArrayUsingSelector:@selector(compare:)];
    for (int i = 0; i < numElems; i++)
      GHAssertTrue([[result objectAtIndex:i] intValue] == i+1, @"objs");
  }
  [query release];

  // remove all elements
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    for (DSDatastore *sn in stores) {
      GHAssertTrue([sn contains:key], @"remove");
      GHAssertTrue([[sn get:key] intValue] == i + 1, @"rm");
      [sn delete:key];
      GHAssertFalse([sn contains:key], @"remove");
      GHAssertNil([sn get:key], @"remove");
    }
  }

  [self subtestStores:stores ensureCount:0];

  query = [[DSQuery alloc] initWithType:nil];
  for (DSDatastore *sn in stores) {
    NSArray *result = [sn query:query];
    GHAssertTrue([result count] == 0, @"query count");
  }
  [query release];

  // Reassure they're all not there
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    for (DSDatastore *sn in stores) {
      GHAssertFalse([sn contains:key], @"reassure gone");
      GHAssertNil([sn get:key], @"reassure gone");
    }
  }

  [self subtestStores:stores ensureCount:0];

  query = [[DSQuery alloc] initWithType:nil];
  for (DSDatastore *sn in stores) {
    NSArray *result = [sn query:query];
    GHAssertTrue([result count] == 0, @"query count");
  }
  [query release];

}

- (void) test_basic {

  NSMutableArray *arr = [NSMutableArray array];
  [arr addObject:[[[DSDictionaryDatastore alloc] init] autorelease]];
  [arr addObject:[[[DSDictionaryDatastore alloc] init] autorelease]];
  [arr addObject:[[[DSDictionaryDatastore alloc] init] autorelease]];
  [arr addObject:[[[DSDictionaryDatastore alloc] init] autorelease]];
  [self subtestStores:arr withNumElems:1000];

}

- (void) test_tiered {

  DSDatastore *s1 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s2 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s3 = [[[DSDictionaryDatastore alloc] init] autorelease];

  DSTieredDatastore *ts = [[[DSTieredDatastore alloc] init] autorelease];

  [ts addDatastore:s1];
  [ts addDatastore:s2];
  [ts addDatastore:s3];

  DSKey *k1 = DSKey(@"1");
  DSKey *k2 = DSKey(@"2");
  DSKey *k3 = DSKey(@"3");
  DSKey *k4 = DSKey(@"4");

  [s1 put:@"1" forKey:k1];
  [s2 put:@"2" forKey:k2];
  [s3 put:@"3" forKey:k3];

  // k1
  GHAssertTrue([s1 contains:k1], @"s1k1");
  GHAssertFalse([s2 contains:k1], @"s2k1");
  GHAssertFalse([s3 contains:k1], @"s3k1");
  GHAssertTrue([ts contains:k1], @"tsk1");

  GHAssertEqualStrings([s1 get:k1], @"1", @"s1k1");
  GHAssertNil([s2 get:k1], @"s2k1");
  GHAssertNil([s3 get:k1], @"s3k1");
  GHAssertEqualStrings([ts get:k1], @"1", @"tsk1");

  // k2
  GHAssertFalse([s1 contains:k2], @"s1k2");
  GHAssertTrue([s2 contains:k2], @"s2k2");
  GHAssertFalse([s3 contains:k2], @"s3k2");
  GHAssertTrue([ts contains:k2], @"tsk2");

  GHAssertNil([s1 get:k2], @"s1k2");
  GHAssertEqualStrings([s2 get:k2], @"2", @"s2k2");
  GHAssertNil([s3 get:k2], @"s3k2");
  GHAssertEqualStrings([ts get:k2], @"2", @"tsk2");

  //k3
  GHAssertFalse([s1 contains:k3], @"s1k3");
  GHAssertFalse([s2 contains:k3], @"s2k3");
  GHAssertTrue([s3 contains:k3], @"s3k3");
  GHAssertTrue([ts contains:k3], @"tsk3");

  GHAssertNil([s1 get:k3], @"s1k3");
  GHAssertNil([s2 get:k3], @"s2k3");
  GHAssertEqualStrings([s3 get:k3], @"3", @"s3k3");
  GHAssertEqualStrings([ts get:k3], @"3", @"tsk3");

  //k4
  GHAssertFalse([s1 contains:k4], @"s1k4");
  GHAssertFalse([s2 contains:k4], @"s2k4");
  GHAssertFalse([s3 contains:k4], @"s3k4");
  GHAssertFalse([ts contains:k4], @"tsk4");

  GHAssertNil([s1 get:k4], @"s1k4");
  GHAssertNil([s2 get:k4], @"s2k4");
  GHAssertNil([s3 get:k4], @"s3k4");
  GHAssertNil([ts get:k4], @"tsk4");

  //delete
  [ts delete:k1];
  [ts delete:k2];
  [ts delete:k3];
  [ts delete:k4];

  GHAssertFalse([s1 contains:k1], @"s1k4");
  GHAssertFalse([s2 contains:k2], @"s2k4");
  GHAssertFalse([s3 contains:k3], @"s3k4");

  GHAssertFalse([ts contains:k1], @"tsk4");
  GHAssertFalse([ts contains:k2], @"tsk4");
  GHAssertFalse([ts contains:k3], @"tsk4");

  [self subtestStores:[NSArray arrayWithObject:ts] withNumElems:1000];

}

- (void) testAddedUpCounts:(NSArray *)stores equals:(long)countToEq {
  long count = 0;
  for (DSDatastore *sn in stores)
    if ([sn respondsToSelector:@selector(count)])
      count += [(id)sn count];
  GHAssertTrue(count == countToEq, @"added up counts");
}


- (void) checkKey:(DSKey *)key value:(NSObject *)value
  withShardedStore:(DSShardedDatastore *)ss inShard:(DSDatastore *)shard {

  DSDatastore *correct;
  correct = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];

  for (DSDatastore *sn in ss.stores) {
    if (shard && shard == sn) {
      GHAssertTrue([sn contains:key], @"sn contains key");
      GHAssertEqualObjects([sn get:key], value, @"sn value eq");
    } else {
      GHAssertFalse([sn contains:key], @"sn not contains key");
      GHAssertNil([sn get:key], @"sn value nil");
    }
  }

  if (correct == shard) {
    GHAssertTrue([ss contains:key], @"ss contains key");
    GHAssertEqualObjects([ss get:key], value, @"ss value eq");
  } else {
    GHAssertFalse([ss contains:key], @"ss not contains key");
    GHAssertNil([ss get:key], @"ss value nil");
  }
}

- (void) test_sharded {
  int numElems = 1000;
  DSKey *pkey = DSKey(@"/dsioafjdifdsa423");

  DSDatastore *s1 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s2 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s3 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s4 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s5 = [[[DSDictionaryDatastore alloc] init] autorelease];
  DSDatastore *s6 = [[[DSDictionaryDatastore alloc] init] autorelease];

  DSShardedDatastore *ss = [[[DSShardedDatastore alloc] init] autorelease];

  [ss addDatastore:s1];
  [ss addDatastore:s2];
  [ss addDatastore:s3];
  [ss addDatastore:s4];
  [ss addDatastore:s5];
  [ss addDatastore:s6];

  DSDatastore *shard;

  [self testAddedUpCounts:ss.stores equals:0];

  // all of them
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // ensure still there
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // ensure still there
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // delete
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    if (i % 2 == 0)
      [shard delete:key];
    else
      [ss delete:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];
  }
  [self testAddedUpCounts:ss.stores equals:0];

  // all of them -- wrong
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:([ss hashForKey:key]+1)%[ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // ensure still there -- wrong
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:([ss hashForKey:key]+1)%[ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // move it to correct spot
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:([ss hashForKey:key]+1)%[ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    [shard delete:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];

    shard = [ss.stores objectAtIndex:([ss hashForKey:key]) % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // ensure still there
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    [shard put:key.string forKey:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
  }
  [self testAddedUpCounts:ss.stores equals:numElems];

  // delete
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    shard = [ss.stores objectAtIndex:[ss hashForKey:key] % [ss.stores count]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:shard];
    [shard delete:key];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];
  }
  [self testAddedUpCounts:ss.stores equals:0];

  // ensure still not there.
  for (int i = 0; i < numElems; i++) {
    DSKey *key = [pkey childWithString:[NSString stringWithFormat:@"%d", i]];
    [self checkKey:key value:key.string withShardedStore:ss inShard:nil];
  }
  [self testAddedUpCounts:ss.stores equals:0];

  [self subtestStores:ss.stores withNumElems:1000];
}

- (void) test_fmdbdatastore {

  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_1"];
  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_2"];
  [DSFMDBDatastore deleteDatabaseNamed:@"test_db_3"];

  NSString *intgr = @"NUMERIC";
  SQLSchema *s1 = [SQLSchema simpleTableNamed:@"test_db_1" withValueType:intgr];
  SQLSchema *s2 = [SQLSchema simpleTableNamed:@"test_db_2" withValueType:intgr];
  SQLSchema *s3 = [SQLSchema simpleTableNamed:@"test_db_3" withValueType:intgr];

  DSFMDBDatastore *f1 = [[DSFMDBDatastore alloc] initWithSchema:s1];
  DSFMDBDatastore *f2 = [[DSFMDBDatastore alloc] initWithSchema:s2];
  DSFMDBDatastore *f3 = [[DSFMDBDatastore alloc] initWithSchema:s3];

  NSArray *stores = [NSArray arrayWithObjects: f1, f2, f3, nil];
  [self subtestStores:stores withNumElems:100];

  [f1 release];
  [f2 release];
  [f3 release];
}

@end
