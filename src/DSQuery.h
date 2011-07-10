
#import <Foundation/Foundation.h>

// A Query describes a set versions.
//
// Queries are used to retrieve versions and instances matching a set of
// criteria from Datastores and Drones. Query objects themselves are simply
// descriptions, the actual implementations are left up to the Datastores.
//

@class DSKey;
@class DSModel;
@class DSCollection;
@protocol DSComparable;

typedef NSString DSCompOp;

extern DSCompOp *DSCompOpGreaterThanOrEqual;
extern DSCompOp *DSCompOpGreaterThan;
extern DSCompOp *DSCompOpLessThanOrEqual;
extern DSCompOp *DSCompOpLessThan;
extern DSCompOp *DSCompOpEqual;
extern DSCompOp *DSCompOpNotEqual;

@interface DSFilter : NSObject {
  NSString *field;
  DSCompOp *op;
  NSObject<DSComparable> *value;
}
@property (nonatomic, copy) NSString *field;
@property (nonatomic, copy) DSCompOp *op;
@property (nonatomic, copy) NSObject<DSComparable> *value;

- (BOOL) objectPasses:(NSObject *)object;
- (BOOL) valuePasses:(id<DSComparable>)value;
+ (DSFilter *) filter:(NSString *)field op:(DSCompOp *)op value:(NSObject *)val;

+ (NSArray *) filteredArray:(NSArray *)array withFilters:(NSArray *)filters;

- (NSArray *) array;
+ (DSFilter *) filterWithArray:(NSArray *)array;

@end




typedef NSString DSOrderOp;

extern DSOrderOp *DSOrderOpAscending;
extern DSOrderOp *DSOrderOpDescending;

@interface DSOrder : NSSortDescriptor {
  NSString *field;
  DSOrderOp *op;
}
@property (nonatomic, readonly) NSString *field;
@property (nonatomic, readonly) DSOrderOp *op;

- (id) initWithField:(NSString *)order op:(DSOrderOp *)op;

- (NSArray *) sortedArray:(NSArray *)array;
+ (DSOrder *) order:(NSString *)field op:(DSOrderOp *)op;

+ (NSArray *) sortedArray:(NSArray *)array withOrders:(NSArray *)orders;

- (NSString *) string;
+ (DSOrder *) orderWithString:(NSString *)order;
@end





@interface DSQuery : NSObject {
  NSString *type;
  int limit;
  int offset;
  BOOL keysonly;
  NSMutableArray *filters;
  NSMutableArray *orders;
}

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSArray *filters;
@property (nonatomic, readonly) NSArray *orders;
@property (nonatomic, assign) int limit;
@property (nonatomic, assign) int offset;
@property (nonatomic, assign) BOOL keysonly;

- (id) initWithModel:(DSModel *)model;
- (id) initWithType:(NSString *)type;

- (Class) typeClass;

- (NSArray *) operateOnArray:(NSArray *)array;

- (void) addOrder:(DSOrder *)order;
- (void) addFilter:(DSFilter *)filter;

- (NSDictionary *) dictionary;
+ (DSQuery *) queryWithDictionary:(NSDictionary *)dictionary;

@end



