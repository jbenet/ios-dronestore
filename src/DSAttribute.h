
#import <Foundation/Foundation.h>

// Attributes define and compose a Model. A Model can be seen as a collection
// of attributes.
//
// An Attribute primarily defines a name, an associated data type, and a
// particular merge strategy.
//
// Attributes can have other options, including defining a default value, and
// validation for the data they hold.
//

@class DSMergeStrategy;
@class DSModel;

@interface DSAttribute : NSObject {
  NSString *name;

  Class type;
  Class strategy;

  SEL getter;
  SEL setter;
  // DSModel *model; // necessary?
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) Class type;
@property (nonatomic, readonly) Class strategy;

// ADD Defaults.
- (id) initWithName:(NSString *)name type:(Class)type
  andStrategy:(Class)strategy;

- (void) setValue:(id)value forInstance:(DSModel *)instance;
- (id) valueForInstance:(DSModel *)instance;

- (NSDictionary *) dataForInstance:(DSModel *)instance;

+ (DSAttribute *) attributeWithName:(NSString *)name type:(Class)type
  andStrategy:(Class)strategy;

@end



// @interface DSPrimitiveAttribute : DSAttribute  {
//
//   char *objCType;
// }
//
// // for type, use @encode(int) or @encode(float), et-cetera.
// - (id) initWithName:(NSString *)name objCType:(const char *)type
//   andStrategy:(DSMergeStrategy *)strategy;
//
// + (DSAttribute *) attributeWithName:(NSString *)name objCType:(const char *)type
//   andStrategy:(DSMergeStrategy *)strategy;
//
// @end

