
#import "DSModel.h"

@interface TestPerson : DSModel {
  NSString *first;
  NSString *last;
  NSString *phone;
  float awesome;
  int age;
}

@property (nonatomic, copy) NSString *first;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, assign) float awesome;
@property (nonatomic, assign) int age;
@end