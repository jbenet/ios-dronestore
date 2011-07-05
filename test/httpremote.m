

#import <iDrone/DSLocalDrone.h>
#import <iDrone/DSQuery.h>
#import <iDrone/DSCallback.h>
#import "DSConnection.h"
#import "DSCall.h"
#import "DSRequest.h"
#import "NSData+AES256.h"
#import "NSData+Base64.h"

static NSString *kTESTURL = @"http://127.0.0.1:9091/ds/%@/";
static NSString *kSYSTEMID = @"GAE.DroneTest.MainServer";
static NSString *kDRONEID = @"GAEDrone";
static NSString *kSYSTEM_SECRET = @"DroneTestSecret_3321";

@interface TypeModel : DSModel
{
  NSString *string_;
  double double_;
  float float_;
  int int_;
  BOOL bool_;
}

@property (nonatomic, copy) NSString *string_;
@property (nonatomic, assign) double double_;
@property (nonatomic, assign) float float_;
@property (nonatomic, assign) int int_;
@property (nonatomic, assign) BOOL bool_;

@end

@implementation TypeModel

@synthesize string_, double_, float_, int_, bool_;

- (void) loadDict:(NSDictionary *)dict
{
  string_ = [dict valueForKey:@"string_"];
  double_ = [[dict valueForKey:@"double_"] doubleValue];
  float_ = [[dict valueForKey:@"float_"] floatValue];
  int_ = [[dict valueForKey:@"int_"] intValue];
  bool_ = [[dict valueForKey:@"bool_"] boolValue];
}
- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict = [super toDict];
  [dict setValue:string_ forKey:@"string_"];
  [dict setValue:[NSNumber numberWithDouble:double_] forKey:@"double_"];
  [dict setValue:[NSNumber numberWithFloat:float_] forKey:@"float_"];
  [dict setValue:[NSNumber numberWithInt:int_] forKey:@"int_"];
  [dict setValue:[NSNumber numberWithBool:bool_] forKey:@"bool_"];
  return dict;
}
@end

@interface HTTPRemoteTest : GHTestCase {
  DSLocalDrone *drone;
  DSLocalDrone *drone2;

  bool calledBack;
}
@end

@implementation HTTPRemoteTest

- (BOOL)shouldRunOnMainThread {
  return NO;
}

- (void)setUpClass {
  drone = [DSLocalDrone localDroneWithSystemID:kSYSTEMID userID:@""];
  [drone retain];

  drone2 = [DSLocalDrone localDroneWithSystemID:kSYSTEMID userID:@"asdfasdf"];
  [drone2 retain];

  NSLog(@"drone1 droneid: %@", drone.droneid);
  NSLog(@"drone2 droneid: %@", drone2.droneid);

  drone.secret = kSYSTEM_SECRET;
  drone2.secret = kSYSTEM_SECRET;

  NSString *url = [NSString stringWithFormat:kTESTURL, drone.droneid];
  [drone addRemoteDroneID:kDRONEID withURL:url];

  url = [NSString stringWithFormat:kTESTURL, drone2.droneid];
  [drone2 addRemoteDroneID:kDRONEID withURL:url];

  calledBack = NO;
}

- (void)tearDownClass {
  [drone release];
  [drone2 release];
  drone = nil;
  drone2 = nil;
}

- (void)setUp {
}

- (void)tearDown {

}

- (void) __testTimeSerializationForTimeIntervalSince1970:(NSTimeInterval)ival {
  #define USEC_SAME(u1, u2) (abs((int)(u1 - u2)) < 10)

  uint64_t usec = ival * 1.0e6, usec2 = 0;
  NSLog(@"usec: %llu (from ival: %f)", usec, ival);
  NSLog(@"usec: %llu sec: %f", usec, usec / 1000000.0);

  NSDate *orig = [NSDate dateWithTimeIntervalSince1970:ival];
  usec2 = [orig timeIntervalSince1970] * 1.0e6;
  GHAssertNotNil(orig, @"Should be valid");
  NSLog(@"orig: %@", orig);
  NSLog(@"usec: %llu ousec: %llu", usec, usec2);
  GHAssertTrue(USEC_SAME(usec, usec2), @"usec");

  NSDate *date = [NSDate dateWithTimeIntervalSince1970:(double)usec * 1.0e-6];
  usec2 = [date timeIntervalSince1970] * 1.0e6;
  GHAssertNotNil(date, @"Should be valid");
  NSLog(@"date: %@", date);
  NSLog(@"usec: %llu dusec: %llu", usec, usec2);
  GHAssertTrue(USEC_SAME(usec, usec2), @"usec");

  NSNumber *num = [DSRequest serialTimeFromDate:date];
  GHAssertNotNil(num, @"Should be valid");
  NSLog(@"usec: %llu nusec: %@", usec, num);
  GHAssertTrue(USEC_SAME([num intValue], usec), @"usec");

  NSDate *td = [DSRequest dateFromSerialTime:num];
  usec2 = [td timeIntervalSince1970] * 1.0e6;
  GHAssertNotNil(td, @"Should be valid");
  NSLog(@"tdate: %@", td);
  NSLog(@"usec: %llu tdusec: %llu", usec, usec2);
  GHAssertTrue(USEC_SAME(usec2, usec), @"usec");

  NSNumber *num2 = [DSRequest serialTimeFromDate:td];
  GHAssertNotNil(num2, @"Should be valid");
  NSLog(@"usec: %llu n2usec: %@", usec, num2);
  GHAssertTrue(USEC_SAME([num2 intValue], usec), @"usec");
  GHAssertTrue(USEC_SAME([num intValue], [num2 intValue]), @"same");

  NSDate *td2 = [DSRequest dateFromSerialTime:num2];
  usec2 = [td2 timeIntervalSince1970] * 1.0e6;
  GHAssertNotNil(td2, @"Should be valid");
  NSLog(@"tdate2: %@", td);
  NSLog(@"usec: %llu td2usec: %llu", usec, usec2);
  GHAssertTrue(USEC_SAME(usec2, usec), @"usec");

  #undef USEC_SAME
}

- (void) testTimeSerialization {
  [self __testTimeSerializationForTimeIntervalSince1970:0];
  [self __testTimeSerializationForTimeIntervalSince1970:0];
  [self __testTimeSerializationForTimeIntervalSince1970:0];
  [self __testTimeSerializationForTimeIntervalSince1970:130.5425432];
  [self __testTimeSerializationForTimeIntervalSince1970:130163.1273961];
  [self __testTimeSerializationForTimeIntervalSince1970:1301787563.1273961];
  [self __testTimeSerializationForTimeIntervalSince1970:2601787563.1273961];
}

- (void) testConnect {
  // [conn enqueueCall:[DSCall WHOCall]];
  // [conn flushCalls];
}

- (void) testSet {

  DSModel *model = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  model.ds_owner_ = kDRONEID;
  GHAssertTrue([model save], @"Save");

  [drone flushConnectionsAndWait:YES];

}

- (void) testGet {
  DSModel *a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  GHAssertTrue([a save], @"Save");

  [drone flushConnectionsAndWait:YES];

  GHAssertNil([drone2 modelForKey:a.ds_key_], @"Shouldnt be here...");

  DSModel *b = [drone2 modelForKey:a.ds_key_ andOwner:kDRONEID
    andClass:[DSModel class]];

  GHAssertEqualStrings(a.ds_key_, b.ds_key_, @"Key Comparison");
}


- (void) testSaving {
  DSModel *a, *e;


  // local:NO remote:YES
  a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  GHAssertFalse([drone saveModel:a local:NO remote:YES], @"Save Remote");
  [drone flushConnectionsAndWait:YES];

  e = [drone modelForKey:a.ds_key_ local:YES remote:NO];
  GHAssertNil(e, @"Shouldn't be here...");
  e = [drone modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]];
  GHAssertNotNil(e, @"Should be here...");
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Key Comparison");

  e = [drone2 modelForKey:a.ds_key_ local:YES remote:NO];
  GHAssertNil(e, @"Shouldn't be here either...");
  e = [drone2 modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]];
  GHAssertNotNil(e, @"Should be here too...");
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Key Comparison");


  // local:YES remote:NO
  a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  GHAssertTrue([drone saveModel:a local:YES remote:NO], @"Save Local");
  [drone flushConnectionsAndWait:YES];

  e = [drone modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]
    local:NO remote:YES];
  GHAssertNil(e, @"Shouldn't be here...");
  e = [drone modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]];
  GHAssertNotNil(e, @"Should be here...");
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Key Comparison");

  e = [drone2 modelForKey:a.ds_key_ local:YES remote:NO];
  GHAssertNil(e, @"Shouldn't be here either...");
  e = [drone2 modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]];
  GHAssertNil(e, @"Shouldn't be here either...");

  // local:NO remote:NO
  a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  GHAssertFalse([drone saveModel:a local:NO remote:NO], @"Save Nowhere");
  [drone flushConnectionsAndWait:YES];

  e = [drone modelForKey:a.ds_key_];
  GHAssertNil(e, @"Shouldn't be here...");
  e = [drone2 modelForKey:a.ds_key_];
  GHAssertNil(e, @"Shouldn't be here either...");

  // local:YES remote:YES
  a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  GHAssertTrue([drone saveModel:a local:YES remote:YES], @"Save Both");
  [drone flushConnectionsAndWait:YES];

  e = [drone modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]];
  GHAssertNotNil(e, @"Should be here...");
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Key Comparison");

  e = [drone modelForKey:a.ds_key_ local:YES remote:NO];
  GHAssertNotNil(e, @"Should be here too...");
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Key Comparison");

  e = [drone2 modelForKey:a.ds_key_ local:YES remote:NO];
  GHAssertNil(e, @"Shouldn't be here...");
  e = [drone2 modelForKey:a.ds_key_ andOwner:kDRONEID andClass:[DSModel class]];
  GHAssertNotNil(e, @"But it should be here...");
  GHAssertEqualStrings(a.ds_key_, e.ds_key_, @"Key Comparison");

}

- (void) testQuery {

  DSModel *a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  DSModel *b = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  DSModel *c = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  b.ds_owner_ = kDRONEID;
  c.ds_owner_ = kDRONEID;

  a.ds_key_ = @"zzzzzzzzz";
  b.ds_key_ = @"zzzzzzzzzz";

  GHAssertTrue([a save], @"Save A");
  GHAssertTrue([b save], @"Save B");
  GHAssertTrue([c save], @"Save C");

  [drone flushConnectionsAndWait:YES];

  DSQuery *query = [DSQuery queryDroneID:kDRONEID];
  [query filterByField:@"ds_key_ >=" value:a.ds_key_];
  [query runWithLocalDrone:drone2 wait:YES];

  GHAssertTrue([query.models count] == 2, @"Should get 2 models");
  GHAssertNotNil([query.models modelForKey:a.ds_key_], @"Should have a");
  GHAssertNotNil([query.models modelForKey:b.ds_key_], @"Should have b");
  GHAssertNil([query.models modelForKey:c.ds_key_], @"Should not have c");

}

- (void) testUpdateQuery {
  DSQuery *query;
  NSString *testDate;

  DSModel *a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  DSModel *b = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  DSModel *c = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  b.ds_owner_ = kDRONEID;
  c.ds_owner_ = kDRONEID;

  a.ds_key_ = @"testUpdateQuery_a";
  b.ds_key_ = @"testUpdateQuery_b";
  c.ds_key_ = @"testUpdateQuery_c";

  NSLog(@"A %@", a.ds_key_);
  NSLog(@"B %@", b.ds_key_);
  NSLog(@"C %@", c.ds_key_);

  GHAssertTrue([a save], @"Save A");
  [drone flushConnectionsAndWait:YES];
  testDate = [drone stringFromDate:[NSDate date]];
  GHAssertTrue([b save], @"Save B");
  GHAssertTrue([c save], @"Save C");
  [drone flushConnectionsAndWait:YES];

  NSLog(@"A %@", a.ds_key_);
  NSLog(@"B %@", b.ds_key_);
  NSLog(@"C %@", c.ds_key_);

  query = [DSQuery queryDroneID:kDRONEID];
  [query filterByField:@"ds_updated_ >" value:testDate];
  [query runWithLocalDrone:drone2 wait:YES];

  NSLog(@"%@", [query.models models]);

  GHAssertNil([query.models modelForKey:a.ds_key_], @"Should not have a");
  GHAssertNotNil([query.models modelForKey:b.ds_key_], @"Should have b");
  GHAssertNotNil([query.models modelForKey:c.ds_key_], @"Should have c");

  testDate = [drone stringFromDate:[NSDate date]];

  query = [DSQuery queryDroneID:kDRONEID];
  [query filterByField:@"ds_updated_ >" value:testDate];
  [query runWithLocalDrone:drone2 wait:YES];

  GHAssertTrue([query.models count] == 0, @"Should find none");
  GHAssertNil([query.models modelForKey:a.ds_key_], @"Should not have a");
  GHAssertNil([query.models modelForKey:b.ds_key_], @"Should not have b");
  GHAssertNil([query.models modelForKey:c.ds_key_], @"Should not have c");

  GHAssertTrue([a save], @"Save A");
  [drone flushConnectionsAndWait:YES];


  query = [DSQuery queryDroneID:kDRONEID];
  [query filterByField:@"ds_updated_ >" value:testDate];
  [query runWithLocalDrone:drone2 wait:YES];

  GHAssertNotNil([query.models modelForKey:a.ds_key_], @"Should have a");
  GHAssertNil([query.models modelForKey:b.ds_key_], @"Should not have b");
  GHAssertNil([query.models modelForKey:c.ds_key_], @"Should not have c");


}


- (void) testTimedQuery {
  GHAssertTrue(TIMETESTS, @"Time tests must be on");

  DSModel *a = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  DSModel *b = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  DSModel *c = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  b.ds_owner_ = kDRONEID;
  c.ds_owner_ = kDRONEID;

  a.ds_key_ = @"zzzzzzzzz";
  b.ds_key_ = @"zzzzzzzzzz";

  GHAssertTrue([a save], @"Save A");
  GHAssertTrue([b save], @"Save B");
  GHAssertTrue([c save], @"Save C");

  [drone flushConnectionsAndWait:YES];

  DSQuery *query = [DSQuery queryDroneID:kDRONEID];
  [query filterByField:@"ds_key_ >=" value:a.ds_key_];
  [query runWithLocalDrone:drone2 wait:NO];

  [NSThread sleepForTimeInterval: 20];

  GHAssertTrue([query.models count] == 2, @"Should get 2 models");
  GHAssertNotNil([query.models modelForKey:a.ds_key_], @"Should have a");
  GHAssertNotNil([query.models modelForKey:b.ds_key_], @"Should have b");
  GHAssertNil([query.models modelForKey:c.ds_key_], @"Should not have c");

}

- (void) callbackDone {
  calledBack = YES;
}

- (void) testTimedCallbacks {

  GHAssertTrue(TIMETESTS, @"Time tests must be on");

  DSQuery *query;

  calledBack = NO;
  query = [DSQuery queryDroneID:kDRONEID];
  query.callback = [DSCallback callback:self selector:@selector(callbackDone)];
  [query runWithLocalDrone:drone2 wait:NO];

  [NSThread sleepForTimeInterval: 20];
  GHAssertTrue(calledBack, @"callback should be done");

  calledBack = NO;
  query = [DSQuery queryDroneID:kDRONEID];
  query.callback = [DSCallback callback:self selector:@selector(callbackDone)];
  [query runWithLocalDrone:drone2 wait:NO];

  [drone2 flushConnections];
  [NSThread sleepForTimeInterval: 4];
  GHAssertTrue(calledBack, @"callback should be done");
}

- (void) testTypesRemotely {

  TypeModel *a = [[[TypeModel alloc] initNewWithDrone:drone] autorelease];
  a.ds_owner_ = kDRONEID;
  a.string_ = @"hello";
  a.float_ = 10.5;
  a.double_ = 10.5;
  a.int_ = 10;
  a.bool_ = YES;
  GHAssertTrue([a save], @"Save");

  TypeModel *b = [[[TypeModel alloc] initNewWithDrone:drone] autorelease];
  b.ds_owner_ = kDRONEID;
  b.string_ = @"tame.";
//  b.string_ = @"hello fewnfoirqjfo43qjf489q3huy4rg3415qr56321tr48732ugop5;rwthjbdgniubhs ~!@#$%^&*()_+{}[]()''''\"";
  b.float_ = 10;
  b.double_ = 0;
  b.int_ = -11431;
  b.bool_ = NO;
  GHAssertTrue([b save], @"Save");

  [drone flushConnectionsAndWait:YES];

  GHAssertNil([drone2 modelForKey:a.ds_key_], @"Shouldnt be here...");
  GHAssertNil([drone2 modelForKey:b.ds_key_], @"Shouldnt be here...");
  TypeModel *c = [[TypeModel alloc] initWithKey:a.ds_key_ andDrone:drone];
  c.ds_owner_ = kDRONEID;
  [c load];

  TypeModel *d = [[TypeModel alloc] initWithKey:b.ds_key_ andDrone:drone];
  d.ds_owner_ = kDRONEID;
  [d load];

  [drone flushConnectionsAndWait:YES];

  GHAssertEqualStrings(a.ds_key_, c.ds_key_, @"Key Comparison");
  GHAssertEqualStrings(c.string_, a.string_, @"string");
  GHAssertTrue(c.float_ == a.float_, @"float");
  GHAssertTrue(c.double_ == a.double_, @"double");
  GHAssertTrue(c.int_ == a.int_, @"int");
  GHAssertTrue(c.bool_ == a.bool_, @"bool");

  GHAssertEqualStrings(d.ds_key_, b.ds_key_, @"Key Comparison");
  GHAssertEqualStrings(d.string_, b.string_, @"string");
  GHAssertTrue(d.float_ == b.float_, @"float");
  GHAssertTrue(d.double_ == b.double_, @"double");
  GHAssertTrue(d.int_ == b.int_, @"int");
  GHAssertTrue(d.bool_ == b.bool_, @"bool");

}

- (void) testPOST {
  DSModel *model;
  DSQuery *query;

  NSString *beforeSet = [drone stringFromDate:[NSDate date]];
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:30];

  for (int i = 0; i < 30; i++) {
    model = [[[DSModel alloc] initNewWithDrone:drone] autorelease];
    model.ds_owner_ = kDRONEID;
    GHAssertTrue([model save], @"Saving %i", i);
    [array addObject:model.ds_key_];
  }

  [drone flushConnectionsAndWait:YES];

  query = [DSQuery queryDroneID:kDRONEID];
  [query filterByField:@"ds_updated_ >" value:beforeSet];
  [query runWithLocalDrone:drone wait:YES];

  for (NSString *dskey in array)
    GHAssertNotNil([query.models modelForKey:dskey], @"Should have all keys.");
}

- (void) testEncryption {

  NSString *string = @"Testing Testing 123 Testing.";
  NSData *testData = [string dataUsingEncoding:NSASCIIStringEncoding];
  NSData *encrypted = [testData AES256EncryptWithKey:kSYSTEM_SECRET];
  NSData *b64encoded = [encrypted base64EncodedData];
  NSData *b64decoded = [b64encoded base64DecodedData];
  NSData *decrypted = [b64decoded AES256DecryptWithKey:kSYSTEM_SECRET];

  NSString *enc_str = [[[NSString alloc] initWithData:encrypted
                            encoding:NSASCIIStringEncoding] autorelease];
  NSString *b64e_str = [[[NSString alloc] initWithData:b64encoded
                            encoding:NSASCIIStringEncoding] autorelease];

  NSString *b64d_str = [[[NSString alloc] initWithData:b64decoded
                            encoding:NSASCIIStringEncoding] autorelease];

  NSString *dec_str = [[[NSString alloc] initWithData:decrypted
                            encoding:NSASCIIStringEncoding] autorelease];


  NSLog(@"String: %@", string);
  NSLog(@"Encrypted: '%@'", enc_str);
  NSLog(@"B64 Encoded: '%@'", b64e_str);
  NSLog(@"B64 Decoded: '%@'", b64d_str);
  NSLog(@"Decrypted: '%@'", dec_str);
  GHAssertEqualStrings(enc_str, b64d_str, @"b64 Decoded Equal");
  GHAssertEqualStrings(string, dec_str, @"Encryption Equal");

}

@end