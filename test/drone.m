

#import <iDrone/DSDrone.h>
#import <iDrone/DSLocalDrone.h>

@interface TestModel : DSModel {
  int a;
  int b;
  int c;
}
@property (nonatomic, assign) int a;
@property (nonatomic, assign) int b;
@property (nonatomic, assign) int c;
@end

@implementation TestModel
@synthesize a, b, c;

- (BOOL) invariantsHold {
  return a < b && b < c;
}

- (void) loadDict:(NSDictionary *)dict {
  [super loadDict:dict];
  a = [[dict valueForKey:@"a"] intValue];
  b = [[dict valueForKey:@"b"] intValue];
  c = [[dict valueForKey:@"c"] intValue];
}

- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict = [super toDict];
  [dict setValue:[NSNumber numberWithInt:a] forKey:@"a"];
  [dict setValue:[NSNumber numberWithInt:b] forKey:@"a"];
  [dict setValue:[NSNumber numberWithInt:c] forKey:@"a"];
  return dict;
}
@end

@interface DroneTest : GHTestCase {
  DSDrone *drone;
  NSString *key;
  NSString *key2;
  NSString *key3;
}
@end

@implementation DroneTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void)setUpClass {

}

- (void)tearDownClass {
}

- (void)setUp {
  drone = [DSDrone localDroneWithSystemID:@"goo" userID:@"gee"];
  [drone retain];
}

- (void)tearDown {
  [drone release];
}

- (void) testMainDrone {
  GHAssertEquals(drone, [DSDrone mainDrone], @"first drone, should be main.");
  [drone release];

  drone = [DSDrone localDroneWithSystemID:@"goo" userID:@"gee"];
  [drone retain];
  GHAssertEquals(drone, [DSDrone mainDrone], @"last drone, should be main.");

  DSDrone *drone2 = [DSDrone localDroneWithSystemID:@"goo" userID:@"geeaa"];
  GHAssertEquals(drone2, [DSDrone mainDrone], @"last drone, should be main.");

  [DSDrone setMainDrone:drone];
  GHAssertEquals(drone, [DSDrone mainDrone], @"explicitly set, frist should be main.");

  drone2 = [DSDrone localDroneWithSystemID:@"goo" userID:@"geeaaaa"];
  GHAssertEquals(drone, [DSDrone mainDrone], @"was explicitly set, even if we make a new one.");
}

- (void) testInsertData {

  DSModel *m = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  GHAssertTrue([m save], @"Inserting Data");
  key = [[[m ds_key_] copy] autorelease];

  TestModel *t = [[[TestModel alloc] initNewWithDrone:drone] autorelease];
  t.a = 1;
  t.b = 2;
  t.c = 3;
  GHAssertTrue([t save], @"Inserting Test");
  key2 = [[[t ds_key_] copy] autorelease];

  TestModel *t2 = [[[TestModel alloc] initNewWithDrone:drone] autorelease];
  t2.a = 1;
  t2.b = 2;
  t2.c = 2;
  GHAssertFalse([t2 save], @"Invariant does not hold");
  key3 = [[[t2 ds_key_] copy] autorelease];
}

- (void) testLookupData {
  // Must go after testInsertData

  DSModel *m = [drone modelForKey:key];
  GHAssertTrue([[m ds_key_] isEqualToString:key], @"Keys must be equal");
  GHAssertTrue([[m ds_owner_] isEqualToString:[drone ds_key_]],
                @"Owner must be drone key");

  GHAssertNil([drone modelForKey:[key substringFromIndex:1]],
                @"Shouldnt be anything");
  GHAssertNil([drone modelForKey:[key substringFromIndex:5]],
                @"Shouldnt be anything");


  TestModel *t = [drone modelForKey:key2];
  GHAssertTrue([[t ds_key_] isEqualToString:key2], @"Keys must be equal");
  GHAssertTrue([[t ds_owner_] isEqualToString:[drone ds_key_]],
                @"Owner must be drone key");

  GHAssertNil([drone modelForKey:[key2 substringFromIndex:1]],
                @"Shouldnt be anything");
  GHAssertNil([drone modelForKey:[key2 substringFromIndex:5]],
                @"Shouldnt be anything");

  GHAssertNil([drone modelForKey:key3], @"Shouldnt be anything");

}

- (void)testIDs {
  NSLog(@"droneid: %@", drone.droneid);
  NSLog(@"systemid: %@", [(DSLocalDrone *)drone systemid]);
  NSLog(@"deviceid: %@", [(DSLocalDrone *)drone deviceid]);
}

- (void)testIDs_again {
  [self testIDs];
}

- (void) testSHADigest {
  NSString *a, *b, *c;
  a = [DSLocalDrone sha256HexDigestFrom:@"abcdefghijklmnopqrstuvwxyz"];
  b = @"71c480df93d6ae2f1efad1447c66c9525e316218cf51fc8d9ed832f2daf18b73";
  c = [NSString stringWithFormat:@" SHA digest (%@ == %@)", a, b];
  GHAssertTrue([a isEqualToString:b], c);
}

- (void) testTimedRelease {

  GHAssertTrue(TIMETESTS, @"Time tests must be on");

  [drone release];

  [NSThread sleepForTimeInterval: 20];

  drone = [DSDrone localDroneWithSystemID:@"goo" userID:@"gee"];
  [drone retain];

}

- (void) testCachedSavedData {
  DSModel *a, *b, *c, *d, *e;

  a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  GHAssertTrue([a save], @"Inserting Data");

  b = [drone modelForKey:a.ds_key_];
  GHAssertEqualStrings(a.ds_key_, b.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == b, @"Should be same pointer.");

  c = [[[DSModel alloc] initWithKey:a.ds_key_ andDrone:drone] autorelease];
  GHAssertEqualStrings(a.ds_key_, c.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == c, @"Should be same pointer.");

  d = [DSModel modelForKey:a.ds_key_];
  GHAssertEqualStrings(a.ds_key_, d.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == d, @"Should be same pointer.");

  e = [DSModel modelFromData:[a data]];
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == e, @"Should be same pointer.");

}

- (void) testCachedData {
  DSModel *a, *b, *c, *d, *e;

  a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  GHAssertTrue([a cache], @"Caching Data");

  b = [drone modelForKey:a.ds_key_];
  GHAssertEqualStrings(a.ds_key_, b.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == b, @"Should be same pointer.");

  c = [[[DSModel alloc] initWithKey:a.ds_key_ andDrone:drone] autorelease];
  GHAssertEqualStrings(a.ds_key_, c.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == c, @"Should be same pointer.");

  d = [DSModel modelForKey:a.ds_key_];
  GHAssertEqualStrings(a.ds_key_, d.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == d, @"Should be same pointer.");

  e = [DSModel modelFromData:[a data]];
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Should be same keys.");
  GHAssertTrue(a == e, @"Should be same pointer.");

}

- (void) __testSystemDate {
  NSTimeInterval offset = drone.systemTimeOffset;
  NSDate *sys_now = drone.systemDate;
  NSDate *dev_now = [NSDate date];
  NSTimeInterval observed_offset = [sys_now timeIntervalSinceDate:dev_now];

  BOOL OK = fabs(offset - observed_offset) < 10e-4;
  GHAssertTrue(OK, @"Offsets should be almost equal.");

  if (offset > 0)
    GHAssertTrue(observed_offset > 0, @"Should be future.");
  else
    GHAssertTrue(observed_offset <= 0, @"Should be past.");

}

- (void) __testSystemTimeOffset:(NSTimeInterval)offset {
  drone.systemTimeOffset = offset;
  [self __testSystemDate];
}

- (void) __testSystemDate:(NSDate *)systemDate {
  drone.systemDate = systemDate;
  [self __testSystemDate];
}

- (void) testSystemTime {
  [self __testSystemDate]; // no offset.
  [self __testSystemDate]; // no offset.
  [self __testSystemDate]; // no offset.

  [self __testSystemTimeOffset:10];
  [self __testSystemTimeOffset:2000000];
  [self __testSystemTimeOffset:-10];
  [self __testSystemTimeOffset:-2000000];
  [self __testSystemTimeOffset:0];

  [self __testSystemDate:[NSDate dateWithTimeIntervalSinceNow:10]];
  [self __testSystemDate:[NSDate dateWithTimeIntervalSinceNow:2000000]];
  [self __testSystemDate:[NSDate dateWithTimeIntervalSinceNow:-10]];
  [self __testSystemDate:[NSDate dateWithTimeIntervalSinceNow:-2000000]];
  [self __testSystemDate:[NSDate dateWithTimeIntervalSinceNow:0]];
}

@end