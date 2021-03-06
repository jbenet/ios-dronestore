
#import <Foundation/Foundation.h>

// A key represents the unique identifier of an object.
// Our key scheme is inspired by the Google App Engine key model.
//
// It is meant to be unique across a system. Note that keys are hierarchical,
// objects can be deemed the 'children' of other objects. It is also strongly
// encouraged to include the 'type' of the object in the key path.
//
// For example:
//   Key('/ComedyGroup/MontyPython')
//   Key('/ComedyGroup/MontyPython/Comedian/JohnCleese')

#ifndef NSStringFmt
#define NSStringFmt(fmt, ...) ([NSString stringWithFormat:fmt, __VA_ARGS__])
#endif

#ifndef DSKey
#define DSKey(string) ([DSKey keyWithString:string])
#endif

#ifndef DSKeyFmt
#define DSKeyFmt(...) ([DSKey keyWithString:NSStringFmt(__VA_ARGS__)])
#endif


@interface DSKey : NSObject {
  NSString *string;
}

@property (nonatomic, readonly) NSString *string;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) DSKey *parent;

- (id) initWithString:(NSString *)string;

- (DSKey *) childWithString:(NSString *)child;
- (DSKey *) childWithKey:(DSKey *)key;

- (BOOL) isAncestorOfKey:(DSKey *)key;
- (BOOL) isTopLevelKey;

- (NSString *) hashString;
- (NSArray *) components;

- (BOOL) isEqualToKey:(DSKey *)key;
- (NSComparisonResult) compare:(DSKey *)key;

+ (DSKey *) keyWithString:(NSString *)string;

@end



@interface NSString (Pathing)
- (NSString *) stringByRemovingDuplicateSlashes;
- (NSString *) absolutePathString;
@end
