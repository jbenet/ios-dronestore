//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import "DSCache.h"
#import <iDrone/DSCollection.h>
#import <iDrone/DSModel.h>

@implementation DSCache

- (id) init
{
  if (self = [super init]) {
    objects = [[DSCollection alloc] initWithCapacity:30];
  }
  return self;
}

- (DSModel *) modelForKey:(NSString *)dskey
{
  [objects readLock];
  DSModel *model = [[objects modelForKey:dskey] retain];
  [objects unlock];
  return [model autorelease]; // Retain-autorelease in case of garbage collect.
}

- (void) insertModel:(DSModel *)object
{
  [objects writeLock];
  [objects insertModel:object];
  [objects unlock];
}

- (int) count
{
  [objects readLock];
  int count = [objects count];
  [objects unlock];
  return count;
}

- (void) collectGarbage
{
  [objects readLock];
  NSArray *array = [objects arrayForMutableEnumeration];
  [objects unlock];

  for (NSString *key in array)
  {
    [objects readLock];
    DSModel *model = [objects modelForKey:key];
    if ([model retainCount] == 1)
    {
      [objects unlock]; // Unlock read
      [objects writeLock]; // Lock for write.
      if ([model retainCount] == 1) // Check again (races).
        [objects removeModelForKey:key];
    }
    [objects unlock];
  }
}

- (void) dealloc
{
  [objects release];
  [super dealloc];
}


@end


