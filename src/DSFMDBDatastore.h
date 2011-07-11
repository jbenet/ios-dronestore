#import "DSDatastore.h"
#import "DSQuery.h"

struct pthread_mutex_t;
@class FMDatabase;
@class FMResultSet;


@interface SQLSchema : NSObject {
  NSMutableDictionary *fields;
  NSString *key;
  NSString *table;
  NSString *wrappedValue;
}

@property (nonatomic, readonly) NSMutableDictionary *fields;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *table;
@property (nonatomic, copy) NSString *wrappedValue;

- (id) initWithTableName:(NSString *)name;

- (NSString *) create;
- (NSString *) select;
- (NSString *) update;
- (NSString *) insert;
- (NSString *) delete;
- (NSString *) count;
- (NSString *) query:(DSQuery *)query;

- (NSDictionary *) dictionaryFromResultSet:(FMResultSet *)rs;
- (NSArray *) updateValuesFromObject:(NSObject *)object andKey:(NSString *)key;

+ (SQLSchema *) simpleTableNamed:(NSString *)table;
+ (SQLSchema *) versionTableNamed:(NSString *)table;
@end




@interface DSFMDBDatastore : DSDatastore {
  SQLSchema *schema;

  FMDatabase *fmdb_;
  pthread_mutex_t lock_;
}

@property (nonatomic, readonly) SQLSchema *schema;

- (id) initWithSchema:(SQLSchema *)schema;


+ (NSString *) pathForName:(NSString *)name;
+ (void) deleteDatabaseNamed:(NSString *)name;

@end

@interface DSQuery (SQL)
- (NSString *) SQLQueryWithTable:(NSString *)table;
@end