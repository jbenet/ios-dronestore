
#import "DSMerge.h"
#import "DSModel.h"
#import "DSVersion.h"
#import "DSAttribute.h"


@implementation DSMerge

+ (void) mergeInstance:(DSModel *)instance withVersion:(DSVersion *)version {

  if (!instance.isCommitted) {
    [NSException raise:@"DSMergeInvalid" format:@"Cannot merge an uncommitted"
      " instance. Commit changes first, then merge."];
  }

  NSDictionary *attrs = [[instance class] attributes];
  NSMutableDictionary *mergeData = [[NSMutableDictionary alloc] init];
  NSDictionary *data = nil;

  for (DSAttribute *attr in [attrs allValues]) {
    data = [attr.strategy mergeLocal:instance.version withRemote:version];
    if (data) { // did not merge anything
      [mergeData setValue:data forKey:attr.name];
    }
  }

  // Only merge it in if everything went ok.
  for (NSString *attrName in mergeData) {
    data = [mergeData valueForKey:attrName];
    DSAttribute *attr = [attrs valueForKey:attrName];
    [attr setData:data forInstance:instance];
  }

  [instance commit];
}

@end



@implementation DSMergeStrategy

@synthesize attribute;

- (id) initWithAttribute:(DSAttribute *)_attribute {
  if ((self = [super init])) {
    attribute = _attribute; // weak.
  }
  return self;
}

- (void) dealloc {
  // [attribute release]; weak.
  [super dealloc];
}

// Merges two versions
- (NSDictionary *) mergeLocal:(DSVersion *)local withRemote:(DSVersion *)remote{
  [NSException raise:@"NotImplementedError" format:@"Strategy %@ "
   "does not implement required @selector(mergeLocal:withRemote:)."];

  return nil;
}

// Notify that an attribute changed to change any relevant state.
- (void) setValue:(id)value forInstance:(DSModel *)instance {
  // default impl: do nothing.
}

- (void) setDefaultValue:(id)value forInstance:(DSModel *)instance {
  // default impl: do nothing.
}


+ (id) strategy {
  return [[[[self class] alloc] init] autorelease];
}

@end


@implementation DSLatestObjectMergeStrategy
// Merges two versions
- (NSDictionary *) mergeLocal:(DSVersion *)local withRemote:(DSVersion *)remote{

  if (remote.committed.ns > local.committed.ns)
    return [remote dataForAttribute:attribute.name];
  return nil;
}
@end



@implementation DSLatestMergeStrategy
// Merges two versions
- (NSDictionary *) mergeLocal:(DSVersion *)local withRemote:(DSVersion *)remote{

  NSDictionary *remote_data = [remote dataForAttribute:attribute.name];
  NSDictionary *local_data = [local dataForAttribute:attribute.name];

  NSNumber *remote_nt = [remote_data valueForKey:@"updated"];
  NSNumber *local_nt = [local_data valueForKey:@"updated"];

  // if no timestamp found in remote. we're done!
  if (remote_nt == nil)
    return nil;

  // since other side has a timestamp, if we don't, take theirs.
  if (local_nt == nil)
    return remote_data;

  // if we havent decided (both have timestamps), compare timestamps
  if ([remote_nt compare:local_nt] == NSOrderedDescending)
    return remote_data;

  // not updated sooner. keep local.
  return nil;
}

- (void) setValue:(id)value forInstance:(DSModel *)instance {
  NSMutableDictionary *data = [instance mutableDataForAttribute:attribute.name];

  id<DSComparable> curr = [data valueForKey:@"value"];
  id<DSComparable> prev = [instance.version valueForAttribute:attribute.name];
  if (curr && prev && [curr compare:prev] == NSOrderedSame)
    return; // value has not changed. no need to update.

  // store our extra state.
  NSNumber *now = [NSNumber numberWithLongLong:nanotime_now().ns];
  [data setValue:now forKey:@"updated"];
}

- (void) setDefaultValue:(id)value forInstance:(DSModel *)instance {
  // initialize updated to 0 so default values dont seem "newer"
  NSMutableDictionary *data = [instance mutableDataForAttribute:attribute.name];
  [data setValue:[NSNumber numberWithLongLong:0] forKey:@"updated"];
}

@end



@implementation DSMaxMergeStrategy
// Merges two versions
- (NSDictionary *) mergeLocal:(DSVersion *)local withRemote:(DSVersion *)remote{

  id<DSComparable> local_value = [local valueForAttribute:attribute.name];
  id<DSComparable> remote_value = [remote valueForAttribute:attribute.name];

  if ([remote_value compare:local_value] == NSOrderedDescending)
    return [remote dataForAttribute:attribute.name];
  return nil;
}
@end


