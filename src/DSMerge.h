
#import <Foundation/Foundation.h>

// A MergeStrategy represents a unique way to decide how the two values of a
// particular attributes merge together.
//
// MergeStrategies are meant to enforce a particular rule that helps ensure
// application semantics regarding attributes changed in multiple nodes.
//
// MergeStrategies can store state in the object (e.g. a timestamp). If so,
// MergeStrategies must set the REQUIRES_STATE class variable to True.
//


@class DSModel;
@class DSVersion;
@class DSAttribute;

@interface DSMerge : NSObject {}
+ (void) mergeInstance:(DSModel *)instance withVersion:(DSVersion *)version;
@end


@interface DSMergeStrategy : NSObject {
  DSAttribute *attribute;
}

- (id) initWithAttribute:(DSAttribute *)attribute;

// Merges two versions
- (void) mergeLocal:(DSVersion *)local withRemote:(DSVersion *)remote;

// Notify that an attribute changed to change any relevant state.
- (void) setValue:(id)value forInstance:(DSModel *)instance;

@end

