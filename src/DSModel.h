
#import <Foundation/Foundation.h>
#import "NSDate+Nanotime.h"

// A Model represents a type with a collection of Attributes
// All data in dronestore is in the form of model instances,
// addressed by a unique (hierarchical) key.
//

@class DSKey;
@class DSVersion;
@class DSAttribute;

@interface DSModel : NSObject {
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
+ (DSModel *) modelWithVersion:(DSVersion *)version;



- (void) commit;
- (void) mergeVersion:(DSVersion *)other;


// Attributes
+ (DSAttribute *) attributeNamed:(NSString *)name;
+ (NSDictionary *) attributes;
- (NSDictionary *) attributeData;

- (void) setAttributeDefaults;
- (NSDictionary *) dataForAttribute:(NSString *)attributeName;
- (NSMutableDictionary *) mutableDataForAttribute:(NSString *)attrName;
- (void) setData:(NSDictionary *)dict forAttribute:(NSString *)attrName;

+ (void) registerAttribute:(DSAttribute *)attr;
+ (void) registerAttributes;

// override this to name model something different than its Class name.
- (NSString *) dstype;
+ (NSString *) dstype;
+ (DSKey *) keyWithName:(NSString *)name; // returns '/<dstype>/<name>'

+ (Class) modelWithDSType:(NSString *)type;

@end



