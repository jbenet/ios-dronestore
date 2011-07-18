
#import "DSModel.h"

@class DSCollection;

@interface TestPerson : DSModel {
  NSString *first;
  NSString *last;
  NSString *phone;
  float awesomesauce;
  int age;

  TestPerson *father;
  TestPerson *mother;
  DSCollection *children;

  NSMutableArray *titles;
  NSMutableDictionary *computers;
}

@property (nonatomic, copy) NSString *first;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *phone;

@property (nonatomic, assign) float awesomesauce;
@property (nonatomic, assign) int age;


@property (nonatomic, retain) TestPerson *father;
@property (nonatomic, retain) TestPerson *mother;
@property (nonatomic, retain) DSCollection *children;

@property (nonatomic, retain) NSMutableArray *titles;
@property (nonatomic, retain) NSMutableDictionary *computers;

+ (DSCollection *) allPeople;

@end