#import "DSDatastore.h"

struct pthread_mutex_t;
@class FMDatabase;

@interface DSFMDBDatastore : DSDatastore {
  NSString *name;

  FMDatabase *fmdb_;
  pthread_mutex_t lock_;
}

@property (nonatomic, readonly) NSString *name;

- (id) initWithName:(NSString *)name;


+ (NSString *) pathForName:(NSString *)name;
+ (void) deleteDatabaseNamed:(NSString *)name;

@end