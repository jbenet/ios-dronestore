//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//

#import <pthread.h>
#import "DSDatabase.h"
#import <iDrone/DSModel.h>
#import <iDrone/DSQuery.h>
#import <iDrone/DSCollection.h>
#import "DSCache.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import <YAJL/YAJL.h>

static NSString *kDSSQLITE_FILE = @"ds.%@.sqlite";
static NSString *kQ_TABLE = @"SELECT name FROM sqlite_master WHERE name=?";

static NSString *kCREATE_ENTITIES = @"CREATE TABLE IF NOT EXISTS ds_entities ("
"  ds_key_ TEXT PRIMARY KEY,"
"  ds_type_ TEXT,"
"  ds_owner_ TEXT,"
"  ds_created_ NUMERIC,"
"  ds_updated_ NUMERIC,"
"  ds_expire_ NUMERIC,"
"  ds_access_ INTEGER,"
"  dso_lease_ INTEGER,"
"  dso_backup_ TEXT,"
"  dso_backupx_ TEXT,"
"  serialized TEXT"
");";

static NSString *kCREATE_JOURNAL = @"CREATE TABLE IF NOT EXISTS ds_journal ("
"  call TEXT,"
"  serial TEXT,"
"  created NUMERIC"
");";

static NSString *kSELECT_ENTITY = @"SELECT * FROM ds_entities WHERE ds_key_ = ?";
static NSString *kUPDATE_ENTITY = @"UPDATE ds_entities SET \
 ds_owner_ = ?, ds_created_ = ?, ds_updated_ = ?, ds_expire_ = ?,\
 ds_type_ = ?, ds_access_ = ?, dso_lease_ = ?, dso_backup_ = ?,\
 dso_backupx_= ?, serialized = ? WHERE ds_key_ = ?;";
static NSString *kINSERT_ENTITY = @"INSERT INTO ds_entities (ds_key_) VALUES (?);";

static NSString *kQUERY_ENTITIES = @"SELECT * FROM ds_entities WHERE %@";


@implementation DSDatabase

@synthesize name, drone;

#pragma mark Initializing

- (id) initWithName:(NSString *)name_ andDrone:(DSDrone *)drone_;
{
  if (self = [super init]) {
    name = [name_ copy];
    pthread_mutex_init(&fmdb_lock, NULL);
    [self initializeDatabase];
    cache = [[DSCache alloc] init];
    drone = drone_;
  }
  return self;
}

- (void) dealloc
{
  [cache release];
  [fmdb release];
  [name release];
  drone = nil;
  pthread_mutex_destroy(&fmdb_lock);
  [super dealloc];
}

//------------------------------------------------------------------------------

- (void) upkeep {
  [cache collectGarbage];
}

//------------------------------------------------------------------------------

- (BOOL) tableExists:(NSString *)table
{
  pthread_mutex_lock(&fmdb_lock);
  FMResultSet *rs = [fmdb executeQuery:kQ_TABLE, table];

  bool exists = [rs next];
  [rs close];

  pthread_mutex_unlock(&fmdb_lock);
  return exists;
}

- (void) initializeDatabase
{
  pthread_mutex_lock(&fmdb_lock);

  fmdb = [[FMDatabase alloc] initWithPath:[DSDatabase pathForName:name]];
  fmdb.logsErrors = YES;
  [fmdb setBusyRetryTimeout:10];
//  fmdb.traceExecution = YES;

  if (![fmdb open])
    NSLog(@"DS_ERROR: error opening sqlite database.");

  pthread_mutex_unlock(&fmdb_lock);

  BOOL entities_exists = [self tableExists:@"ds_entities"];
  BOOL journal_exists = [self tableExists:@"ds_journal"];

  pthread_mutex_lock(&fmdb_lock);

  if (!entities_exists)
    [fmdb executeUpdate:kCREATE_ENTITIES];

  if (!journal_exists)
    [fmdb executeUpdate:kCREATE_JOURNAL];

  pthread_mutex_unlock(&fmdb_lock);
  //FIXME Error code checks...
}

//------------------------------------------------------------------------------

- (id) modelForKey: (NSString *)key
{
  return [self modelForKey:key withClass:nil];
}

- (id) modelForKey: (NSString *)key withClass:(Class)modelClass
{
  DSModel *model = [cache modelForKey:key];
  if (model != nil)
    return model;

  [key retain];
  pthread_mutex_lock(&fmdb_lock);
  FMResultSet *rs = [fmdb executeQuery:kSELECT_ENTITY, key];
  [key release];

  if (![rs next]) {
    [rs close];
    pthread_mutex_unlock(&fmdb_lock);
    return nil;
  }

  if (modelClass == nil || modelClass == NULL)
    modelClass = NSClassFromString([rs stringForColumn:@"ds_type_"]);

  NSString *json = [rs stringForColumn:@"serialized"];
  [rs close];

  pthread_mutex_unlock(&fmdb_lock);

  model = [[modelClass alloc] initWithDrone: drone];
  [model loadDict:[json yajl_JSON]];
  [cache insertModel:model];
  return [model autorelease];
}

//------------------------------------------------------------------------------

- (BOOL) _saveModel:(DSModel *)model
{
  NSDictionary *dict = [model toDict];

  pthread_mutex_lock(&fmdb_lock);

  [fmdb executeUpdate:kUPDATE_ENTITY, [model ds_owner_],
    [model ds_created_], [model ds_updated_], [model ds_expire_],
    NSStringFromClass([model class]), [model ds_access_],
    [model dso_lease_], [model dso_backup_], [model dso_backupx_],
    [dict yajl_JSONString], [model ds_key_]];

  if ([fmdb changes] > 1)
    NSLog(@"DS_ERROR: Update to _saveModel modified more than one row.");

  bool success = ![fmdb hadError] && [fmdb changes] > 0;

  pthread_mutex_unlock(&fmdb_lock);

  [cache insertModel:model];
  return success;
}

- (BOOL) saveModel:(DSModel *)model
{
  if (![self _saveModel:model])
    return [self insertModel:model];

  //FIXME otherQueryProperties
  return YES;
}

- (BOOL) cacheModel:(DSModel *)model
{
  [cache insertModel:model];
  return YES;
}

- (BOOL) insertModel:(DSModel *)model
{
  pthread_mutex_lock(&fmdb_lock);
  [fmdb executeUpdate:kINSERT_ENTITY, [model ds_key_]];
  pthread_mutex_unlock(&fmdb_lock);

  //FIXME otherQueryProperties
  return [self _saveModel:model];
}

- (BOOL) loadModel:(DSModel *)model
{
  NSString *dskey = [[model ds_key_] retain];
  pthread_mutex_lock(&fmdb_lock);
  FMResultSet *rs = [fmdb executeQuery:kSELECT_ENTITY, dskey];
  [dskey release];

  if (![rs next]) {
    [rs close];
    pthread_mutex_unlock(&fmdb_lock);
    return NO;
  }
  NSString *json = [rs stringForColumn:@"serialized"];
  [rs close];

  pthread_mutex_unlock(&fmdb_lock);

  [model loadDict:[json yajl_JSON]];
  [cache insertModel:model];
  return YES;
}

//------------------------------------------------------------------------------

- (void) runQuery:(DSQuery *)query {
  [query retain];
  NSMutableArray *arguments = [[NSMutableArray array] retain];
  NSString *where = [query SQLWhereWithArguments:arguments];
  NSString *sql = [[NSString stringWithFormat:kQUERY_ENTITIES, where] retain];

  pthread_mutex_lock(&fmdb_lock);
  FMResultSet *rs = [fmdb executeQuery:sql withArgumentsInArray:arguments];
  [sql release];

  while ([rs next]) {
    NSString *key = [rs stringForColumn:@"ds_key_"];
    if (query.keysOnly) {
      [query.keys addObject:key];
      continue;
    }
    Class modelClass = NSClassFromString([rs stringForColumn:@"ds_type_"]);
    NSString *json = [rs stringForColumn:@"serialized"];

    pthread_mutex_unlock(&fmdb_lock);

    DSModel *model = [[cache modelForKey:key] retain];
    if (model == nil) {
      model = [[modelClass alloc] initWithDrone:drone];
      model.ds_key_ = key;
      [cache insertModel:model];
    }
    NSDictionary *dict = [[json yajl_JSON] retain];
    [model loadDict:dict];
    [dict release];
    [query.models insertModel:model];
    [model release];

    pthread_mutex_lock(&fmdb_lock);
  }
  [rs close];
  pthread_mutex_unlock(&fmdb_lock);

  [arguments release];
  [query queryRanWithCallback:nil];
  [query autorelease];
}

//------------------------------------------------------------------------------

- (NSDictionary *) dictFromResult:(FMResultSet *)rs
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:9];
  [dict setObject:[rs stringForColumn:@"ds_key_"] forKey:@"ds_key_"];
  [dict setObject:[rs stringForColumn:@"ds_owner_"] forKey:@"ds_owner_"];
  [dict setObject:[rs stringForColumn:@"ds_created_"] forKey:@"ds_created_"];
  [dict setObject:[rs stringForColumn:@"ds_updated_"] forKey:@"ds_updated_"];
  [dict setObject:[rs stringForColumn:@"ds_expire_"] forKey:@"ds_expire_"];
  [dict setObject:[NSNumber numberWithInt:[rs intForColumn:@"ds_access_"]] forKey:@"ds_access_"];
  [dict setObject:[NSNumber numberWithInt:[rs intForColumn:@"dso_lease_"]] forKey:@"dso_lease_"];
  [dict setObject:[rs stringForColumn:@"dso_backup_"] forKey:@"dso_backup_"];
  [dict setObject:[rs stringForColumn:@"dso_backupx_"] forKey:@"dso_backupx_"];
  return dict;
}

// - (NSArray *) modelsForQuery:(DSQuery *)query
// {
//   NSString *query = [NSString stringWithFormat:kQUERY_ENTITIES, [query sql]];
//   FMResultSet *rs = [fmdb executeQuery:query];
//   NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
//   Class model = NSClassFromString([query type]);
//
//   while (![rs next]) {
//     model entity = [[model alloc] init];
//     [model fromDict:[self dictFromResult:rs]];
//     [cache insertModel:entity];
//     [result insertModel:entity];
//     [entity release];
//   }
//   return result;
// }

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
  [fileManager removeItemAtPath:[DSDatabase pathForName:name] error:NULL];
}

+ (DSDatabase *) databaseWithName:(NSString *)name_ andDrone:(DSDrone *)drone_
{
  return [[[DSDatabase alloc] initWithName:name_ andDrone:drone_] autorelease];
}

@end


