
#import "TestPerson.h"
#import "DSAttribute.h"
#import "DSMerge.h"

@implementation TestPerson
@synthesize first, last, phone, awesome, age;

+ (void) registerAttributes {

  [super registerAttributes];

  DSRegisterAttribute(first, NSString, @"", DSLatestMergeStrategy);
  DSRegisterAttribute(last, NSString, @"", DSLatestMergeStrategy);
  DSRegisterAttribute(phone, NSString, @"0", DSLatestMergeStrategy);

  DSRegisterPrimitiveAttribute(age, int, 1, DSMaxMergeStrategy);
  DSRegisterPrimitiveAttribute(awesome, float, 0.1,DSLatestObjectMergeStrategy);

}

+ (NSString *) dstype {
  return @"Person";
}

@end