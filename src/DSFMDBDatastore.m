
#import "DSFMDBDatastore.h"

#import "iDrone.h"
#import <pthread.h>
#import "FMDatabase.h"
#import "FMResultSet.h"
#import <bson-objc/BSONCodec.h>

static NSString *kDSSQLITE_FILE = @"ds.%@.sqlite";
static NSString *kQ_TABLE = @"SELECT name FROM sqlite_master WHERE name=?";

static NSString *kCREATE_VERSIONS = @"CREATE TABLE IF NOT EXISTS ds_versions ("
"  key TEXT PRIMARY KEY,"
"  hash TEXT,"
"  parent TEXT,"
"  type NUMERIC,"
"  committed NUMERIC,"
"  created NUMERIC,"
"  attributes TEXT"
");";


static NSString *kSELECT_VERSION = @"SELECT * FROM ds_versions WHERE key = ?;";

static NSString *kQUERY_VERSION = @"SELECT * FROM ds_versions WHERE %@;";

static NSString *kINSERT_VERSION = @"INSERT INTO ds_versions (key) VALUES (?);";

static NSString *kCOUNT_VERSION = @"SELECT COUNT(*) as cnt FROM ds_versions \
 WHERE key = ?;";

static NSString *kDELETE_VERSION = @"DELETE FROM ds_versions WHERE key = ?;";

static NSString *kUPDATE_VERSION = @"UPDATE ds_versions SET \
 hash = ?, parent = ?, type = ?, committed = ?, created = ?, attributes = ? \
 WHERE key = ?;";


static NSString *kCREATE_KV = @"CREATE TABLE IF NOT EXISTS ds_kv ("
"  k TEXT PRIMARY KEY,"
"  v BLOB"
");";


static NSString *kSELECT_KV = @"SELECT * FROM ds_kv WHERE k = ?;";
static NSString *kQUERY_KV = @"SELECT * FROM ds_kv WHERE %@;";
static NSString *kINSERT_KV = @"INSERT INTO ds_kv (k) VALUES (?);";
static NSString *kCOUNT_KV = @"SELECT COUNT(*) as cnt FROM ds_kv WHERE k = ?;";
static NSString *kDELETE_KV = @"DELETE FROM ds_kv WHERE k = ?;";
static NSString *kUPDATE_KV = @"UPDATE ds_kv SET v = ? WHERE k = ?;";



//------------------------------------------------------------------------------


@interface DSFMDBDatastore (Private)
- (BOOL) tableExists:(NSString *)table;
- (void) ensureTableExists:(NSString *)table create:(NSString *)create;
- (void) initializeDatabase;
@end

//------------------------------------------------------------------------------
#pragma mark init

@implementation DSFMDBDatastore

@synthesize name;

- (id) initWithName:(NSString *)_name {
  if ((self = [super init])) {
    name = [_name copy];
    pthread_mutex_init(&lock_, NULL);
    [self initializeDatabase];
  }
  return self;
}


- (void) dealloc {
  [fmdb_ release];
  [name release];
  pthread_mutex_destroy(&lock_);
  [super dealloc];
}

//------------------------------------------------------------------------------

- (void) initializeDatabase
{
  pthread_mutex_lock(&lock_);

  fmdb_ = [[FMDatabase alloc] initWithPath:[[self class] pathForName:name]];
  fmdb_.logsErrors = YES;
  [fmdb_ setBusyRetryTimeout:10];
//  fmdb.traceExecution = YES;

  if (![fmdb_ open])
    DSLog(@"fmdb error: failed to open sqlite database.");

  pthread_mutex_unlock(&lock_);

  [self ensureTableExists:@"ds_kv" create:kCREATE_KV];
}

- (BOOL) tableExists:(NSString *)table {
  pthread_mutex_lock(&lock_);

  FMResultSet *rs = [fmdb_ executeQuery:kQ_TABLE, table];
  bool exists = [rs next];
  [rs close];

  pthread_mutex_unlock(&lock_);
  return exists;
}

- (void) ensureTableExists:(NSString *)table create:(NSString *)create {
  pthread_mutex_lock(&lock_);

  FMResultSet *rs = [fmdb_ executeQuery:kQ_TABLE, table];
  bool exists = [rs next];
  [rs close];

  if (!exists)
    [fmdb_ executeUpdate:create];

  pthread_mutex_unlock(&lock_);
}

//------------------------------------------------------------------------------
#pragma mark dbcalls

- (BOOL) __updateData:(NSData *)data forKey:(NSString *)key {
  [data retain];
  [key retain];
  pthread_mutex_lock(&lock_);

  [fmdb_ executeUpdate:kUPDATE_KV, data, key];

  // [fmdb_ executeUpdate:kUPDATE_VERSION, [data valueForKey:@"hash"],
  //   [data valueForKey:@"parent"], [data valueForKey:@"type"],
  //   [data valueForKey:@"committed"], [data valueForKey:@"created"],
  //   [[data valueForKey:@"attributes"] BSONRepresentation], key];

  if ([fmdb_ changes] > 1)
    DSLog(@"fmdb error: update modified more than one row.");

  bool success = ![fmdb_ hadError] && [fmdb_ changes] > 0;

  pthread_mutex_unlock(&lock_);
  [key release];
  [data release];
  return success;
}

- (BOOL) insertData:(NSData *)data forKey:(NSString *)key {
  [data retain];
  [key retain];
  pthread_mutex_lock(&lock_);

  [fmdb_ executeUpdate:kINSERT_KV, key];

  pthread_mutex_unlock(&lock_);

  //FIXME otherQueryProperties
  BOOL success = [self __updateData:data forKey:key];

  [key release];
  [data release];
  return success;
}

- (BOOL) updateData:(NSData *)data forKey:(NSString *)key {
  [data retain];
  [key retain];

  BOOL success = [self __updateData:data forKey:key];
  if (!success)
    success = [self insertData:data forKey:key];

  [key release];
  [data release];
  return success;
}


- (NSData *) selectDataForKey:(NSString *)key {
  [key retain];
  pthread_mutex_lock(&lock_);
  FMResultSet *rs = [fmdb_ executeQuery:kSELECT_KV, key];
  [key release];

  if (![rs next]) {
    [rs close];
    pthread_mutex_unlock(&lock_);
    return nil;
  }

  // NSDictionary *dict = [self dictFromResult:rs];
  NSData *data = [rs dataForColumn:@"v"];
  [rs close];

  pthread_mutex_unlock(&lock_);

  // return dict;
  return data;
}

- (int) countDataForKey:(NSString *)key {
  [key retain];
  pthread_mutex_lock(&lock_);
  FMResultSet *rs = [fmdb_ executeQuery:kCOUNT_KV, key];
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
  [fmdb_ executeUpdate:kDELETE_KV, key];

  [key release];
  pthread_mutex_unlock(&lock_);
}

//------------------------------------------------------------------------------
#pragma mark datasource


- (id) get:(DSKey *)key {
  if (key == nil)
    return nil;

  NSData *data = [self selectDataForKey:key.string];
  // NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *dict = [data BSONValue];
  return [dict valueForKey:@"v"];
}

- (void) put:(NSObject *)object forKey:(DSKey *)key {
  if (object == nil || key == nil)
    return;


  NSDictionary *dict;
  dict = [NSDictionary dictionaryWithObjectsAndKeys:object, @"v", nil];

  NSData *data = [dict BSONRepresentation];

  // NSString *str;
  // str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

  [self updateData:data forKey:key.string];

//  [str release];
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


//------------------------------------------------------------------------------
#pragma mark util

- (NSDictionary *) dictFromResult:(FMResultSet *)rs
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:7];
  [dict setObject:[rs stringForColumn:@"key"] forKey:@"key"];
  [dict setObject:[rs stringForColumn:@"hash"] forKey:@"hash"];
  [dict setObject:[rs stringForColumn:@"parent"] forKey:@"parent"];
  [dict setObject:[rs stringForColumn:@"type"] forKey:@"type"];

  [dict setObject:[NSNumber numberWithInt:[rs intForColumn:@"committed"]]
    forKey:@"committed"];
  [dict setObject:[NSNumber numberWithInt:[rs intForColumn:@"created"]]
    forKey:@"created"];

  [dict setObject:[rs stringForColumn:@"attributes"] forKey:@"attributes"];
  return dict;
}

//------------------------------------------------------------------------------

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