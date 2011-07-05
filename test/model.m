
#import "DSCollection.h"
#import <iDrone/DSModel.h>

@interface ModelTest : GHTestCase {
  DSModel *a, *b, *c, *d, *e;
}
@end

@implementation ModelTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void)setUpClass {
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
  [a release];
  [b release];
  [c release];
  [d release];
  [e release];
}

- (void)setUp {

}

- (void)tearDown {
}


- (void)testType {

  GHAssertTrue([a.ds_type_ isEqualToString:@"DSModel"], @"a type");
  GHAssertTrue([b.ds_type_ isEqualToString:@"DSModel"], @"b type");
  GHAssertTrue([c.ds_type_ isEqualToString:@"DSModel"], @"c type");
  GHAssertTrue([d.ds_type_ isEqualToString:@"DSModel"], @"d type");
  GHAssertTrue([e.ds_type_ isEqualToString:@"DSModel"], @"e type");

  GHAssertTrue([[DSModel ds_type_] isEqualToString:@"DSModel"], @"static type");

  GHAssertEquals([DSModel class], [DSModel classFromType:@"DSModel"], @"Class");

}

- (void) testData {

  DSModel *a2 = [DSModel modelFromData:[a data]];
  GHAssertEqualStrings(a.ds_key_, a2.ds_key_, @"Should be same keys.");
  GHAssertTrue([[a2 data] isEqualToData:[a data]], @"check data, same object");

}

@end
