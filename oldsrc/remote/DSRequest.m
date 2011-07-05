//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <iDrone/DSDrone.h>
#import <iDrone/DSLocalDrone.h>
#import "DSRequest.h"
#import "DSConnection.h"
#import "DSCall.h"

@implementation DSRequest

@synthesize calls, fromDrone, toDrone, date;

- (id) init {
  if (self = [super init]) {
    self.calls = [NSMutableArray arrayWithCapacity:5];
  }
  return self;
}

- (void) dealloc {
  self.calls = nil;
  self.toDrone = nil;
  self.fromDrone = nil;
  self.date = nil;
  [super dealloc];
}

//------------------------------------------------------------------------------

- (void) addCall:(DSCall *) call {
  [calls addObject:call];
}

- (int) count {
  return [calls count];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id *)stackbuf count:(NSUInteger)len
{
  return [calls countByEnumeratingWithState:state objects:stackbuf count:len];
}

//------------------------------------------------------------------------------

+ (NSDate *) dateFromSerialTime:(NSNumber *)serialized {
  NSTimeInterval secs = [serialized longLongValue] * 1.0 * 1e-6;
  return [NSDate dateWithTimeIntervalSince1970:secs];
}

+ (NSNumber *) serialTimeFromDate:(NSDate *)date {
  NSTimeInterval secs = [date timeIntervalSince1970];
  return [NSNumber numberWithLongLong:secs * 1e6];
}

//------------------------------------------------------------------------------

- (id)JSON {
  return [self toDict];
}

- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
  [dict setValue:calls forKey:@"c"];
  [dict setValue:toDrone forKey:@"t"];
  [dict setValue:fromDrone forKey:@"f"];
  // systime
  return dict;
}

- (void) loadDict:(NSDictionary *)dict {
  if ([dict valueForKey:@"usec"]) {
    self.date = [[self class] dateFromSerialTime:[dict valueForKey:@"usec"]];
  }

  self.toDrone = [dict valueForKey:@"t"];
  self.fromDrone = [dict valueForKey:@"f"];

  NSArray *calls_ = [dict valueForKey:@"c"];
  for (NSDictionary *call in calls_)
    [self addCall:[DSCall callFromDict:call]];
}

+ (DSRequest *) requestFromDict:(NSDictionary *)dict {
  if ([dict valueForKey:@"c"] == nil)
    return nil;
  if ([dict valueForKey:@"t"] == nil)
    return nil;
  if ([dict valueForKey:@"f"] == nil)
    return nil;

  DSRequest *request = [[DSRequest alloc] init];
  [request loadDict:dict];
  return [request autorelease];
}

//------------------------------------------------------------------------------

+ (DSRequest *) requestWithConnection:(DSConnection *)conn {
  DSRequest *request = [[DSRequest alloc] init];
  request.fromDrone = conn.localDrone.droneid;
  request.toDrone = conn.remoteDrone.droneid;
  return [request autorelease];
}

+ (DSRequest *) requestWithConnection:(DSConnection *)conn
                             andCalls:(NSArray *)calls {
  DSRequest *request = [DSRequest requestWithConnection:conn];
  [request.calls addObjectsFromArray:calls];
  return request;
}


@end