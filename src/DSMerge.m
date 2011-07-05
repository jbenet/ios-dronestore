
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

  NSDictionary *attrs = [instance attributes];
  NSMutableDictionary *mergeData = [[NSMutableDictionary alloc] init];

  for (DSAttribute *attr in [attrs allValues]) {
    attr.strategy strat = [[attr.strategy alloc] initWithAttribute:attr];
    data = [strat mergeLocal:instance.version withRemote:version];
    if (data) { // did not merge anything
      [mergeData setValue:data forKey:attr.name];
    }
  }


  for (NSString *attrName in mergeData) {
    [[attrs valueForKey:attrName] setValue:

    [vals setValue:[self dataForAttribute:attr.name] forKey:attr.name];
  }

}

@end



@implementation DSMergeStrategy

- (id) init {
  [NSException raise:@"DSMergeStrategyConstructionException" format:@"Merge "
    "Strategies require an Attribute instance."];
  return nil;
}

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

@end

