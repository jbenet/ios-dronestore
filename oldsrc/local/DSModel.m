//
// iDrone -- Cocoa Drone
// Implementation of the DroneStore protocol
//
// @author jbenet@cs.stanford.edu
//


#import <iDrone/DSDrone.h>
#import <iDrone/DSModel.h>

#define kDS_MODEL_LEASE_SECONDS 1000
#define CMPCLIP(a) (a == 0 ? 0 : (a > 0 ? 1 : -1))
@implementation DSModel

@synthesize ds_key_, ds_owner_, ds_created_, ds_updated_, ds_expire_;
@synthesize ds_access_, dso_lease_, dso_backup_, dso_backupx_;
@synthesize dirty, drone;

//------------------------------------------------------------------------------
#pragma mark -- Initializing --

- (id) initWithDrone:(DSDrone *)drone_
{
  if (self = [super init])
  {
    self.dirty = YES;
    drone = drone_;
    if (drone == nil && [DSDrone mainDrone] != nil)
      drone = [DSDrone mainDrone];
    [self modelInit];
  }
  return self;
}

- (id) initNew
{
  return [self initNewWithDrone:[DSDrone mainDrone]];
}

- (id) initNewWithDrone:(DSDrone *)drone_
{
  if (self = [self initWithDrone:drone_])
  {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *lowercase = [(NSString *)string lowercaseString];
    NSString *lo = [lowercase substringToIndex:32];
    CFRelease(string);

    self.ds_key_= [lo stringByReplacingOccurrencesOfString:@"-" withString:@""];
    self.ds_owner_ = drone_.droneid;
    self.dso_lease_ = [NSNumber numberWithInt:kDS_MODEL_LEASE_SECONDS];
    self.ds_created_ = [drone_ systemDate];
    self.dirty = YES;

    [[lo retain] release];
    [[lowercase retain] release];
  }
  return self;
}

- (id) initWithKey:(NSString *)key
{
  return [self initWithKey:key andDrone:nil];
}

- (id) initWithKey:(NSString *)key andDrone:(DSDrone *)drone_
{
  if (self = [self initWithDrone:drone_]) {
    self.ds_key_ = key;
    self.dirty = NO;

    id model = [drone modelForKey:key];
    if (model != nil && model != self) {
      [self release];
      self = [model retain];
    }
    [self load];

    if (self.ds_owner_ == nil)
      self.ds_owner_ = drone.droneid;
  }
  return self;
}

- (void) modelInit {
}

//------------------------------------------------------------------------------
#pragma mark -- Util --

- (NSUInteger) hash {
  return [self.ds_key_ hash];
}

- (BOOL) isEqual:(DSModel *)other
{
  return [self.ds_key_ isEqualToString:other.ds_key_];
}

- (BOOL) hasExpired
{
  if (self.ds_expire_ == nil)
    return NO; //FIXME YES?

  return [self.ds_expire_ timeIntervalSinceNow] < 0;
}

- (NSString *) ds_type_ {
  return NSStringFromClass([self class]);
}

+ (NSString *) ds_type_ {
  return NSStringFromClass(self);
}

- (BOOL) invariantsHold {
  if (!ds_key_ || [ds_key_ length] < 1)
    return NO;
  return YES;
}

+ (Class) classFromType:(NSString *)ds_type_ {
  Class modelClass = nil;
  if (ds_type_ != nil)
    modelClass = NSClassFromString(ds_type_);
  if (modelClass == nil)
    modelClass = [DSModel class];
  return modelClass;
}

#pragma mark -- Storing --

- (BOOL) load {
  [self cache];
  return [drone loadModel:self];
}

- (BOOL) save {
  self.ds_updated_ = [drone systemDate];
  [self cache];
  return [drone saveModel:self];
}

- (BOOL) cache {
  return [drone cacheModel:self];
}

- (BOOL) delete {
  return NO;
}

- (BOOL) loadRemote {
  [self cache];
  return [drone loadModel:self local:NO remote:YES];
}

- (BOOL) saveRemote {
  [self cache];
  return [drone saveModel:self local:NO remote:YES];
}

- (BOOL) loadLocal {
  [self cache];
  return [drone loadModel:self local:YES remote:NO];
}

- (BOOL) saveLocal {
  [self cache];
  return [drone saveModel:self local:YES remote:NO];
}

//------------------------------------------------------------------------------
#pragma mark -- Sorting --

- (int) keyCompare:(DSModel *)other
{
  return CMPCLIP([self.ds_key_ compare:other.ds_key_]);
}

- (int) createdCompare:(DSModel *)other
{
  return CMPCLIP([self.ds_created_ timeIntervalSinceDate:other.ds_created_]);
}

- (int) updatedCompare:(DSModel *)other
{
  return CMPCLIP([self.ds_updated_ timeIntervalSinceDate:other.ds_updated_]);
}

//------------------------------------------------------------------------------
#pragma mark -- Serializing --

- (id) JSON {
  return [self toDict];
}

+ (id) modelFromDict:(NSDictionary *)dict {
  return [self modelFromDict:dict andDrone:nil];
}

+ (id) modelFromDict:(NSDictionary *)dict andDrone:(DSDrone *)drone {
  if (drone == nil)
    drone = [DSDrone mainDrone];

  NSString *key = [dict valueForKey:@"ds_key_"];
  id model = [drone modelForKey:key local:YES remote:NO];
  if (model == nil) {
    Class modelClass = [self classFromType:[dict valueForKey:@"ds_type_"]];
    model = [[[modelClass alloc] initWithKey:key andDrone:drone] autorelease];
  }
  [model loadDict:dict];
  return model;
}

- (void) loadDict:(NSDictionary *)dict {
  NSDate *date = nil;

  self.ds_key_ = [dict valueForKey:@"ds_key_"];
  self.ds_owner_ = [dict valueForKey:@"ds_owner_"];

  date = [drone dateFromString:[dict valueForKey:@"ds_created_"]];
  if (date)
    self.ds_created_ = date;

  date = [drone dateFromString:[dict valueForKey:@"ds_updated_"]];
  if (date)
    self.ds_updated_ = date;

  date = [drone dateFromString:[dict valueForKey:@"ds_expire_"]];
  if (date)
    self.ds_expire_ = date;

  self.ds_access_ = [dict valueForKey:@"ds_access_"];

  self.dso_lease_ = [dict valueForKey:@"dso_lease_"];
  self.dso_backup_ = [dict valueForKey:@"dso_backup_"];
  self.dso_backupx_ = [dict valueForKey:@"dso_backupx_"];
}

- (NSMutableDictionary *) toDict {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
  [dict setValue: self.ds_key_ forKey:@"ds_key_"];
  [dict setValue: NSStringFromClass([self class]) forKey:@"ds_type_"];
  if (self.ds_owner_ != nil)
    [dict setValue: self.ds_owner_ forKey:@"ds_owner_"];
  if (self.ds_created_ != nil)
    [dict setValue: [drone stringFromDate:ds_created_] forKey:@"ds_created_"];
  if (self.ds_updated_ != nil)
    [dict setValue: [drone stringFromDate:ds_updated_] forKey:@"ds_updated_"];
  if (self.ds_expire_ != nil)
    [dict setValue: [drone stringFromDate:ds_expire_] forKey:@"ds_expire_"];
  if (self.ds_access_ != nil)
    [dict setValue: self.ds_access_ forKey:@"ds_access_"];

  if (self.dso_lease_ != nil)
    [dict setValue: self.dso_lease_ forKey:@"dso_lease_"];
  if (self.dso_backup_ != nil)
    [dict setValue: self.dso_backup_ forKey:@"dso_backup_"];
  if (self.dso_backupx_ != nil)
    [dict setValue: self.dso_backupx_ forKey:@"dso_backupx_"];
  return dict;
}

//------------------------------------------------------------------------------

- (void) loadData:(NSData *)data {
  NSString *json;
  json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [self loadDict:[json yajl_JSON]];
  [json release];
}

+ (id) modelFromData:(NSData *)data {
  return [self modelFromData:data andDrone:nil];
}

+ (id) modelFromData:(NSData *)data andDrone:(DSDrone *)drone {
  NSString *json;
  json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  id model = [self modelFromDict:[json yajl_JSON] andDrone:drone];
  [json release];
  return model;
}

- (NSData *) data {
  return [[self yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
}

//------------------------------------------------------------------------------

- (NSString *) description {
  return [[self toDict] yajl_JSONString];
}

+ (NSDictionary *) otherQueriableProperties {
  return nil;
}

//------------------------------------------------------------------------------

+ (id) modelForKey:(NSString *)key
{
  return [self modelForKey:key andDrone:nil];
}

+ (id) modelForKey:(NSString *)key andDrone:(DSDrone *)drone
{
  if (drone == nil)
    drone = [DSDrone mainDrone];
  return [drone modelForKey:key];
}

//------------------------------------------------------------------------------


- (void) dealloc
{
  self.ds_key_ = nil;
  self.ds_owner_ = nil;
  self.ds_created_ = nil;
  self.ds_updated_ = nil;
  self.ds_expire_ = nil;
  self.ds_access_ = nil;
  self.dso_lease_ = nil;
  self.dso_backup_ = nil;
  self.dso_backupx_ = nil;
  // [drone release]; // not retained.
  [super dealloc];
}

@end
