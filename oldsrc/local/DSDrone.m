//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//


#import <iDrone/DSDrone.h>
#import <iDrone/DSModel.h>
#import <UIKit/UIKit.h>
#import <iDrone/DSLocalDrone.h>
#import <CommonCrypto/CommonDigest.h>

static DSDrone *mainDrone = nil;
static DSDrone *lastDrone = nil;

static NSString *kDATE_FORMAT = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSS";
static NSString *kDATE_TZ = @"UTC";

@implementation DSDrone

@synthesize droneid, secret, pub_key, pri_key, dateFormatter, systemTimeOffset;

- (void) dealloc
{
  @synchronized ([DSDrone class]) {
    if (mainDrone == self)
      mainDrone = nil;

    if (lastDrone == self)
      lastDrone = nil;

    if (drone == self)
      drone = nil;

    self.droneid = nil;
    self.secret = nil;
    self.pub_key = nil;
    self.pri_key = nil;

    self.dateFormatter = nil;
    [super dealloc];
  }
}

//------------------------------------------------------------------------------

- (BOOL) saveModel:(DSModel *)model
{
  return NO;
}

- (BOOL) loadModel:(DSModel *)model
{
  return NO;
}

- (BOOL) saveModel:(DSModel *)model local:(BOOL)local remote:(BOOL)remote
{
  return NO;
}

- (BOOL) loadModel:(DSModel *)model local:(BOOL)local remote:(BOOL)remote
{
  return NO;
}

- (BOOL) cacheModel:(DSModel *)model
{
  return NO;
}

//------------------------------------------------------------------------------

- (id) modelForKey:(NSString *)key
{
  return nil;
}

- (id) modelForKey:(NSString *)key local:(BOOL)local remote:(BOOL)remote
{
  return nil;
}

- (id) modelForKey:(NSString *)key withClass:(Class) modelClass
{
  return nil;
}

- (id) modelForKey:(NSString *)key andOwner:(NSString *)owner
  andClass:(Class)class
{
  return nil;
}

- (id) modelForKey: (NSString *)key andOwner:(NSString *)owner
  andClass:(Class)class local:(BOOL)local remote:(BOOL)remote;
{
  return nil;
}

//------------------------------------------------------------------------------

+ (DSDrone *) remoteDroneWithDroneID:(NSString *)did andDrone:(DSDrone *)drone_
{
  DSDrone *remote = [drone_ modelForKey:did];
  if (remote == nil) {
    remote = [[[DSDrone alloc] initNewWithDrone:drone_] autorelease];
    remote.droneid = did;
    remote.ds_key_ = did;
    [remote save];
  }
  return remote;
}

+ (DSDrone *) localDroneWithSystemID:(NSString *)system userID:(NSString *)user
{
  return [DSLocalDrone localDroneWithSystemID:system userID:user];
}

//------------------------------------------------------------------------------

// First Drone or drone specified.
+ (DSDrone *) mainDrone {
  DSDrone *drone = nil;
  @synchronized ([DSDrone class]) {
    drone = lastDrone;
    if (mainDrone != nil)
      drone = mainDrone;
  }
  return drone;
}

+ (void) setMainDrone:(DSDrone *)drone {
  // No retain, as we don't want to hold on to it
  @synchronized ([DSDrone class]) {
    mainDrone = drone;
  }
}

+ (void) setLastDrone:(DSDrone *)drone {
  @synchronized ([DSDrone class]) {
    lastDrone = drone;
  }
}

//------------------------------------------------------------------------------

- (NSDateFormatter *) dateFormatter {
  if (dateFormatter == nil) {
    @synchronized (self) {
      if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:kDATE_FORMAT];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:kDATE_TZ]];
      }
    }
  }
  return dateFormatter;
}

- (NSString *) stringFromDate:(NSDate *)date {
  if (date == nil)
    return nil;

  @synchronized(dateFormatter) {
    return [self.dateFormatter stringFromDate:date];
  }
}

- (NSDate *) dateFromString:(NSString *)string {
  if (string == nil || ![string isKindOfClass:[NSString class]]
    || [string length] < 1)
    return nil;

  @synchronized(dateFormatter) {
    return [self.dateFormatter dateFromString:string];
  }
}

//------------------------------------------------------------------------------

- (void) setSystemDate:(NSDate *)date {
  systemTimeOffset = [date timeIntervalSinceDate:[NSDate date]];
}

- (NSDate *) systemDate {
  return [NSDate dateWithTimeIntervalSinceNow:systemTimeOffset];
}


//------------------------------------------------------------------------------

+ (NSString *) sha256HexDigestFrom:(NSString *) input
{
  unsigned char hashed[32];
  CC_SHA256([input UTF8String],
            [input lengthOfBytesUsingEncoding:NSASCIIStringEncoding],
            hashed);

  NSMutableString *hex = [[[NSMutableString alloc] init] autorelease];
  for (int i = 0; i < 32; i++)
    [hex appendFormat:@"%02x", hashed[i]];

  return hex;
}

//------------------------------------------------------------------------------

- (void) loadDict:(NSDictionary *)dict
{
  [super loadDict:dict];
  self.droneid = [dict objectForKey:@"droneid"];
  self.secret = [dict objectForKey:@"secret"];
  self.pub_key = [dict objectForKey:@"pub_key"];
  self.pri_key = [dict objectForKey:@"pri_key"];
}

- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict = [super toDict];
  [dict setValue: self.droneid forKey:@"droneid"];
  if (self.secret != nil)
    [dict setValue: self.secret forKey:@"secret"];
  if (self.pub_key != nil)
    [dict setValue: self.pub_key forKey:@"pub_key"];
  if (self.pri_key != nil)
    [dict setValue: self.pri_key forKey:@"pri_key"];

  return dict;
}
@end