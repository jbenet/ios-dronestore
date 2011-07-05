
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
  NSDate *created;

  NSMutableDictionary *attributeData;
}

@property (nonatomic, readonly) DSKey *key;
@property (nonatomic, readonly) DSVersion *version;
@property (nonatomic, readonly) NSDate *created;

// @property (nonatomic, readonly) BOOL isDirty; // expensive
@property (nonatomic, readonly) BOOL isCommitted;


- (id) initWithKey:(DSKey *)key;
- (id) initWithVersion:(DSVersion *)version;
+ (DSModel *) modelWithVersion:(DSVersion *)version;

- (NSString *) computedHash;

- (void) commit;


+ (NSDictionary *) attributes;
- (NSDictionary *) attributeValues;
- (NSDictionary *) attributeData;

+ (void) registerAttribute:(DSAttribute *)attr;
+ (void) registerAttributes;

// override this to name model something different than its Class name.
- (NSString *) dstype;
+ (NSString *) dstype;

+ (Class) modelWithDSType:(NSString *)type;

@end



