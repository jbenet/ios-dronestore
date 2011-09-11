
#import <Foundation/Foundation.h>
#import "NSDate+Nanotime.h"

// A Model represents a type with a collection of Attributes
// All data in dronestore is in the form of model instances,
// addressed by a unique (hierarchical) key.
//

@class DSKey;
@class DSVersion;
@class DSAttribute;
@class DSModelAttribute;
@class DSModel;

@protocol DSModel<NSObject>
- (DSKey *) key;
- (DSVersion *) version;
- (NSDate *) created;
- (BOOL) isCommitted;

- (void) commit;
- (void) mergeVersion:(DSVersion *)other;

- (BOOL) isEqualToModel:(DSModel *)model;
@end

@protocol DSModelContainer;

@interface DSModel : NSObject <DSModel> {
  DSKey *key;
  DSVersion *version;

  NSMutableDictionary *attributeData;
}

@property (nonatomic, readonly) DSKey *key;
@property (nonatomic, readonly) DSVersion *version;
@property (nonatomic, readonly) NSDate *created;

// @property (nonatomic, readonly) BOOL isDirty; // expensive
@property (nonatomic, readonly) BOOL isCommitted;


- (id) initWithKeyName:(NSString *)keyname;
- (id) initWithKeyName:(NSString *)keyname andParent:(DSKey *)parent;
- (id) initWithVersion:(DSVersion *)version;

+ (id) modelWithVersion:(DSVersion *)version;
+ (id) modelWithDictionary:(NSDictionary *)dictionary;


- (void) commit;
- (void) mergeVersion:(DSVersion *)other;

// equality
- (BOOL) isEqualToModel:(DSModel *)model;

// Attributes
+ (DSAttribute *) attributeNamed:(NSString *)name;
+ (NSDictionary *) attributes;
- (NSDictionary *) attributeData;

- (void) initializeAttributes;
- (NSDictionary *) dataForAttribute:(NSString *)attributeName;
- (NSMutableDictionary *) mutableDataForAttribute:(NSString *)attrName;
- (void) setData:(NSDictionary *)dict forAttribute:(NSString *)attrName;

// Override this for DSModelAttributes
- (id<DSModelContainer>) modelContainerForAttribute:(DSAttribute *)attr;

+ (void) rebindAttribute:(NSString *)attr toProperty:(NSString *)property;
+ (void) registerAttribute:(DSAttribute *)attr;
+ (void) registerAttributes;

// override this to name model something different than its Class name.
- (NSString *) dstype;
+ (NSString *) dstype;
+ (DSKey *) keyWithName:(NSString *)name; // returns '/<dstype>/<name>'

+ (Class) modelWithDSType:(NSString *)type;

@end


@protocol DSModelContainer
- (void) addModel:(DSModel *)model;
- (void) removeModel:(DSModel *)model;
- (void) removeModelForKey:(DSKey *)key;
- (DSModel *) modelForKey:(DSKey *)key;
@end



