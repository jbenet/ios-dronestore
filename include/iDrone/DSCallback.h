//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

@interface DSCallback : NSObject {

  id receiver;
  id object;
  SEL selector;
  BOOL onMainThread;

  BOOL didCallback;
  BOOL didSucceed;
  BOOL justObject;
}

@property (nonatomic, retain) id receiver;
@property (nonatomic, retain) id object;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) BOOL onMainThread;

@property (nonatomic, assign) BOOL didCallback;
@property (nonatomic, assign) BOOL didSucceed;
@property (nonatomic, assign) BOOL justObject;

- (id) initWithReceiver:(id)rcvr;

- (void) callSucceeded:(BOOL)succeeded;

+ (DSCallback *) callback;
+ (DSCallback *) callback:(id)rcvr selector:(SEL)sel;
+ (DSCallback *) callback:(id)rcvr onMainThreadSelector:(SEL)sel;


@end



