
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
@protocol DSComparable;

@interface DSMerge : NSObject {}
+ (void) mergeInstance:(DSModel *)instance withVersion:(DSVersion *)version;
@end


// A MergeStrategy represents a unique way to decide how the two values of a
// particular attributes merge together.
//
// MergeStrategies are meant to enforce a particular rule that helps ensure
// application semantics regarding attributes changed in multiple nodes.
//
// MergeStrategies can store state in the object (e.g. a timestamp). If so,
// MergeStrategies must set the REQUIRES_STATE class variable to True.
//

@interface DSMergeStrategy : NSObject {
  DSAttribute *attribute;
}

@property (nonatomic, assign) DSAttribute *attribute;

- (id) initWithAttribute:(DSAttribute *)attribute;

// Merges two versions, return attribute data.
- (NSDictionary *) mergeLocal:(DSVersion *)local withRemote:(DSVersion *)remote;

// Notify that an attribute changed to change any relevant state.
- (void) setValue:(id)value forInstance:(DSModel *)instance;

// setup initial state for attribute
- (void) setDefaultValue:(id)value forInstance:(DSModel *)instance;


+ (id) strategy;

@end


// LatestObjectStrategy merges attributes based solely on objects' timestamp.
// In essence, the most recently written object wins.
//
// This Strategy stores no additional state.
//

@interface DSLatestObjectMergeStrategy : DSMergeStrategy {}
@end

// LatestStrategy merges attributes based solely on timestamp. In essence, the
// most recently written attribute wins.
//
// This Strategy stores its state like so:
// { 'updated' : nanotime.NanoTime, 'value': attrValue }
//
// A value with a timestamp will be preferred over values without.
//

@interface DSLatestMergeStrategy : DSMergeStrategy {}
@end

// MaxStrategy merges attributes based solely on comparison. In essence, the
// larger value is picked.
//
// This Strategy stores no additional state.
//

@interface DSMaxMergeStrategy : DSMergeStrategy {}
@end

