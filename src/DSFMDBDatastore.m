
#import "DSFMDBDatastore.h"

#import "iDrone.h"
#import <pthread.h>
#import "FMDatabase.h"
#import "FMResultSet.h"
#import <bson-objc/BSONCodec.h>

static NSString *kDSSQLITE_FILE = @"ds.%@.sqlite";
static NSString *kQ_TABLE = @"SELECT name FROM sqlite_master WHERE name=?";

//------------------------------------------------------------------------------


@interface DSFMDBDatastore (Private)
- (BOOL) tableExists:(NSString *)table;
- (void) ensureTableExists:(NSString *)table create:(NSString *)create;
- (void) initializeDatabase;
@end

//------------------------------------------------------------------------------
#pragma mark init

@implementation DSFMDBDatastore

@synthesize schema;

- (id) init {
  [NSException raise:@"DSDatastoreInvalidCreation" format:@"%@ requires a "
    "%@ to be specified.", [self class], [SQLSchema class]];
  return nil;
}

- (id) initWithSchema:(SQLSchema *)_schema {
  if ((self = [super init])) {
    schema = [_schema retain];
    pthread_mutex_init(&lock_, NULL);
    [self initializeDatabase];
  }
  return self;
}


- (void) dealloc {
  [fmdb_ release];
  [schema release];
  pthread_mutex_destroy(&lock_);
  [super dealloc];
}

//------------------------------------------------------------------------------

- (void) initializeDatabase
{
  pthread_mutex_lock(&lock_);

  NSString *path = [[self class] pathForName:schema.table];
  fmdb_ = [[FMDatabase alloc] initWithPath:path];
  fmdb_.logsErrors = YES;
  [fmdb_ setBusyRetryTimeout:10];
//  fmdb.traceExecution = YES;

  if (![fmdb_ open])
    DSLog(@"fmdb error: failed to open sqlite database.");

  pthread_mutex_unlock(&lock_);

  [self ensureTableExists:schema.table create:[schema create]];
}

- (BOOL) tableExists:(NSString *)table {
  pthread_mutex_lock(&lock_);

  FMResultSet *rs = [fmdb_ executeQuery:kQ_TABLE, schema.table];
  bool exists = [rs next];
  [rs close];

  pthread_mutex_unlock(&lock_);
  return exists;
}

- (void) ensureTableExists:(NSString *)table create:(NSString *)create {
  pthread_mutex_lock(&lock_);

  FMResultSet *rs = [fmdb_ executeQuery:kQ_TABLE, schema.table];
  bool exists = [rs next];
  [rs close];

  if (!exists)
    [fmdb_ executeUpdate:create];

  pthread_mutex_unlock(&lock_);
}

//------------------------------------------------------------------------------
#pragma mark dbcalls

- (BOOL) __updateValues:(NSArray *)values forKey:(NSString *)key {
  [values retain];
  [key retain];
  pthread_mutex_lock(&lock_);

  [fmdb_ executeUpdate:[schema update] withArgumentsInArray:values];

  if ([fmdb_ changes] > 1)
    DSLog(@"fmdb error: update modified more than one row.");

  bool success = ![fmdb_ hadError] && [fmdb_ changes] > 0;

  pthread_mutex_unlock(&lock_);
  [key release];
  [values release];
  return success;
}

- (BOOL) insertValues:(NSArray *)values forKey:(NSString *)key {
  [values retain];
  [key retain];
  pthread_mutex_lock(&lock_);

  [fmdb_ executeUpdate:[schema insert], key];

  pthread_mutex_unlock(&lock_);

  //FIXME otherQueryProperties
  BOOL success = [self __updateValues:values forKey:key];

  [key release];
  [values release];
  return success;
}

- (BOOL) updateValues:(NSArray *)values forKey:(NSString *)key {
  [values retain];
  [key retain];

  BOOL success = [self __updateValues:values forKey:key];
  if (!success)
    success = [self insertValues:values forKey:key];

  [key release];
  [values release];
  return success;
}


- (NSDictionary *) selectDataForKey:(NSString *)key {
  [key retain];
  pthread_mutex_lock(&lock_);
  FMResultSet *rs = [fmdb_ executeQuery:[schema select], key];
  [key release];

  if (![rs next]) {
    [rs close];
    pthread_mutex_unlock(&lock_);
    return nil;
  }

  NSDictionary *data = [[schema dictionaryFromResultSet:rs] retain];

  [rs close];
  pthread_mutex_unlock(&lock_);

  return [data autorelease];
}

- (int) countDataForKey:(NSString *)key {
  [key retain];
  pthread_mutex_lock(&lock_);
  FMResultSet *rs = [fmdb_ executeQuery:[schema count], key];
  [key release];

  if (![rs next]) {
    [rs close];
    pthread_mutex_unlock(&lock_);
    return 0;
  }

  int count = [rs intForColumn:@"cnt"];
  [rs close];

  pthread_mutex_unlock(&lock_);
  return count;

}

- (void) deleteDataForKey:(NSString *)key {
  [key retain];
  pthread_mutex_lock(&lock_);

  [fmdb_ executeUpdate:[schema delete], key];

  [key release];
  pthread_mutex_unlock(&lock_);
}

- (NSArray *) runQuery:(NSString *)query {
  [query retain];

  pthread_mutex_lock(&lock_);
  NSMutableArray *result = [[NSMutableArray alloc] init];
  FMResultSet *rs;

  rs = [fmdb_ executeQuery:query];

  while ([rs next]) {
    [result addObject:[schema dictionaryFromResultSet:rs]];
  }

  [rs close];
  pthread_mutex_unlock(&lock_);

  [query release];
  return [result autorelease];
}

//------------------------------------------------------------------------------
#pragma mark datasource interface


- (id) get:(DSKey *)key {
  if (key == nil)
    return nil;

  NSDictionary *result = [self selectDataForKey:key.string];

  // unwrap those that need unwrapping.
  if ([result count] == 1)
    return [[result allValues] objectAtIndex:0];

  return result;
}

- (void) put:(NSObject *)object forKey:(DSKey *)key {
  if (object == nil || key == nil)
    return;

  NSArray *values = [schema updateValuesFromObject:object andKey:key.string];
  [self updateValues:values forKey:key.string];
}

- (void) delete:(DSKey *)key {
  if (key != nil)
    [self deleteDataForKey:key.string];
}

- (BOOL) contains:(DSKey *)key {
  if (key == nil)
    return NO;
  return [self countDataForKey:key.string] > 0;
}

- (NSArray *) query:(DSQuery *)query {
  return [self runQuery:[schema query:query]];
}

//------------------------------------------------------------------------------
#pragma mark util

+ (NSString *) pathForName:(NSString *)name
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *db = [NSString stringWithFormat:kDSSQLITE_FILE, name];
  return [documentsDirectory stringByAppendingPathComponent: db];
}

+ (void) deleteDatabaseNamed:(NSString *)name
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:[self pathForName:name] error:NULL];
}

@end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


@implementation SQLSchema

@synthesize fields, key, table;

- (id) init {
  if ((self = [super init])) {
    fields = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (id) initWithTableName:(NSString *)name {
  if ((self = [self init])) {
    self.table = name;
  }
  return self;
}

- (void) dealloc {
  [fields release];
  [table release];
  [key release];
  [super dealloc];
}

- (void) check {
  if (table == nil || key == nil || [fields count] == 0) {
    [NSException raise:@"DSInvalidTableSchema" format:@"Table Schema requires "
      "at least a table name, key field name, and one other field."];
  }
}

- (NSString *) create {
  [self check];

  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (", table];
  [string appendFormat:@"  %@ TEXT PRIMARY KEY", key];
  for (NSString *field in fields)
    [string appendFormat:@", %@ %@", field, [fields valueForKey:field]];
  [string appendString:@");"];
  NSLog(@"%@", string);
  return string;
}

- (NSString *) select {
  [self check];

  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"SELECT * FROM %@ WHERE %@ = ?;", table, key];
  NSLog(@"%@", string);
  return string;
}

- (NSString *) update {
  [self check];

  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"UPDATE %@ SET ", table];
  BOOL first = YES;
  for (NSString *field in fields) {
    if (!first)
      [string appendString:@","];
    [string appendFormat:@" %@ = ? ", field];
    first = NO;
  }
  [string appendFormat:@" WHERE %@ = ?;", key];
  NSLog(@"%@", string);
  return string;
}


- (NSString *) insert {
  [self check];

  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"INSERT INTO %@ ", table];
  [string appendFormat:@"(%@) VALUES (?);", key];
  NSLog(@"%@", string);
  return string;
}

- (NSString *) delete {
  [self check];

  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"DELETE FROM %@ ", table];
  [string appendFormat:@"WHERE %@ = ?;", key];
  NSLog(@"%@", string);
  return string;
}

- (NSString *) count {
  [self check];

  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"SELECT count(*) as cnt FROM %@ ", table];
  [string appendFormat:@"WHERE %@ = ?;", key];
  NSLog(@"%@", string);
  return string;
}

- (NSString *) query:(DSQuery *)query {
  [self check];

  return [query SQLQueryWithTable:table];
}

- (NSObject *) objectForField:(NSString *)fld fromResultSet:(FMResultSet *)rs {
  NSString *type = [fields valueForKey:fld];

  if ([type isEqualToString:@"TEXT"])
    return [rs stringForColumn:fld];

  if ([type isEqualToString:@"INTEGER"])
    return [NSNumber numberWithLongLong:[rs longLongIntForColumn:fld]];

  if ([type isEqualToString:@"REAL"])
    return [NSNumber numberWithDouble:[rs doubleForColumn:fld]];

  if ([type isEqualToString:@"NUMERIC"])
    return [NSNumber numberWithDouble:[rs doubleForColumn:fld]];

  if ([type isEqualToString:@"BLOB"])
    return [rs dataForColumn:fld];

  return nil;
}

- (NSDictionary *) dictionaryFromResultSet:(FMResultSet *)rs {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  for (NSString *field in fields) {
    NSObject *object = [self objectForField:field fromResultSet:rs];
    [dict setValue:object forKey:field];
  }
  return [dict autorelease];
}

- (NSArray *) updateValuesFromObject:(NSObject *)object andKey:(NSString *)_k {
  if ([fields count] == 1)
    return [NSArray arrayWithObjects:object, _k, nil];

  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (NSString *field in fields)
    [array addObject:[object valueForKey:field]];
  [array addObject:_k];
  return [array autorelease];
}

+ (SQLSchema *) simpleTableNamed:(NSString *)table {
  SQLSchema *schema = [[SQLSchema alloc] init];
  schema.table = table;
  schema.key = @"k";
  [schema.fields setValue:@"TEXT" forKey:@"v"];
  return [schema autorelease];
}

+ (SQLSchema *) versionTableNamed:(NSString *)table {
  SQLSchema *schema = [[SQLSchema alloc] init];
  schema.table = table;
  schema.key = @"key";
  [schema.fields setValue:@"TEXT" forKey:@"type"];
  [schema.fields setValue:@"TEXT" forKey:@"hash"];
  [schema.fields setValue:@"TEXT" forKey:@"parent"];
  [schema.fields setValue:@"INTEGER" forKey:@"created"];
  [schema.fields setValue:@"INTEGER" forKey:@"committed"];
  [schema.fields setValue:@"TEXT" forKey:@"attributes"];
  return [schema autorelease];
}

@end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

@implementation DSQuery (SQL)

- (NSString *) SQLQueryWithTable:(NSString *)table {
  NSMutableString *string = [[NSMutableString alloc] init];

  // Add the select clause
  [string appendFormat:@"SELECT * FROM %@ ", table];

  // Add the WHERE clause
  if ([filters count] > 0) {
    BOOL first = YES;
    for (DSFilter *filter in filters) {
      [string appendString:(first ? @"WHERE " : @",")];
      [string appendFormat:@" %@ %@ %@ ", filter.field, filter.op, filter.value];
      first = NO;
    }
  }

  // Add the ORDER BY clause
  if ([orders count] > 0) {
    BOOL first = YES;
    for (DSOrder *order in orders) {
      [string appendString:(first ? @" ORDER BY " : @",")];
      [string appendFormat:@" %@ ", order.field];
      [string appendString:(order.isAscending ? @"ASC " : @"DESC ")];
      first = NO;
    }
  }

  // Add the limit clause
  if (limit > 0)
    [string appendFormat:@" LIMIT %d ", limit];

  // Add the offset clause
  if (offset > 0)
    [string appendFormat:@" OFFSET %d ", offset];

  // Close the query
  [string appendString:@";"];

  NSLog(@"%@", string);
  return [string autorelease];
}

@end
