
#import <iDrone/DSModel.h>
#import "DSCache.h"

@interface CacheTest : GHTestCase {
  DSCache *cache;
  DSModel *a, *b, *c, *d, *e;
}
@end

@implementation CacheTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void)setUpClass {

}

- (void)tearDownClass {
}

- (void)setUp {
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

  cache = [[DSCache alloc] init];
  [cache insertModel:a];
  [cache insertModel:b];
  [cache insertModel:c];
  [cache insertModel:d];
  [cache insertModel:e];
}

- (void)tearDown {

  if (a != nil) [a release];
  if (b != nil) [b release];
  if (c != nil) [c release];
  if (d != nil) [d release];
  if (e != nil) [e release];

  NSLog(@"Cache Retain Count: %i", [cache retainCount]);
  [cache release];

}

- (void)testCount {
  GHAssertEquals([cache count], 5, @"Cache Count");
}

- (void)testGet {

  GHAssertEquals(a, [cache modelForKey:a.ds_key_], @" modelForKey ");
  GHAssertEquals(b, [cache modelForKey:b.ds_key_], @" modelForKey ");
  GHAssertEquals(c, [cache modelForKey:c.ds_key_], @" modelForKey ");
  GHAssertEquals(d, [cache modelForKey:d.ds_key_], @" modelForKey ");
  GHAssertEquals(e, [cache modelForKey:e.ds_key_], @" modelForKey ");

}

- (void) testRelease {

  GHAssertEquals([cache count], 5, @"Cache Count should be 5");
  [a release];
  a = nil;
  [b release];
  b = nil;

  GHAssertEquals([cache count], 5, @"Cache Count should still be 5");

  [cache collectGarbage];

  GHAssertEquals([cache count], 3, @"Cache Count should now be 3");

}

@end