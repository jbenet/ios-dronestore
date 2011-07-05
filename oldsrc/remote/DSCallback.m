//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <iDrone/DSCallback.h>

@implementation DSCallback

@synthesize receiver, selector, object, onMainThread;
@synthesize didCallback, didSucceed, justObject;

- (id) initWithReceiver:(id)rcvr {
  if (self = [super init]) {
    self.receiver = rcvr;
    self.object = nil;
    self.onMainThread = NO;

    didCallback = NO;
    didSucceed = NO;
    justObject = NO;
  }
  return self;
}

- (void) dealloc {
  self.receiver = nil;
  self.object = nil;
  [super dealloc];
}

- (void) callSucceeded:(BOOL)succeeded {

  didSucceed = succeeded;
  SEL sel = selector;
  id obj = justObject ? object : self;
  if (sel && onMainThread)
    [receiver performSelectorOnMainThread:sel withObject:obj waitUntilDone:NO];
  else if (sel)
    [receiver performSelector:sel withObject:obj];

  didCallback = YES;
}

//------------------------------------------------------------------------------

+ (DSCallback *) callback {
  return [[[DSCallback alloc] initWithReceiver:nil] autorelease];
}

+ (DSCallback *) callback:(id)rcvr selector:(SEL)sel {
  DSCallback *callback = [[DSCallback alloc] initWithReceiver:rcvr];
  callback.selector = sel;
  return [callback autorelease];
}

+ (DSCallback *) callback:(id)rcvr onMainThreadSelector:(SEL)sel {
  DSCallback *callback = [self callback:rcvr selector:sel];
  callback.onMainThread = YES;
  return callback;
}

@end