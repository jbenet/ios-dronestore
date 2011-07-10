//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//


#import "DSKey.h"
#import "DSVersion.h"
#import "DSAttribute.h"
#import "DSSerialRep.h"
#import "DSModel.h"
#import "DSMerge.h"

#ifndef DSLog
#define DSLog(fmt, ...) NSLog((@"[DSLog] %s [line %d] " fmt), \
          __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#endif
