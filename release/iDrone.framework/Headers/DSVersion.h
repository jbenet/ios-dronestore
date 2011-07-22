
#import <Foundation/Foundation.h>

// A version is one snapshot of a particular object's values.
//
// Versions have an associated hash (sha1). Their hash determines uniqueness of
// the object snapshot. Versions are used as snapshot 'containers,' including
// all of the data of the particular object snapshot.
//
// The current implementation does not use incremental changes, as the entire
// version history of each object is not tracked.
//

#import "DSSerialRep.h"
#import "NSDate+Nanotime.h"

@class DSKey;

extern const NSString *DSVersionBlankHash;

@interface DSVersion : NSObject {
  DSMutableSerialRep *serialRep;
}

@property (nonatomic, readonly) DSSerialRep *serialRep;

@property (nonatomic, readonly) DSKey *key;
@property (nonatomic, readonly) NSString *hashstr;
@property (nonatomic, readonly) NSString *parent;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) nanotime committed;
@property (nonatomic, readonly) NSDate * committedDate;
@property (nonatomic, readonly) nanotime created;
@property (nonatomic, readonly) NSDate * createdDate;

@property (nonatomic, readonly) BOOL isBlank;

- (id) initWithSerialRep:(DSSerialRep *)serialRep;

- (Class) typeClass;

- (id) valueForAttribute:(NSString *)attrName;
- (NSDictionary *) dataForAttribute:(NSString *)attrName;
- (id) metaData:(NSString *)key forAttribute:(NSString *)attrName;

- (NSObject *) valueForKey:(NSString *)key;

+ (DSVersion *) versionWithSerialRep:(DSSerialRep *)serialRep;
+ (DSVersion *) blankVersionWithKey:(DSKey *)key;

- (BOOL) isEqualToVersion:(DSVersion *)version;

@end


@interface DSSerialRep (Version)
- (BOOL) isValidVersionRepresentation;
@end

